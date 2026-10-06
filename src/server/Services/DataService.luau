--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Types = require(Shared:WaitForChild("Types"))
local Logger = require(Shared:WaitForChild("Logger"))
local ProfileStore =
	require(game:GetService("ServerScriptService"):WaitForChild("ServerPackages"):WaitForChild("ProfileStore"))
local DataSchema = require(script.Parent.Parent.Data.DataSchema)
local DataMigrations = require(script.Parent.Parent.Data.DataMigrations)
local DATA = Config.DATA
local logger = Logger.new("DataService")

-- Structural adapter: 1.0.3's exported loader type omits Cancel, and its Mock
-- wrapper ignores that argument. Validate external data before treating it as PlayerData.
type Connection = { Disconnect: (self: any) -> () }
type Signal = { Connect: (self: any, callback: (...any) -> ()) -> Connection }
type Profile = {
	Data: any,
	IsActive: (self: any) -> boolean,
	EndSession: (self: any) -> (),
	AddUserId: (self: any, userId: number) -> (),
	OnSessionEnd: Signal,
	OnLastSave: Signal,
	OnAfterSave: Signal,
}
type Store = {
	Name: string,
	StartSessionAsync: (self: any, key: string, options: { Cancel: () -> boolean }) -> Profile?,
}
type Record = {
	Profile: Profile,
	Connections: { Connection },
	Revision: number,
	Ending: boolean,
	FinalRequested: boolean,
	ExpectedRelease: boolean,
}

local DataService = {}
local records: { [Player]: Record } = {}
local pendingSaves: { [Record]: boolean } = {}
local loading: { [Player]: boolean } = {}
local connections: { Connection } = {}
local store: Store? = nil
local rawStore: GlobalDataStore? = nil
local mode = "Uninitialized"
local initialized = false
local started = false
local closing = false

local function disconnectAll(list: { Connection }): ()
	for _, connection in list do
		connection:Disconnect()
	end
	table.clear(list)
end

local function isPlayer(value: unknown): boolean
	return typeof(value) == "Instance" and value:IsA("Player") and value.Parent == Players
end

local function kick(player: Player, message: string): ()
	if player.Parent == Players and not closing and not ProfileStore.IsClosing then
		player:Kick(message)
	end
end

local function release(player: Player): ()
	local record = records[player]
	if record ~= nil and not record.Ending then
		record.Ending = true
		record.ExpectedRelease = true
		pendingSaves[record] = true
		record.Profile:EndSession()
	end
end

local function loadPlayer(player: Player): ()
	if closing or records[player] ~= nil or loading[player] or player.Parent ~= Players then
		return
	end
	loading[player] = true
	local deadline = os.clock() + DATA.LOAD_TIMEOUT_SECONDS
	local function cancelled(): boolean
		return closing or player.Parent ~= Players or os.clock() >= deadline
	end
	local ok, reason = pcall(function(): string?
		while ProfileStore.DataStoreState == "NotReady" and not cancelled() do
			task.wait(DATA.WAIT_INTERVAL_SECONDS)
		end
		if cancelled() then
			error("Profile load cancelled or timed out")
		end
		local key = DATA.PLAYER_KEY_PREFIX .. tostring(player.UserId)
		if mode ~= "Mock" then
			assert(ProfileStore.DataStoreState == "Access", "DataStore access unavailable; refusing temporary saves")
			assert(rawStore ~= nil, "Persistent store was not initialized")
			-- ProfileStore repairs malformed envelopes. Inspect them first to avoid
			-- that normal repair path for existing damaged saves (one extra read/join).
			local raw = rawStore:GetAsync(key)
			if raw ~= nil then
				local validEnvelope, envelopeError = DataSchema.ValidateEnvelope(raw)
				assert(validEnvelope, envelopeError)
				local prepared, validationError = DataMigrations.Prepare(raw.Data)
				assert(prepared ~= nil, validationError)
			end
		end
		if cancelled() then
			error("Player left or loading timed out")
		end
		assert(store ~= nil, "Store was not initialized")
		local profile = store:StartSessionAsync(key, { Cancel = cancelled })
		assert(profile ~= nil, "Profile session could not be started")
		-- Mock ignores Cancel; a player can disappear during its simulated API yield.
		if cancelled() then
			profile:EndSession()
			error("Player left or loading timed out")
		end
		local prepared, validationError = DataMigrations.Prepare(profile.Data)
		if prepared == nil then
			profile:EndSession() -- Release the lock with the original data unchanged.
			error(validationError)
		end
		profile.Data = prepared
		profile:AddUserId(player.UserId)
		local record: Record = {
			Profile = profile,
			Connections = {},
			Revision = 0,
			Ending = false,
			FinalRequested = false,
			ExpectedRelease = false,
		}
		records[player] = record
		table.insert(
			record.Connections,
			profile.OnLastSave:Connect(function(): ()
				record.Ending = true
				record.FinalRequested = true
				pendingSaves[record] = true
			end)
		)
		table.insert(
			record.Connections,
			profile.OnSessionEnd:Connect(function(): ()
				record.Ending = true
				records[player] = nil
				pendingSaves[record] = true
				if not record.ExpectedRelease then
					kick(player, "Your data session ended. Please rejoin.")
				end
			end)
		)
		table.insert(
			record.Connections,
			profile.OnAfterSave:Connect(function(saved: any): ()
				if record.Ending then
					local valid = DataSchema.Validate(saved)
					if record.FinalRequested and valid and DataSchema.Equal(saved, profile.Data) then
						logger.Info(string.format("Final save confirmed for %d (%s)", player.UserId, mode))
					else
						logger.Warn(
							string.format("Session ended without confirming our final data for %d", player.UserId)
						)
					end
					pendingSaves[record] = nil
					disconnectAll(record.Connections)
				end
			end)
		)
		logger.Info(string.format("Profile loaded for %d (schema %d, %s)", player.UserId, prepared.SchemaVersion, mode))
		return nil
	end)
	loading[player] = nil
	if not ok then
		logger.Warn(string.format("Profile load failed for %d: %s", player.UserId, tostring(reason)))
		kick(player, "Your data could not be loaded. Please rejoin.")
	end
