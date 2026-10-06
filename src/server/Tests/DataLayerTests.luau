--!strict

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Types = require(Shared:WaitForChild("Types"))
local Logger = require(Shared:WaitForChild("Logger"))
local DataSchema = require(script.Parent.Parent.Data.DataSchema)
local DataMigrations = require(script.Parent.Parent.Data.DataMigrations)
local DataService = require(script.Parent.Parent.Services.DataService)
local ProfileStore =
	require(game:GetService("ServerScriptService"):WaitForChild("ServerPackages"):WaitForChild("ProfileStore"))
local DATA = Config.DATA
local logger = Logger.new("DataLayerTests")
local Tests = {}

local function assertStudio(): ()
	assert(RunService:IsStudio() and RunService:IsServer(), "Tests are Studio-server only")
end

local function waitUntil(predicate: () -> boolean): ()
	local deadline = os.clock() + DATA.TEST_TIMEOUT_SECONDS
	while not predicate() and os.clock() < deadline do
		task.wait(DATA.WAIT_INTERVAL_SECONDS)
	end
	assert(predicate(), "Test timed out")
end

local function assertInvalid(value: any): ()
	local data, reason = DataMigrations.Prepare(value)
	assert(data == nil and type(reason) == "string", "Expected invalid data to be rejected")
end

