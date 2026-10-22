--!strict

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Logger)
local DataService = require(script.Parent.DataService)
local PlotRegistry = require(script.Parent.Parent.Plots.PlotRegistry)
local logger = Logger.new("PlotService")
local SETTINGS = Config.PLOTS

type Plot = {
	Model: Model,
	Origin: BasePart,
	Marker: BasePart,
	Label: TextLabel,
	Kingdom: Model?,
}

local PlotService = {}
local plots: { [string]: Plot } = {}
local registry: PlotRegistry.Registry = PlotRegistry.new({})
local connections: { RBXScriptConnection } = {}
local lastRequests: { [Player]: number } = {}
local template: Model? = nil
local activeKingdoms: Folder? = nil
local arrival: SpawnLocation? = nil
local plotFolder: Folder? = nil
local initialized = false
local started = false
local closing = false
type Observer = { Claimed: (Player, Model) -> (), Releasing: (Player, Model) -> () }
local observers: { [Observer]: boolean } = {}

-- Synchronous server-only callbacks; observers must not yield. Releasing runs
-- before destroying the clone, including partial-claim rollback.
function PlotService.ObserveKingdoms(claimed: (Player, Model) -> (), releasing: (Player, Model) -> ()): () -> ()
	local observer = { Claimed = claimed, Releasing = releasing }
	observers[observer] = true
	return function(): ()
		observers[observer] = nil
	end
end

function PlotService.GetKingdom(player: Player): Model?
	local id = registry.GetPlot(player.UserId)
	return if id ~= nil then plots[id].Kingdom else nil
end

local function notifyRelease(player: Player, kingdom: Model): ()
	for observer in observers do
		local ok, reason = pcall(function(): string?
			observer.Releasing(player, kingdom)
			return nil
		end)
		if not ok then
			logger.Warn("Kingdom release observer failed: " .. tostring(reason))
		end
	end
end

local function publishAvailability(): ()
	local count = 0
	for id in plots do
		if registry.GetOwner(id) == nil then
			count += 1
		end
	end
	if plotFolder ~= nil then
		plotFolder:SetAttribute("AvailablePlotCount", count)
	end
end

local function feedback(player: Player, message: string): ()
	player:SetAttribute("PlotMessage", message)
	local serial = player:GetAttribute("PlotMessageSerial")
	player:SetAttribute("PlotMessageSerial", if typeof(serial) == "number" then serial + 1 else 1)
end

local function resetPlot(plot: Plot): ()
	if plot.Kingdom ~= nil then
		plot.Kingdom:Destroy()
		plot.Kingdom = nil
	end
	plot.Model:SetAttribute("OwnerUserId", nil)
	plot.Label.Text = "CLAIM KINGDOM — FREE"
	plot.Label.Visible = true
	plot.Marker.CanTouch = true
	plot.Marker.Color = Config.PLATES.AVAILABLE_COLOR
end

function PlotService.GetPlotId(player: Player): string?
	return registry.GetPlot(player.UserId)
end

function PlotService.Release(player: Player): ()
	local id = registry.Release(player.UserId)
	if id ~= nil then
		local kingdom = plots[id].Kingdom
		if kingdom ~= nil then
			notifyRelease(player, kingdom)
		end
		if arrival ~= nil then
			player.RespawnLocation = arrival
		end
		resetPlot(plots[id])
		player:SetAttribute("KingdomPlotId", nil)
		publishAvailability()
		logger.Info(string.format("Released %s for %d", id, player.UserId))
	end
end

