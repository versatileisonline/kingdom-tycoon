--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
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
	Track: AnimationTrack?,
	Animation: Animation?,
	Unequipped: RBXScriptConnection?,
	Died: RBXScriptConnection?,
}
local states: { [Player]: State } = {}
local connections: { RBXScriptConnection } = {}
local unsubscribe: (() -> ())? = nil
local started = false
local swing: RemoteEvent
local function remove(state: State): ()
	if state.Unequipped then
		state.Unequipped:Disconnect()
		state.Unequipped = nil
	end
	if state.Died then
		state.Died:Disconnect()
		state.Died = nil
	end
	if state.Track then
		state.Track:Stop(0)
		state.Track:Destroy()
		state.Track = nil
	end
	if state.Animation then
		state.Animation:Destroy()
		state.Animation = nil
	end
	if state.Tool then
		state.Tool:Destroy()
		state.Tool = nil
	end
end
local function prepareAnimation(state: State, humanoid: Humanoid): ()
	local animator: Animator? = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		local created = Instance.new("Animator")
		created.Parent = humanoid
		animator = created
	end
	local animation = Instance.new("Animation")
	animation.Name, animation.AnimationId = "KingdomSwordSideSwipe", Config.SWING_ANIMATION_ID
	local ok, result = pcall(function(): AnimationTrack
		return (animator :: Animator):LoadAnimation(animation)
	end)
	if not ok then
		animation:Destroy()
		logger.Warn("Sword animation could not load: " .. tostring(result))
		return
	end
	local track = result :: AnimationTrack
	track.Name = "KingdomSwordSideSwipe"
	track.Priority, track.Looped = Config.ANIMATION_PRIORITY, false
	state.Animation, state.Track = animation, track
end
function Service.TrySwing(player: Player): boolean
	local state = states[player]
	local tool = if state then state.Tool else nil
	local data = Data.GetSnapshot(player)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if
		not state
		or player:GetAttribute("KingdomEntered") == false
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
	local track = state.Track
	if not track then
		return false
	end
	state.LastSwing = os.clock()
	-- One reusable upper-body track; the sword's upright grip never changes.
	if track.IsPlaying then
		track:Stop(0)
	end
	track:Play(Config.ANIMATION_FADE, 1, 1)
	local serial = tool:GetAttribute("SwingSerial")
	tool:SetAttribute("SwingSerial", (if typeof(serial) == "number" then serial else 0) + 1)
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
	tool.Grip = Config.REST_GRIP
	tool.Parent = backpack
	state.Tool = tool
	prepareAnimation(state, humanoid :: Humanoid)
	state.Unequipped = tool.Unequipped:Connect(function()
		if state.Track then
			state.Track:Stop(Config.ANIMATION_FADE)
		end
	end)
	state.Died = (humanoid :: Humanoid).Died:Connect(function()
		remove(state)
	end)
end
local function register(player: Player): ()
	if states[player] then
		return
	end
	local state: State = {
		Tool = nil,
		Character = nil,
		LastSwing = -math.huge,
		Track = nil,
		Animation = nil,
		Unequipped = nil,
		Died = nil,
	}
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
