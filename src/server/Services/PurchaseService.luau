--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Logger)
local Settings = require(Shared.PurchaseConfig)
local Types = require(Shared.Types)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local logger = Logger.new("PurchaseService")

type Purchase = Settings.Purchase
type Slot = {
	Definition: Purchase,
	Plate: BasePart,
	Label: TextLabel,
	Unlock: Model,
	Shown: boolean,
	Connection: RBXScriptConnection?,
	LastTouch: number,
}
type KingdomPurchases = {
	Kingdom: Model,
	Unlocks: Folder,
	Slots: { Slot },
}

local PurchaseService = {}
local definitions: { [string]: Purchase } = {}
local kingdoms: { [Player]: KingdomPurchases } = {}
local unsubscribe: (() -> ())? = nil
local updatedConnection: RBXScriptConnection? = nil

local function getUnavailableReason(data: Types.PlayerData, purchase: Purchase): string?
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
				slot.Unlock.Parent = state.Unlocks
			end
		elseif not slot.Shown then
			local reason = getUnavailableReason(data, purchase)
			slot.Plate.Color = if reason == nil then Config.PLATES.AVAILABLE_COLOR else Config.PLATES.UNAVAILABLE_COLOR
			slot.Label.Text =
				string.format("%s • %d Gold\n%s", purchase.Name, purchase.Price, reason or "Step to buy")
		end
	end
end

local function purchaseOnTouch(player: Player, state: KingdomPurchases, slot: Slot, hit: BasePart): ()
	local character = player.Character
	if
		slot.Shown
		or character == nil
		or not hit:IsDescendantOf(character)
		or player.Parent ~= Players
		or PlotService.GetKingdom(player) ~= state.Kingdom
	then
		return
	end
	local now = os.clock()
	if now - slot.LastTouch < Settings.TOUCH_COOLDOWN_SECONDS then
		return
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
		return
	end
	local definition = slot.Definition
	local data = DataService.GetSnapshot(player)
	if
		data == nil
		or data.PurchasedBuildings[definition.Id] == true
		or getUnavailableReason(data, definition) ~= nil
	then
		return
	end
	local success, reason = DataService.Update(player, function(draft): ()
		assert(draft.PurchasedBuildings[definition.Id] ~= true, "Already purchased")
		assert(getUnavailableReason(draft, definition) == nil, "Purchase is unavailable")
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
end

local function release(player: Player): ()
	local state = kingdoms[player]
	kingdoms[player] = nil
	if state == nil then
		return
	end
	for _, slot in state.Slots do
		if slot.Connection ~= nil then
			slot.Connection:Disconnect()
		end
		if not slot.Shown then
			slot.Unlock:Destroy()
		end
	end
end

local function prepare(player: Player, kingdom: Model): ()
	local plates = kingdom:FindFirstChild("PurchasePlates")
	local unlocks = kingdom:FindFirstChild("PurchaseUnlocks")
	if plates == nil and unlocks == nil then
		return
	end
	assert(plates and plates:IsA("Folder"), "PurchasePlates must be a Folder")
	assert(unlocks and unlocks:IsA("Folder"), "PurchaseUnlocks must be a Folder")
	local slots: { Slot } = {}
	local seen: { [string]: boolean } = {}
	for _, plate in plates:GetChildren() do
		local id = plate.Name
		local definition = definitions[id]
		local unlock = unlocks:FindFirstChild(id)
		local label = plate:FindFirstChild("PurchaseLabel", true)
		assert(definition ~= nil and not seen[id], "Unknown or duplicate purchase plate " .. id)
		assert(plate:IsA("BasePart") and plate.CanTouch, "Purchase plate must support touch: " .. id)
		assert(unlock ~= nil and unlock:IsA("Model"), "Purchase unlock must be a Model: " .. id)
		assert(label ~= nil and label:IsA("TextLabel"), "Missing PurchaseLabel for " .. id)
		seen[id] = true
		table.insert(slots, {
			Definition = definition,
			Plate = plate,
			Label = label,
			Unlock = unlock,
			Shown = false,
			Connection = nil,
			LastTouch = -math.huge,
		})
	end
	for _, slot in slots do
		local requirement = slot.Definition.Requires
		assert(requirement == nil or seen[requirement], "Missing prerequisite plate for " .. slot.Definition.Id)
	end
	for _, unlock in unlocks:GetChildren() do
		assert(seen[unlock.Name], "Purchase unlock needs a matching plate: " .. unlock.Name)
		seen[unlock.Name] = nil -- Also reject duplicate unlock models.
	end
	local state: KingdomPurchases = { Kingdom = kingdom, Unlocks = unlocks, Slots = {} }
	kingdoms[player] = state
	for _, slot in slots do
		if slot.Definition.StudioOnly and not RunService:IsStudio() then
			slot.Plate:Destroy()
			slot.Unlock:Destroy()
		else
			table.insert(state.Slots, slot)
			slot.Unlock.Parent = nil
			slot.Connection = slot.Plate.Touched:Connect(function(hit: BasePart): ()
				purchaseOnTouch(player, state, slot, hit)
			end)
		end
	end
	refresh(player)
end

function PurchaseService.Init(): ()
	assert(RunService:IsServer(), "PurchaseService is server-only")
	for _, definition in Settings.PURCHASES do
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
