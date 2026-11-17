--!strict

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Settings = require(Shared.FarmConfig)
local MintSettings = require(Shared.MintConfig)
local Logger = require(Shared.Logger)
local PlatePresentation = require(Shared.PlatePresentation)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local ProducerScheduler = require(script.Parent.Parent.Farms.ProducerScheduler)
local FarmLedger = require(script.Parent.Parent.Farms.FarmLedger)
local SessionEarnings = require(script.Parent.Parent.Farms.SessionEarnings)
local logger = Logger.new("FarmService")

type Producer = { Model: Model?, Drop: BasePart, PurchaseId: string }
type SiteSettings = {
	PRODUCERS: { { Name: string, PurchaseId: string } },
	PRODUCTION_SECONDS: number,
	BUNDLE_VALUE: number,
	MAX_BUNDLES: number,
	BUNDLE_LIFETIME_SECONDS: number,
	CONVEYOR_SPEED: number,
}
type Site = {
	Id: string,
	Settings: SiteSettings,
	Source: BasePart,
	Producers: { Producer },
	Scheduler: ProducerScheduler.Scheduler,
	ProducerFolder: Folder?,
	Model: Model,
	Conveyor: BasePart,
	Pit: BasePart,
	Plate: BasePart,
	Label: TextLabel,
	Bundles: Folder,
	Ledger: FarmLedger.Ledger,
	Expires: { [BasePart]: number },
	Overlap: OverlapParams,
	Connection: RBXScriptConnection?,
	Active: boolean,
}
type Production = {
	Kingdom: Model,
	Sites: { Site },
	Account: SessionEarnings.Account,
	StartPlate: BasePart,
	StartConnection: RBXScriptConnection?,
	Started: boolean,
	LastStart: number,
	LastCollect: number,
}

local FarmService = {}
local productions: { [Player]: Production } = {}
local template: BasePart? = nil
local mintTemplate: BasePart? = nil
local unsubscribe: (() -> ())? = nil
local running = false
local initialized = false
local updatedConnection: RBXScriptConnection? = nil

local function part(model: Model, name: string): BasePart
	local found = model:FindFirstChild(name)
	assert(found ~= nil and found:IsA("BasePart") and found.Anchored, model.Name .. " requires anchored " .. name)
	return found
end

local function validateModel(model: Model): ()
	part(model, "Conveyor")
	part(model, "CollectionPit")
	part(model, "CollectPlate")
	local label = model:FindFirstChild("EarningsLabel", true)
	assert(label ~= nil and label:IsA("TextLabel"), model.Name .. " requires EarningsLabel")
end

local function farmAssets(kingdom: Model): Model
	local model = kingdom:FindFirstChild("StarterFarm")
	assert(model ~= nil and model:IsA("Model"), "KingdomTemplate requires StarterFarm")
	validateModel(model)
	part(model, "DropPoint")
	return model
end

local function publish(state: Production): ()
	local balance = state.Account.GetBalance()
	for _, site in state.Sites do
		PlatePresentation.SetAmount(site.Label, "Collect Total", balance)
		site.Plate.Color = if balance > 0 then Config.PLATES.AVAILABLE_COLOR else Config.PLATES.UNAVAILABLE_COLOR
		-- Presentation only: the private account and site ledger decide credit.
		site.Model:SetAttribute("UncollectedGold", balance)
		site.Model:SetAttribute("ActiveBundleCount", site.Ledger.GetCount())
	end
end

local function isNearPlate(player: Player, plate: BasePart, distance: number): boolean
	local character = player.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
	if root == nil or not root:IsA("BasePart") or humanoid == nil or humanoid.Health <= 0 then
		return false
	end
	local localPosition = plate.CFrame:PointToObjectSpace(root.Position)
	local half = plate.Size / 2
	local nearest = Vector3.new(
		math.clamp(localPosition.X, -half.X, half.X),
		math.clamp(localPosition.Y, -half.Y, half.Y),
		math.clamp(localPosition.Z, -half.Z, half.Z)
	)
	return (localPosition - nearest).Magnitude <= distance
