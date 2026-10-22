--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Settings = require(Shared.FarmConfig)
local Logger = require(Shared.Logger)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local FarmLedger = require(script.Parent.Parent.Farms.FarmLedger)
local logger = Logger.new("FarmService")

type Farm = {
	Kingdom: Model,
	Model: Model,
	Drop: BasePart,
	Conveyor: BasePart,
	Pit: BasePart,
	Plate: BasePart,
	Label: TextLabel,
	Bundles: Folder,
	Ledger: FarmLedger.Ledger,
	Expires: { [BasePart]: number },
	Overlap: OverlapParams,
	Connection: RBXScriptConnection?,
	NextDrop: number,
	LastCollect: number,
}

local FarmService = {}
local farms: { [Player]: Farm } = {}
local template: BasePart? = nil
local unsubscribe: (() -> ())? = nil
local running = false
local initialized = false

local function part(model: Model, name: string): BasePart
	local found = model:FindFirstChild(name)
	assert(found ~= nil and found:IsA("BasePart") and found.Anchored, "StarterFarm requires anchored " .. name)
	return found
end

local function assets(kingdom: Model): (Model, BasePart, BasePart, BasePart, BasePart, TextLabel)
	local model = kingdom:FindFirstChild("StarterFarm")
	assert(model ~= nil and model:IsA("Model"), "KingdomTemplate requires StarterFarm (see docs/MILESTONE_1_4.md)")
	local label = model:FindFirstChild("EarningsLabel", true)
	assert(label ~= nil and label:IsA("TextLabel"), "StarterFarm requires EarningsLabel")
	return model,
		part(model, "DropPoint"),
		part(model, "Conveyor"),
		part(model, "CollectionPit"),
		part(model, "CollectPlate"),
		label
end

local function publish(farm: Farm): ()
	farm.Label.Text = string.format("Collect Gold — %d", farm.Ledger.GetBalance())
	-- Read-only presentation/debugging state; accounting remains in the ledger.
	farm.Model:SetAttribute("UncollectedGold", farm.Ledger.GetBalance())
	farm.Model:SetAttribute("ActiveBundleCount", farm.Ledger.GetCount())
end

function FarmService.TryCollect(player: Player): (boolean, number)
	local farm = farms[player]
	if not running or farm == nil or player.Parent ~= Players or PlotService.GetKingdom(player) ~= farm.Kingdom then
		return false, 0
	end
	local character = player.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
	if root == nil or not root:IsA("BasePart") or humanoid == nil or humanoid.Health <= 0 then
		return false, 0
	end
	local localPosition = farm.Plate.CFrame:PointToObjectSpace(root.Position)
	local half = farm.Plate.Size / 2
	local nearest = Vector3.new(
		math.clamp(localPosition.X, -half.X, half.X),
		math.clamp(localPosition.Y, -half.Y, half.Y),
		math.clamp(localPosition.Z, -half.Z, half.Z)
	)
	if not ((localPosition - nearest).Magnitude <= Settings.COLLECT_DISTANCE) then
		return false, 0
	end
	local now = os.clock()
	if now - farm.LastCollect < Settings.COLLECT_COOLDOWN_SECONDS then
		return false, 0
	end
	farm.LastCollect = now
	local success, amount = farm.Ledger.Collect(function(value: number): boolean
		local updated, reason = DataService.Update(player, function(draft): ()
			assert(draft.Gold <= Config.DATA.MAX_SAFE_INTEGER - value, "Gold would exceed safe integer range")
			draft.Gold += value
		end)
		if not updated then
			logger.Warn(string.format("Collection retained for %d: %s", player.UserId, tostring(reason)))
		end
		return updated
	end)
	if success then
		publish(farm)
		logger.Info(string.format("Collected %d Gold for %d", amount, player.UserId))
	end
	return success, amount
end

local function release(player: Player, _kingdom: Model): ()
	local farm = farms[player]
	if farm == nil then
		return
	end
	farms[player] = nil
	if farm.Connection ~= nil then
		farm.Connection:Disconnect()
	end
	farm.Conveyor.AssemblyLinearVelocity = Vector3.zero
	farm.Bundles:Destroy()
	table.clear(farm.Expires)
	farm.Ledger.Clear()
	logger.Info(string.format("Cleaned up farm for %d (uncollected Gold discarded)", player.UserId))
end