end

function DataService.Init(): ()
	if initialized then
		return
	end
	assert(RunService:IsServer(), "DataService is server-only")
	assert(DATA.STUDIO_MODE == "Mock" or DATA.STUDIO_MODE == "Persistent", "Invalid Studio data mode")
	local name = if RunService:IsStudio() then DATA.TEST_STORE_NAME else DATA.LIVE_STORE_NAME
	mode = if RunService:IsStudio() and DATA.STUDIO_MODE == "Mock" then "Mock" else "Persistent"
	local base = ProfileStore.New(name, DataSchema.Create())
	store = (if mode == "Mock" then base.Mock else base) :: any
	if mode ~= "Mock" then
		rawStore = DataStoreService:GetDataStore(name)
	end
	table.insert(
		connections,
		ProfileStore.OnError:Connect(function(message: string, storeName: string, key: string): ()
			if storeName == name then
				logger.Warn(string.format("Storage error for %s: %s", key, message))
			end
		end)
	)
	initialized = true
end

function DataService.Start(): ()
	assert(initialized, "Call DataService.Init before Start")
	if started then
		return
	end
	started = true
	logger.Info(
		string.format(
			"Started (%s, store %s)",
			mode,
			if RunService:IsStudio() then DATA.TEST_STORE_NAME else DATA.LIVE_STORE_NAME
		)
	)
	table.insert(
		connections,
		Players.PlayerAdded:Connect(function(player: Player): ()
			task.spawn(loadPlayer, player)
		end)
	)
	table.insert(connections, Players.PlayerRemoving:Connect(release))
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end
	game:BindToClose(DataService.Shutdown)
end

function DataService.GetStorageMode(): string
	return mode
end

function DataService.GetSnapshot(player: Player): (Types.PlayerData?, string?)
	if not isPlayer(player) then
		return nil, "Invalid player"
	end
	local record = records[player]
	if closing or record == nil or record.Ending or not record.Profile:IsActive() then
		return nil, "Profile is not ready"
	end
	return DataSchema.Copy(record.Profile.Data), nil
end

function DataService.Update(player: Player, mutate: (Types.PlayerData) -> ()): (boolean, string?)
	local draft, reason = DataService.GetSnapshot(player)
	if draft == nil then
		return false, reason
	end
	if type(mutate) ~= "function" then
		return false, "Mutation must be a function"
	end
	local record = records[player]
	assert(record ~= nil, "Profile disappeared before mutation")
	local revision = record.Revision
	local thread = coroutine.create(mutate)
	local ok, mutationError = coroutine.resume(thread, draft)
	if coroutine.status(thread) ~= "dead" then
		pcall(task.cancel, thread)
		return false, "Mutations must not yield"
	end
	if not ok then
		return false, tostring(mutationError)
	end
	local valid, validationError = DataSchema.Validate(draft)
	if not valid then
		return false, validationError
	end
	if draft.SchemaVersion ~= record.Profile.Data.SchemaVersion then
		return false, "Mutations cannot change SchemaVersion"
	end
	if
		closing
		or records[player] ~= record
		or record.Ending
		or not record.Profile:IsActive()
		or record.Revision ~= revision
	then
		return false, "Profile changed during mutation"
	end
	record.Profile.Data = DataSchema.Copy(draft) -- Detach any reference retained by the callback.
	record.Revision += 1
	return true, nil
end

function DataService.Shutdown(): ()
	if closing then
		return
	end
	closing = true
	local players = {}
	for player in records do
		table.insert(players, player)
	end
	for _, player in players do
		release(player)
	end
	local deadline = os.clock() + DATA.SHUTDOWN_TIMEOUT_SECONDS
	while (next(loading) ~= nil or next(pendingSaves) ~= nil) and os.clock() < deadline do
		task.wait(DATA.WAIT_INTERVAL_SECONDS)
	end
	if next(loading) ~= nil or next(pendingSaves) ~= nil then
		logger.Warn("Shutdown deadline reached; some saves are unconfirmed")
	end
	for record in pendingSaves do
		disconnectAll(record.Connections)
	end
	disconnectAll(connections)
end

return DataService