end

-- PurchaseService alone owns parenting the whole Mint model. FarmService owns
-- its producer children, scheduling, collection, and private session accounting.
local function refreshProducers(player: Player): ()
	local state = productions[player]
	local data = DataService.GetSnapshot(player)
	if state == nil or data == nil then
		return
	end
	for _, site in state.Sites do
		site.Active = state.Started and (site.Id == "StarterFarm" or data.PurchasedBuildings.RoyalMint == true)
		local activeCount = 0
		for index, producer in site.Producers do
			local owned = producer.PurchaseId == "" or data.PurchasedBuildings[producer.PurchaseId] == true
			local model = producer.Model
			if model ~= nil then
				model.Parent = if owned then site.ProducerFolder else nil
			end
			site.Scheduler.SetEnabled(index, site.Active and owned, os.clock())
			if site.Active and owned then
				activeCount += 1
			end
		end
		site.Plate.CanTouch = site.Active
		site.Conveyor.AssemblyLinearVelocity = if site.Active
			then site.Conveyor.CFrame.LookVector * site.Settings.CONVEYOR_SPEED
			else Vector3.zero
		site.Model:SetAttribute("ActiveProducerCount", activeCount)
	end
end

function FarmService.IsStarted(player: Player): boolean
	local state = productions[player]
	return state ~= nil and state.Started and PlotService.GetKingdom(player) == state.Kingdom
end

function FarmService.HasProducer(player: Player, purchaseId: string): boolean
	local state = productions[player]
	if state ~= nil then
		for _, site in state.Sites do
			for _, producer in site.Producers do
				if producer.PurchaseId == purchaseId then
					return true
				end
			end
		end
	end
	return false
end

function FarmService.TryStart(player: Player): boolean
	local state = productions[player]
	if
		not running
		or state == nil
		or state.Started
		or player.Parent ~= Players
		or PlotService.GetKingdom(player) ~= state.Kingdom
		or DataService.GetSnapshot(player) == nil
	then
		return false
	end
	local now = os.clock()
	if now - state.LastStart < Settings.START_COOLDOWN_SECONDS then
		return false
	end
	state.LastStart = now
	if not isNearPlate(player, state.StartPlate, Settings.START_DISTANCE) then
		return false
	end
	state.Started = true
	state.Sites[1].Model.Parent = state.Kingdom
	refreshProducers(player)
	if state.StartConnection ~= nil then
		state.StartConnection:Disconnect()
		state.StartConnection = nil
	end
	state.StartPlate.CanTouch = false
	state.StartPlate.CanCollide = false
	state.StartPlate.Transparency = 1
	state.StartPlate.Color = Config.PLATES.UNAVAILABLE_COLOR
	for _, descendant in state.StartPlate:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant.CanTouch = false
		elseif descendant:IsA("LayerCollector") then
			descendant.Enabled = false
		end
	end
	state.Kingdom:SetAttribute("StarterFarmStarted", true)
	player:SetAttribute("StarterFarmStarted", true)
	logger.Info(string.format("Activated starter farm for %d", player.UserId))
	return true
end

