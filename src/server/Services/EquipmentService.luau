--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.EquipmentConfig)
local Data = require(script.Parent.DataService)
local Plots = require(script.Parent.PlotService)
local logger = require(Shared.Logger).new("EquipmentService")
local Service = {}
type State = {
	Tool: Tool?,
	Character: RBXScriptConnection?,
	LastSwing: number,
	Tween: Tween?,
	Generation: number,
}
local states: { [Player]: State } = {}
local connections: { RBXScriptConnection } = {}
local unsubscribe: (() -> ())? = nil
local started = false
local swing: RemoteEvent
local function remove(state: State): ()
	state.Generation += 1
	if state.Tween then
		state.Tween:Cancel()
		state.Tween = nil
	end
	if state.Tool then
		state.Tool:Destroy()
		state.Tool = nil
	end
end
function Service.TrySwing(player: Player): boolean
	local state = states[player]
	local tool = if state then state.Tool else nil
	local data = Data.GetSnapshot(player)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if
		not state
		or not tool
		or tool.Parent ~= character
		or not humanoid
		or humanoid.Health <= 0
		or not data
		or data.PurchasedBuildings[Config.PURCHASE_ID] ~= true
		or Plots.IsResetting(player)
		or os.clock() - state.LastSwing < Config.SWING_COOLDOWN
	then
		return false
	end
	state.LastSwing = os.clock()
	state.Generation += 1
	local generation = state.Generation
	local rest = (ServerStorage:FindFirstChild(Config.TEMPLATE_NAME) :: Tool).Grip
	if state.Tween then
		state.Tween:Cancel()
	end
	-- Grip-only swing: deliberately no touched/raycast/damage path.
	local tween = TweenService:Create(
		tool,
		TweenInfo.new(Config.SWING_TIME),
		{ Grip = rest * CFrame.Angles(0, 0, math.rad(-80)) }
	)
	state.Tween = tween
	tween:Play()
	local serial = tool:GetAttribute("SwingSerial")
	tool:SetAttribute("SwingSerial", (if typeof(serial) == "number" then serial else 0) + 1)
	task.delay(Config.SWING_TIME, function()
		if state.Generation ~= generation or state.Tool ~= tool then
			return
		end
		local back = TweenService:Create(tool, TweenInfo.new(Config.SWING_TIME), { Grip = rest })
		state.Tween = back
		back:Play()
	end)
	return true
end
local function refresh(player: Player): ()
	local state = states[player]
	if not state then
		return
	end
	local data = Data.GetSnapshot(player)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local backpack = player:FindFirstChildOfClass("Backpack")
	local eligible = data
		and data.PurchasedBuildings[Config.PURCHASE_ID] == true
		and Plots.GetKingdom(player) ~= nil
		and not Plots.IsResetting(player)
		and humanoid
		and humanoid.Health > 0
		and backpack
	if not eligible then
		remove(state)
		return
	end
	if state.Tool and (state.Tool.Parent == backpack or state.Tool.Parent == character) then
		return
	end
	remove(state)
	local source = ServerStorage:FindFirstChild(Config.TEMPLATE_NAME)
	if not source or not source:IsA("Tool") then
		logger.Warn("Missing script-free sword template")
		return
	end
	local tool = source:Clone()
	tool.CanBeDropped = false
	tool.Parent = backpack
	state.Tool = tool
end
local function register(player: Player): ()
	if states[player] then
		return
	end
	local state: State =
		{ Tool = nil, Activation = nil, Character = nil, LastSwing = -math.huge, Tween = nil, Generation = 0 }
	states[player] = state
	state.Character = player.CharacterAdded:Connect(function()
		task.spawn(function()
			player:WaitForChild("Backpack", 5)
			refresh(player)
		end)
	end)
	refresh(player)
end
function Service.Init(): ()
	local replicated = game:GetService("ReplicatedStorage")
	assert(not replicated:FindFirstChild(Config.REMOTE_FOLDER), "Equipment remotes already exist")
	local folder = Instance.new("Folder")
	folder.Name = Config.REMOTE_FOLDER
	swing = Instance.new("RemoteEvent")
	swing.Name, swing.Parent = "Swing", folder
	folder.Parent = replicated
end
function Service.Start(): ()
	if started then
		return
	end
	started = true
	table.insert(
		connections,
		swing.OnServerEvent:Connect(function(player: Player, ...: any)
			if select("#", ...) ~= 0 then
				return
			end
			Service.TrySwing(player)
		end)
	)
	table.insert(connections, Players.PlayerAdded:Connect(register))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			local state = states[player]
			if state then
				remove(state)
				if state.Character then
					state.Character:Disconnect()
				end
			end
			states[player] = nil
		end)
	)
	table.insert(connections, Data.ObserveAvailability(refresh))
	table.insert(
		connections,
		Data.ObserveUpdates(function(player)
			task.defer(refresh, player)
		end)
	)
	unsubscribe = Plots.ObserveKingdoms(function(player)
		task.defer(refresh, player)
	end, function(player)
		local state = states[player]
		if state then
			remove(state)
		end
	end)
	for _, player in Players:GetPlayers() do
		register(player)
	end
	game:BindToClose(function()
		if unsubscribe then
			unsubscribe()
			unsubscribe = nil
		end
		for _, connection in connections do
			connection:Disconnect()
		end
		for _, state in states do
			remove(state)
			if state.Character then
				state.Character:Disconnect()
			end
		end
		table.clear(states)
	end)
	logger.Info("Ready (training sword; no damage)")
end
return Service