-- Called by server-bound plates only; no client-supplied position or ownership.
-- Do not add yields between reservation and commit/rollback.
function PlotService.TryClaim(player: Player, plotId: unknown): (boolean, string)
	if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
		return false, "Invalid player."
	end
	if not started or closing then
		return false, "Kingdom claims are unavailable."
	end
	local now = os.clock()
	local previous = lastRequests[player]
	if previous ~= nil and now - previous < SETTINGS.CLAIM_COOLDOWN_SECONDS then
		return false, "Please wait before claiming again."
	end
	lastRequests[player] = now
	if typeof(plotId) ~= "string" then
		return false, "Invalid plot."
	end
	local plot = plots[plotId]
	if plot == nil then
		return false, "Unknown plot."
	end
	if DataService.GetSnapshot(player) == nil then
		return false, "Your progress is still loading. Try again shortly."
	end
	local character = player.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
	if root == nil or not root:IsA("BasePart") or humanoid == nil or humanoid.Health <= 0 then
		return false, "Your character must be alive to claim land."
	end
	if not ((root.Position - plot.Marker.Position).Magnitude <= SETTINGS.CLAIM_DISTANCE) then
		return false, "Step onto the claim plate."
	end
	local reserved, reason = registry.Reserve(player.UserId, plotId)
	if not reserved then
		return false, reason
	end
	local kingdom: Model? = nil
	local ok, failure = pcall(function(): string?
		local source = template
		local container = activeKingdoms
		assert(source ~= nil and container ~= nil, "Plot assets unavailable")
		local clone = source:Clone()
		kingdom = clone
		clone.Name = plotId
		clone:SetAttribute("OwnerUserId", player.UserId)
		clone:SetAttribute("PlotId", plotId)
		clone:PivotTo(plot.Origin.CFrame)
		local sign = clone:FindFirstChild("OwnerLabel", true)
		local spawn = clone:FindFirstChild("SpawnPoint")
		assert(spawn ~= nil and spawn:IsA("SpawnLocation"), "Missing kingdom SpawnLocation")
		assert(sign ~= nil and sign:IsA("TextLabel"), "Missing OwnerLabel")
		sign.Text = player.DisplayName .. "'s Kingdom"
		clone.Parent = container
		plot.Kingdom = clone
		plot.Model:SetAttribute("OwnerUserId", player.UserId)
		plot.Label.Text = player.DisplayName .. "'s Kingdom"
		plot.Label.Visible = false -- The kingdom entrance supplies the owner sign.
		plot.Marker.Color = Config.PLATES.UNAVAILABLE_COLOR
		-- Keep the reusable touch connection alive; ownership gates later touches.
		player:SetAttribute("KingdomPlotId", plotId)
		player.RespawnLocation = spawn
		for observer in observers do
			observer.Claimed(player, clone)
		end
		return nil
	end)
	if not ok then
		if kingdom ~= nil then
			notifyRelease(player, kingdom)
			kingdom:Destroy()
		end
		registry.Release(player.UserId)
		if arrival ~= nil then
			player.RespawnLocation = arrival
		end
		resetPlot(plot)
		player:SetAttribute("KingdomPlotId", nil)
		logger.Warn(string.format("Claim rolled back for %s: %s", plotId, tostring(failure)))
		return false, "Your kingdom could not be placed. Please try again."
	end
	logger.Info(string.format("Claimed %s for %d", plotId, player.UserId))
	publishAvailability()
	return true, "Your kingdom is founded. This land is yours."
end

local function addPlayer(player: Player): ()
	player.DevEnableMouseLock = false -- CameraController owns the approved Left Shift toggle.
	if arrival ~= nil then
		player.RespawnLocation = arrival
	end
end

local function removePlayer(player: Player): ()
	PlotService.Release(player)
	lastRequests[player] = nil
end

function PlotService.Init(): ()
	assert(RunService:IsServer(), "PlotService is server-only")
	initialized = true
end