-- Server-only integration entry point. No caller-provided position or instance
-- can choose the collection range; the named site's actual plate is validated.
function FarmService.TryCollect(player: Player, siteId: string?): (boolean, number)
	local state = productions[player]
	if
		not running
		or state == nil
		or not state.Started
		or player.Parent ~= Players
		or PlotService.GetKingdom(player) ~= state.Kingdom
	then
		return false, 0
	end
	local requested = siteId or "StarterFarm"
	local selected: Site? = nil
	for _, site in state.Sites do
		if site.Id == requested then
			selected = site
			break
		end
	end
	if
		selected == nil
		or not selected.Active
		or not selected.Model:IsDescendantOf(state.Kingdom)
		or not isNearPlate(player, selected.Plate, Settings.COLLECT_DISTANCE)
	then
		return false, 0
	end
	local now = os.clock()
	if now - state.LastCollect < Settings.COLLECT_COOLDOWN_SECONDS then
		return false, 0
	end
	state.LastCollect = now
	local success, amount = state.Account.Collect(function(value: number): boolean
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
		publish(state)
		logger.Info(string.format("Collected %d Gold for %d", amount, player.UserId))
	end
	return success, amount
end

local function release(player: Player, _kingdom: Model): ()
	local state = productions[player]
	if state == nil then
		return
	end
	productions[player] = nil
	if state.StartConnection ~= nil then
		state.StartConnection:Disconnect()
	end
	for _, site in state.Sites do
		if site.Connection ~= nil then
			site.Connection:Disconnect()
		end
		site.Conveyor.AssemblyLinearVelocity = Vector3.zero
		site.Bundles:Destroy()
		for _, producer in site.Producers do
			if producer.Model ~= nil then
				producer.Model:Destroy()
			end
		end
		table.clear(site.Expires)
		site.Ledger.Clear()
		-- FarmService retains the hidden starter model. PurchaseService retains the
		-- whole hidden Mint and is responsible for its destruction on release.
		if site.Id == "StarterFarm" then
			site.Model:Destroy()
		end
	end
	state.Account.Clear()
	player:SetAttribute("StarterFarmStarted", nil)
	logger.Info(string.format("Cleaned up farm for %d (uncollected Gold discarded)", player.UserId))
end

local function createSite(
	model: Model,
	id: string,
	settings: SiteSettings,
	source: BasePart,
	account: SessionEarnings.Account
): Site
	validateModel(model)
	if id == "RoyalMint" then
		-- Only the belt and explicitly authored guides contact coins. Players,
		-- decorative machine geometry and other coins cannot kick them off course.
		for _, item in model:GetDescendants() do
			if item:IsA("BasePart") and (item.Name == "Conveyor" or item:GetAttribute("MintCoinGuide") == true) then
				item.CollisionGroup = MintSettings.TRACK_COLLISION_GROUP
			end
		end
	end
	local label = model:FindFirstChild("EarningsLabel", true) :: TextLabel
	local producerFolder = model:FindFirstChild("Producers")
	local producers: { Producer } = {}
	local first = 1
	if id == "StarterFarm" then
		table.insert(producers, { Model = nil, Drop = part(model, "DropPoint"), PurchaseId = "" })
		first = 2
	end
	if producerFolder ~= nil then
		assert(producerFolder:IsA("Folder"), model.Name .. ".Producers must be a Folder")
		assert(#producerFolder:GetChildren() == #settings.PRODUCERS - first + 1, "Unexpected producer count in " .. id)
		for index = first, #settings.PRODUCERS do
			local definition = settings.PRODUCERS[index]
			local producer = producerFolder:FindFirstChild(definition.Name)
			assert(producer ~= nil and producer:IsA("Model"), "Missing producer " .. definition.Name)
			table.insert(
				producers,
				{ Model = producer, Drop = part(producer, "DropPoint"), PurchaseId = definition.PurchaseId }
			)
		end
	else
		assert(id == "StarterFarm", "RoyalMint requires Producers")
	end
	local bundles = Instance.new("Folder")
	bundles.Name = "ActiveBundles"
	bundles.Parent = model
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = { bundles }
	if id == "RoyalMint" then
		overlap.CollisionGroup = MintSettings.TRACK_COLLISION_GROUP
	end
	local site: Site = {
		Id = id,
		Settings = settings,
		Source = source,
		Producers = producers,
		ProducerFolder = producerFolder :: Folder?,
		Scheduler = ProducerScheduler.new(#settings.PRODUCERS, settings.PRODUCTION_SECONDS),
		Model = model,
		Conveyor = part(model, "Conveyor"),
		Pit = part(model, "CollectionPit"),
		Plate = part(model, "CollectPlate"),
		Label = label,
		Bundles = bundles,
		Ledger = FarmLedger.new(
			settings.MAX_BUNDLES,
			settings.BUNDLE_LIFETIME_SECONDS,
			settings.BUNDLE_VALUE,
			Config.DATA.MAX_SAFE_INTEGER,
			account
		),
		Expires = {},
		Overlap = overlap,
		Connection = nil,
		Active = false,
	}
	PlatePresentation.Style(site.Plate)
	site.Conveyor.AssemblyLinearVelocity = Vector3.zero
	site.Pit.CanCollide = false
	site.Pit.CanQuery = true
	site.Plate.CanTouch = false
	return site
end

local function prepare(player: Player, kingdom: Model): ()
	if not running then
		return
	end
	assert(productions[player] == nil, "Player already has production")
	local source = template
	assert(source ~= nil, "WheatBundle unavailable")
	local model = farmAssets(kingdom)
	local startPlate = part(kingdom, "FarmStartPlate")
	local account = SessionEarnings.new(Config.DATA.MAX_SAFE_INTEGER)
	local state: Production = {
		Kingdom = kingdom,
		Sites = {},
		Account = account,
		StartPlate = startPlate,
		StartConnection = nil,
		Started = false,
		LastStart = -math.huge,
		LastCollect = -math.huge,
	}
	-- Register before creating/detaching children so claim rollback can release
	-- every successfully prepared site when a later asset fails validation.
	productions[player] = state
	table.insert(state.Sites, createSite(model, "StarterFarm", Settings, source, account))
	local unlocks = kingdom:FindFirstChild("PurchaseUnlocks")
	local mint = if unlocks ~= nil then unlocks:FindFirstChild("RoyalMint") else nil
	if mint ~= nil then
		assert(mint:IsA("Model"), "RoyalMint must be a Model")
		local coin = mintTemplate
		assert(coin ~= nil, "RoyalMint requires ServerStorage.RoyalMintCoin")
		table.insert(state.Sites, createSite(mint, "RoyalMint", MintSettings, coin, account))
	end
	for _, site in state.Sites do
		site.Connection = site.Plate.Touched:Connect(function(hit: BasePart): ()
			local character = player.Character
			if character ~= nil and hit:IsDescendantOf(character) then
				FarmService.TryCollect(player, site.Id)
			end
		end)
	end
	PlatePresentation.Style(startPlate)
	startPlate.Color = Config.PLATES.AVAILABLE_COLOR
	state.StartConnection = startPlate.Touched:Connect(function(hit: BasePart): ()
		local character = player.Character
		if character ~= nil and hit:IsDescendantOf(character) then
			FarmService.TryStart(player)
		end
	end)
	refreshProducers(player)
	publish(state)
	model.Parent = nil
	kingdom:SetAttribute("StarterFarmStarted", false)
	player:SetAttribute("StarterFarmStarted", false)
	logger.Info(string.format("Starter farm awaiting activation for %d", player.UserId))
end

local function dropBundle(site: Site, drop: BasePart, now: number): ()
	if site.Ledger.GetCount() >= site.Settings.MAX_BUNDLES then
		return
	end
	local bundle = site.Source:Clone()
	bundle.Name = if site.Id == "RoyalMint" then "RoyalMintCoin" else "WheatBundle"
	local dropParent = drop.Parent
	bundle:SetAttribute("ProducerId", if dropParent ~= nil then dropParent.Name else "")
	bundle.Anchored = false
	bundle.CanCollide = true
	bundle.CanQuery = true
	if site.Id == "RoyalMint" then
		bundle.CollisionGroup = MintSettings.COIN_COLLISION_GROUP
	end
	bundle.CFrame = drop.CFrame
	bundle.Parent = site.Bundles
	local ok, reason = pcall(function(): string?
		bundle:SetNetworkOwner(nil)
		return nil
	end)
	if not ok then
		bundle:Destroy()
		error("Cannot give bundle physics to server: " .. tostring(reason))
	end
	if not site.Ledger.Register(bundle, now) then
		bundle:Destroy()
		return
	end
	site.Expires[bundle] = now + site.Settings.BUNDLE_LIFETIME_SECONDS
end

local function tickSite(site: Site, now: number): ()
	for bundle, expires in site.Expires do
		if bundle.Parent ~= site.Bundles or now >= expires then
			site.Ledger.Remove(bundle, now, false)
			site.Expires[bundle] = nil
			bundle:Destroy()
		end
	end
	for _, bundle in workspace:GetPartsInPart(site.Pit, site.Overlap) do
		if site.Expires[bundle] ~= nil then
			site.Ledger.Remove(bundle, now, true)
			site.Expires[bundle] = nil
			bundle:Destroy()
		end
	end
	for _, index in site.Scheduler.TakeDue(now, site.Settings.MAX_BUNDLES - site.Ledger.GetCount()) do
		dropBundle(site, site.Producers[index].Drop, now)
	end
end

local function validateSource(source: Instance?, name: string): BasePart
	assert(source ~= nil and source:IsA("BasePart") and source.Archivable, "Invalid " .. name .. " template")
	for _, child in source:GetDescendants() do
		assert(
			not child:IsA("LuaSourceContainer") and not child:IsA("BasePart"),
			name .. " must be a single script-free BasePart"
		)
	end
	return source
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
	assert(kingdom:IsA("Model"), "Invalid KingdomTemplate")
	farmAssets(kingdom)
	part(kingdom, "FarmStartPlate")
	template = validateSource(source, "WheatBundle")
	local unlocks = kingdom:FindFirstChild("PurchaseUnlocks")
	if unlocks ~= nil and unlocks:FindFirstChild("RoyalMint") ~= nil then
		mintTemplate = validateSource(ServerStorage:FindFirstChild("RoyalMintCoin"), "RoyalMintCoin")
		for _, name in { MintSettings.COIN_COLLISION_GROUP, MintSettings.TRACK_COLLISION_GROUP } do
			if not PhysicsService:IsCollisionGroupRegistered(name) then
				PhysicsService:RegisterCollisionGroup(name)
			end
		end
		for _, group in PhysicsService:GetRegisteredCollisionGroups() do
			PhysicsService:CollisionGroupSetCollidable(MintSettings.COIN_COLLISION_GROUP, group.name, false)
		end
		PhysicsService:CollisionGroupSetCollidable(
			MintSettings.COIN_COLLISION_GROUP,
			MintSettings.TRACK_COLLISION_GROUP,
			true
		)
	else
		mintTemplate = nil
	end
	running = true
	unsubscribe = PlotService.ObserveKingdoms(prepare, release)
	updatedConnection = DataService.ObserveUpdates(refreshProducers)
	for _, player in Players:GetPlayers() do
		local assigned = PlotService.GetKingdom(player)
		if assigned ~= nil then
			prepare(player, assigned)
		end
	end
	game:BindToClose(FarmService.Shutdown)
	task.spawn(function(): ()
		while running do
			for player, state in productions do
				if not state.Started then
					continue
				end
				local ok, reason = pcall(function(): string?
					for _, site in state.Sites do
						if site.Active and site.Model:IsDescendantOf(state.Kingdom) then
							tickSite(site, os.clock())
						end
					end
					publish(state)
					return nil
				end)
				if not ok then
					logger.Warn(string.format("Farm stopped for %d: %s", player.UserId, tostring(reason)))
					release(player, state.Kingdom)
				end
			end
			task.wait(Settings.TICK_SECONDS)
		end
	end)
	logger.Info("Ready")
end

function FarmService.Shutdown(): ()
	running = false
	if updatedConnection ~= nil then
		updatedConnection:Disconnect()
		updatedConnection = nil
	end
	if unsubscribe ~= nil then
		unsubscribe()
		unsubscribe = nil
	end
	for player, state in productions do
		release(player, state.Kingdom)
	end
end

return FarmService
