--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Logger)
local PlatePresentation = require(Shared.PlatePresentation)
local Settings = require(Shared.PurchaseConfig)
local Types = require(Shared.Types)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local FarmService = require(script.Parent.FarmService)
local logger = Logger.new("PurchaseService")

type Purchase = Settings.Purchase
type Slot = {
	Definition: Purchase,
	Plate: BasePart,
	Label: TextLabel,
	Unlock: Model?,
	Shown: boolean,
	Visible: boolean,
	Connection: RBXScriptConnection?,
	LastTouch: number,
}
type KingdomPurchases = {
	Kingdom: Model,
	Plates: Folder,
	Unlocks: Folder?,
	StartConnection: RBXScriptConnection?,
	Slots: { Slot },
}

local PurchaseService = {}
local definitions: { [string]: Purchase } = {}
local definitionOrder: { [string]: number } = {}
local kingdoms: { [Player]: KingdomPurchases } = {}
local unsubscribe: (() -> ())? = nil
local updatedConnection: RBXScriptConnection? = nil

local function getUnavailableReason(player: Player, data: Types.PlayerData, purchase: Purchase): string?
	if purchase.FarmDropper or purchase.ProductionSite ~= nil then
		if not FarmService.HasProducer(player, purchase.Id) then
			return "Producer unavailable"
		end
		if not FarmService.IsStarted(player) then
			return "Start your farm first"
		end
	end
	if purchase.UpgraderSite ~= nil then
		if not FarmService.HasUpgrader(player, purchase.Id) then
			return "Upgrader unavailable"
		end
		if not FarmService.IsStarted(player) then
			return "Start your farm first"
		end
	end
	local requirement = purchase.Requires
	if requirement ~= nil and data.PurchasedBuildings[requirement] ~= true then
		return "Requires " .. definitions[requirement].Name
	end
	if data.Gold < purchase.Price then
		return string.format("Need %d more Gold", purchase.Price - data.Gold)
	end
	return nil
end

local function refresh(player: Player): ()
	local state = kingdoms[player]
	if state == nil then
		return
	end
	local data = DataService.GetSnapshot(player)
	if data == nil then
		return
	end
	for _, slot in state.Slots do
		local purchase = slot.Definition
		if data.PurchasedBuildings[purchase.Id] == true then
			if not slot.Shown then
				slot.Shown = true
				slot.Plate:Destroy()
				slot.Connection = nil
				local unlock = slot.Unlock
				if unlock ~= nil then
					unlock.Parent = state.Unlocks
				end
			end
		end
	end
	-- A single frontier: the earliest unfinished configured purchase is the only offer.
	local nextSlot: Slot? = nil
	for _, slot in state.Slots do
		if not slot.Shown then
			nextSlot = slot
			break
		end
	end
	for _, slot in state.Slots do
		if slot.Shown then
			continue
		end
		local purchase = slot.Definition
		local requirement = purchase.Requires
		slot.Visible = slot == nextSlot
			and (requirement == nil or data.PurchasedBuildings[requirement] == true)
			and (
				(not purchase.FarmDropper and purchase.ProductionSite == nil and purchase.UpgraderSite == nil)
				or FarmService.IsStarted(player)
			)
		PlatePresentation.SetAmount(slot.Label, purchase.Name, purchase.Price)
		slot.Plate.Color = if getUnavailableReason(player, data, purchase) == nil
			then Config.PLATES.AVAILABLE_COLOR
			else Config.PLATES.UNAVAILABLE_COLOR
		slot.Plate.Parent = if slot.Visible then state.Plates else nil
	end
end