function PlotService.Start(): ()
	assert(initialized, "Call PlotService.Init before Start")
	if started or closing then
		return
	end
	local folder = workspace:FindFirstChild("Plots")
	local map = workspace:FindFirstChild("KingdomMap")
	local source = ServerStorage:FindFirstChild("KingdomTemplate")
	local container = workspace:FindFirstChild("ActiveKingdoms")
	local spawnPoint = if map ~= nil then map:FindFirstChild("ArrivalSpawn") else nil
	-- A code-only Rojo build intentionally has no map. Fail clearly without waiting forever.
	if folder == nil or source == nil or container == nil or spawnPoint == nil then
		logger.Warn("Unavailable: install the milestone 1.3 Studio assets (see tools/BuildPlotScene.luau)")
		return
	end
	assert(folder:IsA("Folder") and source:IsA("Model") and container:IsA("Folder"), "Invalid plot containers")
	assert(spawnPoint:IsA("SpawnLocation"), "ArrivalSpawn must be a SpawnLocation")
	assert(spawnPoint.Enabled and spawnPoint.Neutral, "ArrivalSpawn must be enabled and neutral")
	assert(source.Archivable, "KingdomTemplate must be Archivable")
	local spawn = source:FindFirstChild("SpawnPoint")
	local ownerLabel = source:FindFirstChild("OwnerLabel", true)
	assert(spawn ~= nil and spawn:IsA("SpawnLocation"), "KingdomTemplate requires SpawnPoint (SpawnLocation)")
	assert(spawn.Enabled and spawn.Neutral and not spawn.AllowTeamChangeOnTouch, "Invalid kingdom spawn settings")
	spawn.Duration = Config.SPAWN_PROTECTION_SECONDS
	spawnPoint.Duration = Config.SPAWN_PROTECTION_SECONDS
	assert(ownerLabel ~= nil and ownerLabel:IsA("TextLabel"), "KingdomTemplate requires OwnerLabel")
	for _, descendant in source:GetDescendants() do
		assert(not descendant:IsA("LuaSourceContainer"), "KingdomTemplate must contain no scripts")
		if descendant:IsA("BasePart") then
			assert(descendant.Anchored, "KingdomTemplate parts must be anchored")
		end
	end
	assert(#container:GetChildren() == 0, "ActiveKingdoms must be empty at startup")
	local ids: { string } = {}
	for _, model in folder:GetChildren() do
		assert(model:IsA("Model"), "Plots children must be Models")
		local id = model:GetAttribute("PlotId")
		local origin = model:FindFirstChild("Origin")
		local marker = model:FindFirstChild("ClaimMarker")
		local label = if marker ~= nil then marker:FindFirstChild("ClaimLabel", true) else nil
		assert(typeof(id) == "string" and id ~= "" and plots[id] == nil, "Plot IDs must be unique nonempty strings")
		assert(origin ~= nil and origin:IsA("BasePart") and origin.Anchored, "Missing anchored Origin")
		assert(marker ~= nil and marker:IsA("BasePart") and marker.Anchored, "Missing anchored ClaimMarker")
		assert(label ~= nil and label:IsA("TextLabel"), "Missing ClaimLabel")
		plots[id] = { Model = model, Origin = origin, Marker = marker, Label = label, Kingdom = nil }
		table.insert(ids, id)
	end
	assert(#ids > 0, "No plots configured")
	registry = PlotRegistry.new(ids)
	template = source
	activeKingdoms = container
	arrival = spawnPoint
	plotFolder = folder
	started = true
	for id, plot in plots do
		resetPlot(plot)
		table.insert(
			connections,
			plot.Marker.Touched:Connect(function(hit: BasePart): ()
				local character = hit:FindFirstAncestorOfClass("Model")
				local player = if character ~= nil then Players:GetPlayerFromCharacter(character) else nil
				if player == nil or registry.GetOwner(id) ~= nil then
					return
				end
				local previous = lastRequests[player]
				if previous ~= nil and os.clock() - previous < SETTINGS.CLAIM_COOLDOWN_SECONDS then
					return -- Avoid replicating feedback for throttled requests.
				end
				local _, message = PlotService.TryClaim(player, id)
				feedback(player, message)
			end)
		)
	end
	publishAvailability()
	table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
	table.insert(connections, Players.PlayerRemoving:Connect(removePlayer))
	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end
	game:BindToClose(PlotService.Shutdown)
	logger.Info(string.format("Ready (%d plots)", #ids))
end

function PlotService.Shutdown(): ()
	if closing then
		return
	end
	closing = true
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	for _, player in Players:GetPlayers() do
		removePlayer(player)
	end
end

return PlotService