local function activate(player: Player, kingdom: Model): ()
	if not running then
		return
	end
	assert(farms[player] == nil, "Player already has a farm")
	local model, drop, conveyor, pit, plate, label = assets(kingdom)
	local bundles = Instance.new("Folder")
	bundles.Name = "ActiveBundles"
	bundles.Parent = model
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = { bundles }
	local farm: Farm = {
		Kingdom = kingdom,
		Model = model,
		Drop = drop,
		Conveyor = conveyor,
		Pit = pit,
		Plate = plate,
		Label = label,
		Bundles = bundles,
		Ledger = FarmLedger.new(
			Settings.MAX_BUNDLES,
			Settings.BUNDLE_LIFETIME_SECONDS,
			Settings.BUNDLE_VALUE,
			Config.DATA.MAX_SAFE_INTEGER
		),
		Expires = {},
		Overlap = overlap,
		Connection = nil,
		NextDrop = os.clock() + Settings.PRODUCTION_SECONDS,
		LastCollect = -math.huge,
	}
	farms[player] = farm
	conveyor.AssemblyLinearVelocity = conveyor.CFrame.LookVector * Settings.CONVEYOR_SPEED
	pit.CanCollide = false
	pit.CanQuery = true
	plate.CanTouch = true
	farm.Connection = plate.Touched:Connect(function(hit: BasePart): ()
		local character = player.Character
		if character ~= nil and hit:IsDescendantOf(character) then
			FarmService.TryCollect(player)
		end
	end)
	publish(farm)
	logger.Info(string.format("Activated starter farm for %d", player.UserId))
end

local function dropBundle(farm: Farm, now: number): ()
	local source = template
	if source == nil or farm.Ledger.GetCount() >= Settings.MAX_BUNDLES then
		return
	end
	local bundle = source:Clone()
	bundle.Name = "WheatBundle"
	bundle.Anchored = false
	bundle.CanCollide = true
	bundle.CanQuery = true
	bundle.CFrame = farm.Drop.CFrame
	bundle.Parent = farm.Bundles
	local ok, reason = pcall(function(): string?
		-- nil makes the server own physics, preventing client-controlled arrivals.
		bundle:SetNetworkOwner(nil)
		return nil
	end)
	if not ok then
		bundle:Destroy()
		error("Cannot give bundle physics to server: " .. tostring(reason))
	end
	if not farm.Ledger.Register(bundle, now) then
		bundle:Destroy()
		return
	end
	farm.Expires[bundle] = now + Settings.BUNDLE_LIFETIME_SECONDS
end

local function tickFarm(farm: Farm, now: number): ()
	for bundle, expires in farm.Expires do
		if bundle.Parent ~= farm.Bundles or now >= expires then
			farm.Ledger.Remove(bundle, now, false)
			farm.Expires[bundle] = nil
			bundle:Destroy()
		end
	end
	-- Overlap queries catch arrivals even if native touch delivery misses a contact.
	for _, bundle in workspace:GetPartsInPart(farm.Pit, farm.Overlap) do
		if farm.Expires[bundle] ~= nil then
			farm.Ledger.Remove(bundle, now, true)
			farm.Expires[bundle] = nil
			bundle:Destroy()
		end
	end
	if now >= farm.NextDrop then
		farm.NextDrop = now + Settings.PRODUCTION_SECONDS -- No catch-up/offline bursts.
		dropBundle(farm, now)
	end
	publish(farm)
end

function FarmService.Init(): ()
	assert(RunService:IsServer(), "FarmService is server-only")
	initialized = true
end

function FarmService.Start(): ()
	assert(initialized, "Call FarmService.Init before Start")
	if running then
		return
	end
	local kingdom = ServerStorage:FindFirstChild("KingdomTemplate")
	local source = ServerStorage:FindFirstChild("WheatBundle")
	if kingdom == nil or source == nil then
		logger.Warn("Unavailable: install the milestone 1.4 Studio assets (docs/MILESTONE_1_4.md)")
		return
	end
	assert(kingdom:IsA("Model") and source:IsA("BasePart") and source.Archivable, "Invalid farm templates")
	assets(kingdom)
	for _, child in source:GetDescendants() do
		assert(
			not child:IsA("LuaSourceContainer") and not child:IsA("BasePart"),
			"WheatBundle must be a single script-free BasePart"
		)
	end
	template = source
	running = true
	unsubscribe = PlotService.ObserveKingdoms(activate, release)
	for _, player in Players:GetPlayers() do
		local assigned = PlotService.GetKingdom(player)
		if assigned ~= nil then
			activate(player, assigned)
		end
	end
	game:BindToClose(FarmService.Shutdown)
	task.spawn(function(): ()
		while running do
			for player, farm in farms do
				local ok, reason = pcall(function(): string?
					tickFarm(farm, os.clock())
					return nil
				end)
				if not ok then
					logger.Warn(string.format("Farm stopped for %d: %s", player.UserId, tostring(reason)))
					release(player, farm.Kingdom)
				end
			end
			task.wait(Settings.TICK_SECONDS)
		end
	end)
	logger.Info("Ready")
end

function FarmService.Shutdown(): ()
	running = false
	if unsubscribe ~= nil then
		unsubscribe()
		unsubscribe = nil
	end
	for player, farm in farms do
		release(player, farm.Kingdom)
	end
end

return FarmService