local function purchaseOnTouch(player: Player, state: KingdomPurchases, slot: Slot, hit: BasePart): boolean
	local character = player.Character
	if
		slot.Shown
		or not slot.Visible
		or character == nil
		or not hit:IsDescendantOf(character)
		or player.Parent ~= Players
		or PlotService.GetKingdom(player) ~= state.Kingdom
	then
		return false
	end
	local now = os.clock()
	if now - slot.LastTouch < Settings.TOUCH_COOLDOWN_SECONDS then
		return false
	end
	slot.LastTouch = now
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = if humanoid ~= nil then humanoid.RootPart else nil
	if
		humanoid == nil
		or humanoid.Health <= 0
		or root == nil
		or (root.Position - slot.Plate.Position).Magnitude > Settings.TOUCH_DISTANCE
	then
		return false
	end
	local definition = slot.Definition
	local data = DataService.GetSnapshot(player)
	if
		data == nil
		or data.PurchasedBuildings[definition.Id] == true
		or getUnavailableReason(player, data, definition) ~= nil
	then
		return false
	end
	local success, reason = DataService.Update(player, function(draft): ()
		assert(draft.PurchasedBuildings[definition.Id] ~= true, "Already purchased")
		assert(getUnavailableReason(player, draft, definition) == nil, "Purchase is unavailable")
		draft.Gold -= definition.Price
		draft.PurchasedBuildings[definition.Id] = true
	end)
	if success then
		refresh(player)
		logger.Info(
			string.format("Purchased %s for %d Gold (owner %d)", definition.Id, definition.Price, player.UserId)
		)
	else
		logger.Warn(string.format("Purchase %s rejected for %d: %s", definition.Id, player.UserId, tostring(reason)))
	end

	return success
end

local function release(player: Player): ()
	local state = kingdoms[player]
	kingdoms[player] = nil
	if state == nil then
		return
	end
	if state.StartConnection ~= nil then
		state.StartConnection:Disconnect()
	end
	for _, slot in state.Slots do
		slot.Plate:Destroy()
		if slot.Connection ~= nil then
			slot.Connection:Disconnect()
		end
		if not slot.Shown and slot.Unlock ~= nil then
			slot.Unlock:Destroy()
		end
	end
end

local function prepare(player: Player, kingdom: Model): ()
	local plates = kingdom:FindFirstChild("PurchasePlates")
	local found = kingdom:FindFirstChild("PurchaseUnlocks")
	local unlocks: Folder? = nil
	if found ~= nil then
		assert(found:IsA("Folder"), "PurchaseUnlocks must be a Folder")
		unlocks = found
	end
	if plates == nil then
		assert(unlocks == nil, "PurchaseUnlocks requires PurchasePlates")
		return
	end
	assert(plates:IsA("Folder"), "PurchasePlates must be a Folder")
	local slots: { Slot } = {}
	local seen: { [string]: boolean } = {}
	for _, plate in plates:GetChildren() do
		local id = plate.Name
		local definition = definitions[id]
		local unlock = if unlocks ~= nil then unlocks:FindFirstChild(id) else nil
		local label = plate:FindFirstChild("PurchaseLabel", true)
		assert(definition ~= nil and not seen[id], "Unknown or duplicate purchase plate " .. id)
		assert(plate:IsA("BasePart") and plate.CanTouch, "Purchase plate must support touch: " .. id)
		if definition.FarmDropper or definition.ProductionSite ~= nil then
			assert(FarmService.HasProducer(player, id), "Missing producer for plate " .. id)
			if definition.ProductionSite == "RoyalMint" and id == "RoyalMint" then
				assert(unlock ~= nil and unlock:IsA("Model"), "RoyalMint requires the whole Mint unlock")
			else
				assert(unlock == nil, "Producer models belong inside their production site: " .. id)
			end
		else
			assert(unlock ~= nil and unlock:IsA("Model"), "Purchase unlock must be a Model: " .. id)
			if definition.UpgraderSite ~= nil then
				assert(FarmService.HasUpgrader(player, id), "Missing valid upgrader for plate " .. id)
			end
		end
		assert(label ~= nil and label:IsA("TextLabel"), "Missing PurchaseLabel for " .. id)
		seen[id] = true
		table.insert(slots, {
			Definition = definition,
			Plate = plate,
			Label = label,
			Unlock = unlock :: Model?,
			Shown = false,
			Visible = false,
			Connection = nil,
			LastTouch = -math.huge,
		})
	end
	for _, slot in slots do
		local requirement = slot.Definition.Requires
		assert(requirement == nil or seen[requirement], "Missing prerequisite plate for " .. slot.Definition.Id)
	end
	local unlockChildren: { Instance } = if unlocks ~= nil then unlocks:GetChildren() else {}
	for _, unlock in unlockChildren do
		assert(seen[unlock.Name], "Purchase unlock needs a matching plate: " .. unlock.Name)
		seen[unlock.Name] = nil -- Also reject duplicate unlock models.
	end
	table.sort(slots, function(a: Slot, b: Slot): boolean
		return definitionOrder[a.Definition.Id] < definitionOrder[b.Definition.Id]
	end)
	local state: KingdomPurchases =
		{ Kingdom = kingdom, Plates = plates, Unlocks = unlocks, Slots = {}, StartConnection = nil }
	kingdoms[player] = state
	for _, slot in slots do
		if slot.Definition.StudioOnly and not RunService:IsStudio() then
			slot.Plate:Destroy()
			if slot.Unlock ~= nil then
				slot.Unlock:Destroy()
			end
		else
			PlatePresentation.Style(slot.Plate)
			table.insert(state.Slots, slot)
			if slot.Unlock ~= nil then
				slot.Unlock.Parent = nil
			end
			slot.Connection = slot.Plate.Touched:Connect(function(hit: BasePart): ()
				purchaseOnTouch(player, state, slot, hit)
			end)
		end
	end
	state.StartConnection = player:GetAttributeChangedSignal("StarterFarmStarted"):Connect(function(): ()
		refresh(player)
	end)
	refresh(player)
