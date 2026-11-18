--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.SprintConfig)
local Stamina = require(script.Parent.Parent.Movement.Stamina)
local Data = require(script.Parent.DataService)
local Plots = require(script.Parent.PlotService)
local logger = require(Shared.Logger).new("SprintService")
local Service = {}
type Record = {
	Meter: Stamina.State,
	Owned: boolean,
	Humanoid: Humanoid?,
	BaseSpeed: number,
	LastApplied: number?,
	Tokens: number,
	Refilled: number,
	LastSent: number,
	SentOwned: boolean?,
	SentExhausted: boolean?,
}
local records: { [Player]: Record } = {}
local connections: { RBXScriptConnection } = {}
local folder: Folder
local input: RemoteEvent
local status: RemoteEvent
local started = false
local function restore(record: Record): ()
	local humanoid = record.Humanoid
	if humanoid and record.LastApplied ~= nil and humanoid.WalkSpeed == record.LastApplied then
		humanoid.WalkSpeed = record.BaseSpeed
	end
	record.LastApplied = nil
end
local function refresh(player: Player): ()
	local record = records[player]
	if not record then
		return
	end
	local data = Data.GetSnapshot(player)
	record.Owned = data ~= nil and data.PurchasedBuildings[Config.PURCHASE_ID] == true
	if not record.Owned then
		restore(record)
		record.Meter = Stamina.New()
	end
end
local function register(player: Player): ()
	if records[player] then
		return
	end
	records[player] = {
		Meter = Stamina.New(),
		Owned = false,
		Humanoid = nil,
		BaseSpeed = 16,
		LastApplied = nil,
		Tokens = Config.INPUT_BURST,
		Refilled = os.clock(),
		LastSent = -1,
		SentOwned = nil,
		SentExhausted = nil,
	}
	refresh(player)
end
function Service.SetHeld(player: Player, held: unknown): boolean
	local record = records[player]
	if not record or typeof(held) ~= "boolean" then
		return false
	end
	-- Releases always stop input, even when the start-request bucket is exhausted.
	if held == false then
		Stamina.SetHeld(record.Meter, false)
		return true
	end
	local now = os.clock()
	record.Tokens = math.min(Config.INPUT_BURST, record.Tokens + (now - record.Refilled) * Config.INPUT_PER_SECOND)
	record.Refilled = now
	if record.Tokens < 1 then
		return false
	end
	record.Tokens -= 1
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if
		not record.Owned
		or player:GetAttribute("KingdomEntered") == false
		or not humanoid
		or humanoid.Health <= 0
		or humanoid.Sit
		or not Plots.GetKingdom(player)
		or Plots.IsResetting(player)
	then
		return false
	end
	Stamina.SetHeld(record.Meter, true)
	return true
end
local function tickPlayer(player: Player, record: Record, dt: number): ()
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid ~= record.Humanoid then
		restore(record)
		record.Meter = Stamina.New()
		record.Humanoid = humanoid
		record.BaseSpeed = if humanoid then humanoid.WalkSpeed else 16
	end
	local allowed = record.Owned
		and player:GetAttribute("KingdomEntered") ~= false
		and humanoid ~= nil
		and humanoid.Health > 0
		and not humanoid.Sit
		and Plots.GetKingdom(player) ~= nil
		and not Plots.IsResetting(player)
	-- MoveDirection is client-local for player-owned characters; measure actual motion.
	local root = if humanoid then humanoid.RootPart else nil
	local velocity = if root then root.AssemblyLinearVelocity else Vector3.zero
	local moving = Vector3.new(velocity.X, 0, velocity.Z).Magnitude > 0.5
	Stamina.Step(record.Meter, dt, moving, allowed)
	if humanoid then
		if record.Meter.Active then
			if record.LastApplied == nil then
				record.BaseSpeed = humanoid.WalkSpeed
			end
			local speed = record.BaseSpeed * Config.SPEED_MULTIPLIER
			humanoid.WalkSpeed = speed
			record.LastApplied = speed
		else
			restore(record)
		end
	end
	-- Owner-only updates, quantized to 1%; no traffic while full and unchanged.
	local percent = math.floor(record.Meter.Remaining / Config.CAPACITY * 100 + 0.5)
	if
		percent ~= record.LastSent
		or record.Owned ~= record.SentOwned
		or record.Meter.Exhausted ~= record.SentExhausted
	then
		record.LastSent, record.SentOwned = percent, record.Owned
		record.SentExhausted = record.Meter.Exhausted
		status:FireClient(player, record.Owned, percent / 100, record.Meter.Exhausted)
	end
end
function Service.Init(): ()
	assert(not ReplicatedStorage:FindFirstChild(Config.REMOTE_FOLDER), "Sprint remotes already exist")
	folder = Instance.new("Folder")
	folder.Name = Config.REMOTE_FOLDER
	input = Instance.new("RemoteEvent")
	input.Name, input.Parent = "Input", folder
	status = Instance.new("RemoteEvent")
	status.Name, status.Parent = "Status", folder
	folder.Parent = ReplicatedStorage
end
function Service.Start(): ()
	if started then
		return
	end
	started = true
	table.insert(connections, Players.PlayerAdded:Connect(register))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			local record = records[player]
			if record then
				restore(record)
			end
			records[player] = nil
		end)
	)
	table.insert(connections, Data.ObserveAvailability(refresh))
	table.insert(connections, Data.ObserveUpdates(refresh))
	table.insert(
		connections,
		input.OnServerEvent:Connect(function(player: Player, held: unknown, ...: any)
			if select("#", ...) ~= 0 then
				return
			end
			Service.SetHeld(player, held)
		end)
	)
	for _, player in Players:GetPlayers() do
		register(player)
	end
	task.spawn(function()
		local previous = os.clock()
		while started do
			task.wait(Config.TICK_SECONDS)
			local now = os.clock()
			local dt = math.min(now - previous, 0.5)
			previous = now
			for player, record in records do
				tickPlayer(player, record, dt)
			end
		end
	end)
	game:BindToClose(function()
		started = false
		for _, connection in connections do
			connection:Disconnect()
		end
		for _, record in records do
			restore(record)
		end
		table.clear(records)
		folder:Destroy()
	end)
	logger.Info("Ready (server stamina)")
end
return Service