function Tests.RunSchema(): number
	assertStudio()
	local cases: { () -> () } = {
		function(): ()
			local a, b = DataSchema.Create(), DataSchema.Create()
			assert(a.SchemaVersion == 1 and a.Gold == 0 and a.Rebirths == 0, "Incorrect initial profile")
			a.PurchasedBuildings.Probe = true
			assert(b.PurchasedBuildings.Probe == nil, "Defaults share mutable tables")
		end,
		function(): ()
			local original = DataSchema.Create()
			original.Gold = DATA.TEST_GOLD
			original.PurchasedBuildings.Probe = true
			local prepared, reason = DataMigrations.Prepare(original)
			assert(prepared ~= nil, reason)
			assert(DataSchema.Equal(original, prepared), "Current schema changed during preparation")
			prepared.PurchasedBuildings.Probe = false
			assert(original.PurchasedBuildings.Probe == true, "Preparation mutates original data")
		end,
		function(): ()
			assertInvalid(nil)
			assertInvalid("bad")
		end,
		function(): ()
			local data: any = DataSchema.Create()
			data.SchemaVersion = nil
			assertInvalid(data)
			data.SchemaVersion = 0
			assertInvalid(data)
		end,
		function(): ()
			local data = DataSchema.Create()
			data.SchemaVersion = DATA.SCHEMA_VERSION + 1
			assertInvalid(data)
			assert(data.SchemaVersion == DATA.SCHEMA_VERSION + 1, "Future schema was overwritten")
		end,
		function(): ()
			local data = DataSchema.Create()
			for _, value in { -1, 0.5, math.huge, 0 / 0, DATA.MAX_SAFE_INTEGER + 1 } do
				data.Gold = value
				assertInvalid(data)
			end
		end,
		function(): ()
			local data: any = DataSchema.Create()
			data.Rebirths = "zero"
			assertInvalid(data)
			data.Rebirths = 0
			data.Gold = nil
			assertInvalid(data)
		end,
		function(): ()
			local data: any = DataSchema.Create()
			data.PurchasedBuildings = { [1] = true }
			assertInvalid(data)
			data.PurchasedBuildings = { Probe = "true" }
			assertInvalid(data)
			data.PurchasedBuildings = { [""] = true }
			assertInvalid(data)
		end,
		function(): ()
			local data: any = DataSchema.Create()
			data.UnversionedAddition = true
			assertInvalid(data)
		end,
		function(): ()
			local data: any = DataSchema.Create()
			data.PurchasedBuildings.Cycle = data
			assertInvalid(data)
		end,
		function(): ()
			local updates: { any } = { 0, {} }
			local envelope: any = {
				Data = DataSchema.Create(),
				MetaData = { ProfileCreateTime = 1, SessionLoadCount = 1 },
				GlobalUpdates = updates,
			}
			assert(DataSchema.ValidateEnvelope(envelope), "Valid envelope rejected")
			envelope.MetaData.SessionLoadCount = nil
			assert(not DataSchema.ValidateEnvelope(envelope), "Damaged envelope accepted")
		end,
	}
	for index, run in cases do
		local ok, reason = pcall(function(): string?
			run()
			return nil
		end)
		assert(ok, string.format("Schema case %d failed: %s", index, tostring(reason)))
	end
	logger.Info(string.format("Schema checks passed (%d cases)", #cases))
	return #cases
end

function Tests.RunService(): ()
	assertStudio()
	waitUntil(function(): boolean
		return DataService.GetStorageMode() ~= "Uninitialized" and #Players:GetPlayers() > 0
	end)
	assert(DataService.GetStorageMode() == "Mock", "Service mutation tests require mock player data")
	local player = Players:GetPlayers()[1]
	assert(player ~= nil, "Start a Play session with a player")
	waitUntil(function(): boolean
		return DataService.GetSnapshot(player) ~= nil
	end)
	local original = DataService.GetSnapshot(player)
	assert(original ~= nil, "Profile was not loaded")
	local ok, reason = pcall(function(): string?
		local snapshot = DataService.GetSnapshot(player)
		assert(snapshot ~= nil, "Missing snapshot")
		snapshot.Gold += 1
		snapshot.PurchasedBuildings.Probe = true
		local current = DataService.GetSnapshot(player)
		assert(current ~= nil and DataSchema.Equal(current, original), "Snapshot leaked mutable profile data")
		local accepted = DataService.Update(player, function(draft: Types.PlayerData): ()
			draft.Gold = -1
		end)
		assert(not accepted, "Invalid mutation committed")
		accepted = DataService.Update(player, function(draft: Types.PlayerData): ()
			draft.Gold = DATA.TEST_GOLD
			error("Expected callback failure")
		end)
		assert(not accepted, "Throwing mutation committed")
		accepted = DataService.Update(player, function(draft: Types.PlayerData): ()
			draft.Gold = DATA.TEST_GOLD
			task.wait(DATA.WAIT_INTERVAL_SECONDS)
		end)
		assert(not accepted, "Yielding mutation committed")
		current = DataService.GetSnapshot(player)
		assert(current ~= nil and DataSchema.Equal(current, original), "Rejected mutation altered profile")
		local leaked: Types.PlayerData? = nil
		accepted = DataService.Update(player, function(draft: Types.PlayerData): ()
			draft.Gold = DATA.TEST_GOLD
			leaked = draft
		end)
		assert(accepted and leaked ~= nil, "Valid mutation failed")
		local retained = leaked :: Types.PlayerData
		retained.Gold = 0
		current = DataService.GetSnapshot(player)
		assert(current ~= nil and current.Gold == DATA.TEST_GOLD, "Callback retained access to saved data")
		accepted = DataService.Update(player, function(draft: Types.PlayerData): ()
			local inner = DataService.Update(player, function(innerDraft: Types.PlayerData): ()
				innerDraft.Gold = DATA.TEST_GOLD + 1
			end)
			assert(inner, "Inner update failed")
			draft.Gold = 0
		end)
		assert(not accepted, "Stale outer mutation overwrote inner commit")
		return nil
	end)
	local restored, restoreError = DataService.Update(player, function(draft: Types.PlayerData): ()
		draft.Gold = original.Gold
		draft.Rebirths = original.Rebirths
		draft.PurchasedBuildings = table.clone(original.PurchasedBuildings)
	end)
	assert(restored, restoreError)
	assert(ok, tostring(reason))
	logger.Info("Service isolation and mutation checks passed; original mock data restored")
end

-- Uses a unique non-player key in the TEST store only. An existing key performs
-- a read-only verification, allowing a second Play session to check persistence.
function Tests.RunStorage(persistent: boolean, existingKey: string?): string
	assertStudio()
	assert(type(persistent) == "boolean", "Choose mock or persistent storage explicitly")
	waitUntil(function(): boolean
		return ProfileStore.DataStoreState ~= "NotReady"
	end)
	if persistent then
		assert(ProfileStore.DataStoreState == "Access", "Enable Studio API access for persistent verification")
	end
	local base = ProfileStore.New(DATA.TEST_STORE_NAME, DataSchema.Create())
	local target = if persistent then base else base.Mock
	local key = existingKey or (DATA.TEST_KEY_PREFIX .. HttpService:GenerateGUID(false))
	assert(#key <= 50 and string.sub(key, 1, #DATA.TEST_KEY_PREFIX) == DATA.TEST_KEY_PREFIX, "Invalid test key")
	if existingKey == nil then
		local profile = target:StartSessionAsync(key, {})
		assert(profile ~= nil, "Test session failed to start")
		profile.Data.Gold = DATA.TEST_GOLD
		local saved = false
		local connection = profile.OnAfterSave:Connect(function(data: any): ()
			saved = data.Gold == DATA.TEST_GOLD
		end)
		profile:EndSession()
		local ok, reason = pcall(function(): string?
			waitUntil(function(): boolean
				return saved
			end)
			return nil
		end)
		connection:Disconnect()
		assert(ok, tostring(reason))
	end
	local loaded = target:GetAsync(key)
	assert(loaded ~= nil, "Test data did not reload")
	local prepared, reason = DataMigrations.Prepare(loaded.Data)
	assert(prepared ~= nil, reason)
	assert(prepared.Gold == DATA.TEST_GOLD, "Saved test balance did not survive reload")
	logger.Info(string.format("%s storage verification passed: %s", if persistent then "Persistent" else "Mock", key))
	return key
end

function Tests.Run(): ()
	Tests.RunSchema()
	Tests.RunService()
	Tests.RunStorage(false)
	logger.Info("All mock data-layer checks passed")
end

return Tests