end

-- Server-only integration entry point; normal play uses the same validated touch path.
function PurchaseService.TryPurchase(player: Player, purchaseId: unknown): boolean
	if typeof(purchaseId) ~= "string" then
		return false
	end
	local state = kingdoms[player]
	local character = player.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	if state == nil or root == nil or not root:IsA("BasePart") then
		return false
	end
	for _, slot in state.Slots do
		if slot.Definition.Id == purchaseId then
			return purchaseOnTouch(player, state, slot, root)
		end
	end
	return false
end

function PurchaseService.Init(): ()
	assert(RunService:IsServer(), "PurchaseService is server-only")
	for index, definition in Settings.PURCHASES do
		local id, price, requirement = definition.Id, definition.Price, definition.Requires
		assert(#id > 0 and #id <= Config.DATA.MAX_BUILDING_ID_LENGTH and definitions[id] == nil, "Invalid purchase ID")
		assert(price > 0 and price <= Config.DATA.MAX_SAFE_INTEGER and price % 1 == 0, "Invalid purchase price: " .. id)
		if requirement ~= nil then
			local dependency = definitions[requirement]
			assert(dependency ~= nil, "Prerequisite must be configured before " .. id)
			assert(
				not dependency.StudioOnly or definition.StudioOnly,
				"Live purchase requires a Studio purchase: " .. id
			)
		end
		definitions[id] = definition
		definitionOrder[id] = index
	end
end

function PurchaseService.Start(): ()
	if unsubscribe ~= nil then
		return
	end
	unsubscribe = PlotService.ObserveKingdoms(prepare, release)
	updatedConnection = DataService.ObserveUpdates(refresh)
	game:BindToClose(function(): ()
		if unsubscribe ~= nil then
			unsubscribe()
			unsubscribe = nil
		end
		if updatedConnection ~= nil then
			updatedConnection:Disconnect()
			updatedConnection = nil
		end
		for player in kingdoms do
			release(player)
		end
	end)
	logger.Info("Ready")
end

return PurchaseService
