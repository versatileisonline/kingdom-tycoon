--!strict
local Tests = {}
function Tests.Run(): ()
	local Server = script.Parent.Parent
	local Shared = game.ReplicatedStorage.Shared
	local Data = require(Server.Services.DataService)
	local Plots = require(Server.Services.PlotService)
	local Farms = require(Server.Services.FarmService)
	local Entitlements = require(Server.Services.EntitlementService)
	assert(Entitlements.IsPreview() and Data.GetStorageMode() == "Mock", "Studio Mock preview only")
	require(script.Parent.ShopOwnershipTests).Run(require(Server.Shop.EntitlementRegistry))
	require(script.Parent.ShopEconomyTests).Run(require(Server.Farms.SessionEarnings), require(Server.Farms.FarmLedger))
	local player: Player? = nil
	local deadline = os.clock() + 30
	repeat
		player = game.Players:GetPlayers()[1]
		if
			player
			and player.Character
			and player.Character:FindFirstChild("HumanoidRootPart")
			and Data.GetSnapshot(player)
		then
			break
		end
		task.wait(0.1)
	until os.clock() > deadline
	assert(player and player.Character, "test player ready")
	local owner = player :: Player
	local character = owner.Character :: Model
	local original = character:GetPivot()
	local before = Data.GetSnapshot(owner)
	assert(before and not Plots.GetKingdom(owner), "run before claim")
	local function pending(): number
		local value = owner:GetAttribute("UncollectedGold")
		return if typeof(value) == "number" then value else 0
	end
	local function waitEarnings(): ()
		local limit = os.clock() + 25
		repeat
			task.wait(0.1)
		until pending() > 0 or os.clock() > limit
		assert(pending() > 0, "physical production must reach collector")
	end
	local ok, reason = xpcall(function()
		for _, offer in require(Shared.ShopConfig).OFFERS do
			Entitlements.SetPreview(owner, offer.Key, false)
		end
		assert(
			Data.Update(owner, function(draft)
				draft.Gold = 100
				draft.PurchasedBuildings = {}
				for _, offer in require(Shared.PurchaseConfig).PURCHASES do
					if not offer.StudioOnly then
						draft.PurchasedBuildings[offer.Id] = true
					end
				end
			end),
			"fixture update"
		)
		local marker = workspace.Plots.Plot01.ClaimMarker
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 10)))
		assert(Plots.TryClaim(owner, "Plot01"), "claim")
		local kingdom = Plots.GetKingdom(owner) :: Model
		local start = kingdom:FindFirstChild("FarmStartPlate") :: BasePart
		character:PivotTo(CFrame.new(start.Position + Vector3.new(0, 3, 0)))
		assert(Farms.TryStart(owner), "start")
		character:PivotTo(CFrame.new(start.Position + Vector3.new(30, 3, 0)))
		waitEarnings()
		assert(not Farms.TryCollectAnywhere(owner), "unowned remote collection rejected")
		assert(Entitlements.SetPreview(owner, "CollectNow", true), "preview ownership")
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
		root.Parent = nil
		local missingRootAccepted = Farms.TryCollectAnywhere(owner)
		root.Parent = character
		assert(not missingRootAccepted, "missing character root rejected")
		local oldBalance = pending()
		local oldData = Data.GetSnapshot(owner)
		assert(oldData, "snapshot")
		local collected, amount = Farms.TryCollectAnywhere(owner)
		assert(collected and amount == oldBalance, "remote collects whole balance from afar")
		assert(
			owner:GetAttribute("TutorialFarmCollected") == true,
			"remote collection advances contributing farm tutorial"
		)
		local after = Data.GetSnapshot(owner)
		assert(after and after.Gold == oldData.Gold + amount and pending() == 0, "exact once credit")
		assert(not Farms.TryCollectAnywhere(owner), "duplicate/cooldown rejected")
		waitEarnings()
		local retained = pending()
		assert(
			Data.Update(owner, function(draft)
				draft.Gold = require(Shared.Config).DATA.MAX_SAFE_INTEGER
			end),
			"cap fixture"
		)
		Entitlements.SetPreview(owner, "AutoCollect", true)
		task.wait(0.3)
		assert(pending() >= retained, "failed automatic banking retains earnings")
		Entitlements.SetPreview(owner, "AutoCollect", false)
		assert(
			Data.Update(owner, function(draft)
				draft.Gold = 100
			end),
			"restore fixture Gold"
		)
		task.wait(1.1)
		require(Server.Presentation.TutorialProgress).ResetCollections(owner)
		local autoPending = pending()
		Entitlements.SetPreview(owner, "AutoCollect", true)
		task.wait(0.3)
		after = Data.GetSnapshot(owner)
		assert(after and after.Gold >= 100 + autoPending, "auto confirmation banks pending balance")
		local autoGold = after.Gold
		task.wait(5)
		after = Data.GetSnapshot(owner)
		assert(after and after.Gold > autoGold, "automatic natural production")
		assert(
			owner:GetAttribute("TutorialFarmCollected") == true,
			"automatic collection advances contributing farm tutorial"
		)
		Entitlements.SetPreview(owner, "AutoCollect", false)
		waitEarnings()
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
		humanoid.Health = 0
		assert(not Farms.TryCollectAnywhere(owner), "dead owner cannot remotely collect")
		Entitlements.SetPreview(owner, "CollectNow", false)
		assert(not Farms.TryCollectAnywhere(owner), "revoked preview cannot collect")
		Plots.Release(owner)
		assert(owner:GetAttribute("UncollectedGold") == nil, "release clears pending presentation")
		assert(not Farms.TryCollectAnywhere(owner), "released kingdom cannot collect")
		require(script.Parent.ShopPreviewModeTests).Run(owner)
	end, debug.traceback)
	Plots.Release(owner)
	for _, offer in require(Shared.ShopConfig).OFFERS do
		Entitlements.SetPreview(owner, offer.Key, false)
	end
	assert(
		Data.Update(owner, function(draft)
			draft.Gold = before.Gold
			draft.PurchasedBuildings = before.PurchasedBuildings
		end),
		"restore player data"
	)
	if character.Parent then
		character:PivotTo(original)
	end
	local respawnDeadline = os.clock() + 15
	while
		owner.Character == character
		and (character:FindFirstChildOfClass("Humanoid") :: Humanoid).Health <= 0
		and os.clock() < respawnDeadline
	do
		task.wait(0.1)
	end
	if owner.Character and owner.Character ~= character then
		local currentRoot = owner.Character:WaitForChild("HumanoidRootPart", 10)
		if currentRoot then
			owner.Character:PivotTo(original)
		end
	end
	assert(ok, reason)
	print("[KingdomTycoon][ShopTests] All shop and pass checks passed")
end
return Tests
