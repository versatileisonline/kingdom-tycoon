--!strict
-- Standalone normal Mock Play suite, before claiming. Restores the initial profile.
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Data = require(script.Parent.Parent.Services.DataService)
local Plots = require(script.Parent.Parent.Services.PlotService)
local Farms = require(script.Parent.Parent.Services.FarmService)
local Purchases = require(script.Parent.Parent.Services.PurchaseService)
local Equipment = require(script.Parent.Parent.Services.EquipmentService)
local Sprint = require(script.Parent.Parent.Services.SprintService)
local Catalog = require(Shared.PurchaseConfig)
local Tests = {}
function Tests.Run(): ()
	assert(game:GetService("RunService"):IsStudio() and Data.GetStorageMode() == "Mock", "Studio Mock only")
	require(script.Parent.OptionalOfferTests).Run(require(script.Parent.Parent.Purchases.PurchaseOffers))
	require(script.Parent.StaminaTests).Run(require(script.Parent.Parent.Movement.Stamina))
	local deadline = os.clock() + 20
	local player: Player?
	repeat
		player = Players:GetPlayers()[1]
		if player and player.Character and Data.GetSnapshot(player) then
			break
		end
		task.wait(0.1)
	until os.clock() > deadline
	assert(player and player.Character, "Player not ready")
	local owner = player :: Player
	local character = owner.Character :: Model
	local before = Data.GetSnapshot(owner)
	assert(before and not Plots.GetKingdom(owner), "Run before claiming")
	local saved = before :: any
	local original = character:GetPivot()
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
	local enteredBefore = owner:GetAttribute("KingdomEntered")
	local anchoredBefore = root.Anchored
	local function update(gold: number, owned: { [string]: boolean }?): ()
		assert(Data.Update(owner, function(draft)
			draft.Gold = gold
			if owned then
				draft.PurchasedBuildings = table.clone(owned)
			end
		end))
	end
	local owned: { [string]: boolean } = {}
	for _, entry in Catalog.PURCHASES do
		if entry.Id == "RoyalMintUpgrader01" then
			break
		end
		owned[entry.Id] = true
	end
	local ok, reason = xpcall(function()
		-- Temporarily bypass startup presentation for this isolated Mock fixture.
		owner:SetAttribute("KingdomEntered", true)
		root.Anchored = false
		update(0, owned)
		local marker = workspace.Plots.Plot01.ClaimMarker :: BasePart
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 0)))
		assert(Plots.TryClaim(owner, "Plot01"), "Claim failed")
		local kingdom = Plots.GetKingdom(owner) :: Model
		local start = kingdom:FindFirstChild("FarmStartPlate") :: BasePart
		character:PivotTo(CFrame.new(start.Position + Vector3.new(0, 3, 0)))
		assert(Farms.TryStart(owner), "Start failed")
		task.wait(0.2)
		local plates = kingdom:FindFirstChild("PurchasePlates") :: Folder
		assert(#plates:GetChildren() == 7, "Expected six optional plates and one upgrader")
		assert(not Sprint.SetHeld(owner, true), "Unowned sprint accepted")
		assert(not Sprint.SetHeld(owner, "true"), "Invalid sprint input accepted")
		assert(not Equipment.TrySwing(owner), "Unowned sword accepted")
		local optional = {}
		for _, entry in Catalog.PURCHASES do
			if entry.Optional and entry.Requires == "RoyalMintDropper08" then
				table.insert(optional, entry)
			end
		end
		assert(#optional == 6, "Wrong catalog")
		local first = plates:FindFirstChild("RoyalBanners") :: BasePart
		assert(first.Color == require(Shared.Config).PLATES.UNAVAILABLE_COLOR, "Unfunded offer not red")
		character:PivotTo(CFrame.new(first.Position + Vector3.new(0, 3, 0)))
		assert(not Purchases.TryPurchase(owner, "RoyalBanners"), "Insufficient funds accepted")
		update(50000)
		character:PivotTo(original)
		task.wait(0.8)
		assert(not Purchases.TryPurchase(owner, "RoyalFountain"), "Distant purchase accepted")
		task.wait(require(Shared.PurchaseConfig).TOUCH_COOLDOWN_SECONDS + 0.1)
		local charged = 0
		for i = #optional, 1, -1 do
			local entry = optional[i]
			local plate = plates:FindFirstChild(entry.Id) :: BasePart
			assert(plate and plate.Color == require(Shared.Config).PLATES.AVAILABLE_COLOR, "Missing funded option")
			character:PivotTo(CFrame.new(plate.Position + Vector3.new(0, 3, 0)))
			assert(Purchases.TryPurchase(owner, entry.Id), "Out-of-order purchase failed: " .. entry.Id)
			assert(not Purchases.TryPurchase(owner, entry.Id), "Duplicate charged")
			charged += entry.Price
		end
		character:PivotTo(original)
		task.wait(0.3)
		assert((Data.GetSnapshot(owner) :: any).Gold == 50000 - charged, "Wrong optional charges")
		assert(
			#plates:GetChildren() == 1 and plates:FindFirstChild("RoyalMintUpgrader01"),
			"Options blocked production"
		)
		assert(Sprint.SetHeld(owner, true), "Purchased sprint rejected")
		Sprint.SetHeld(owner, false)
		require(script.Parent.EquipmentTests).Run(owner, Equipment)
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
		local baseSpeed = humanoid.WalkSpeed
		-- Restoration without charging: release and reclaim the same saved purchases.
		Plots.Release(owner)
		task.wait(1.2)
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 0)))
		assert(Plots.TryClaim(owner, "Plot01"), "Reclaim failed")
		kingdom = Plots.GetKingdom(owner) :: Model
		task.wait(0.3)
		for _, entry in optional do
			assert(
				(kingdom:FindFirstChild("PurchaseUnlocks") :: Folder):FindFirstChild(entry.Id),
				"Saved optional model not restored"
			)
			assert(
				not (kingdom:FindFirstChild("PurchasePlates") :: Folder):FindFirstChild(entry.Id),
				"Owned plate reappeared"
			)
		end
		assert((Data.GetSnapshot(owner) :: any).Gold == 50000 - charged, "Restoration charged")
		-- Exercise the real rebirth service, including plot reconstruction and ability revocation.
		local rebirths = (Data.GetSnapshot(owner) :: any).Rebirths
		local target = require(Shared.RebirthConfig).Target(rebirths)
		assert(target, "Missing rebirth target")
		update(target)
		local success, message = require(script.Parent.Parent.Services.RebirthService).TryRebirth(owner, rebirths)
		assert(success, message)
		task.wait(0.4)
		assert(not Sprint.SetHeld(owner, true), "Rebirth retained sprint")
		assert(not Equipment.TrySwing(owner), "Rebirth retained sword")
		assert(
			not owner.Backpack:FindFirstChild("KingdomTrainingSword")
				and not character:FindFirstChild("KingdomTrainingSword"),
			"Sword leaked across rebirth"
		)
		assert(humanoid.WalkSpeed == baseSpeed, "Rebirth retained speed override")
		kingdom = Plots.GetKingdom(owner) :: Model
		for _, entry in optional do
			assert(
				not (kingdom:FindFirstChild("PurchaseUnlocks") :: Folder):FindFirstChild(entry.Id),
				"Rebirth retained optional model"
			)
		end
		assert(
			#(kingdom:FindFirstChild("PurchasePlates") :: Folder):GetChildren() == 0,
			"Rebirth exposed locked optional plates"
		)
	end, debug.traceback)
	Plots.Release(owner)
	character:PivotTo(original)
	assert(Data.Update(owner, function(draft)
		draft.Gold = saved.Gold
		draft.Rebirths = saved.Rebirths
		draft.PurchasedBuildings = table.clone(saved.PurchasedBuildings)
	end))
	owner:SetAttribute("KingdomEntered", enteredBefore)
	root.Anchored = anchoredBefore
	assert(ok, reason)
	print("All optional additions and rebirth checks passed")
end
return Tests
