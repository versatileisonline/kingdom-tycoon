--!strict
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Mint = require(Shared.MintConfig)
local Data = require(script.Parent.Parent.Services.DataService)
local Plots = require(script.Parent.Parent.Services.PlotService)
local Farms = require(script.Parent.Parent.Services.FarmService)
local Purchases = require(script.Parent.Parent.Services.PurchaseService)
local Tests = {}
local function getPart(parent: Instance, name: string): BasePart
	local item = parent:FindFirstChild(name)
	assert(item and item:IsA("BasePart"), "Missing " .. name)
	return item
end
function Tests.Run(): ()
	assert(game:GetService("RunService"):IsStudio() and Data.GetStorageMode() == "Mock", "Studio Mock only")
	assert(
		not Mint.RUN_TESTS_IN_STUDIO
			and not require(Shared.PurchaseConfig).RUN_TESTS_IN_STUDIO
			and not require(Shared.FarmConfig).RUN_TESTS_IN_STUDIO
			and not require(Shared.HudConfig).RUN_TESTS_IN_STUDIO
			and not Config.DATA.RUN_TESTS_IN_STUDIO
			and not Config.PLOTS.RUN_TESTS_IN_STUDIO,
		"Run upgrader suite separately"
	)
	require(script.Parent.UpgraderLedgerTests).Run()
	local crossing = require(script.Parent.Parent.Farms.UpgraderCrossing)
	require(script.Parent.UpgraderCrossingTests).Run(crossing)
	require(script.Parent.UpgraderCrossingTests).RunEngine(crossing)
	local deadline = os.clock() + 30
	local player: Player? = nil
	repeat
		player = Players:GetPlayers()[1]
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
	assert(player and player.Character, "Player not ready")
	local owner = player :: Player
	local character = owner.Character :: Model
	local before = Data.GetSnapshot(owner)
	assert(before and not Plots.GetKingdom(owner), "Run before claiming")
	local original = character:GetPivot()
	local function move(p: BasePart): ()
		character:PivotTo(CFrame.new(p.Position + Vector3.new(0, 3, 0)))
	end
	local marker = getPart(workspace.Plots.Plot01, "ClaimMarker")
	local function claim(): Model
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 10)))
		assert(Plots.TryClaim(owner, "Plot01"), "Claim failed")
		local k = Plots.GetKingdom(owner)
		assert(k, "Kingdom missing")
		return k
	end
	local ok, reason = xpcall(function(): string?
		assert(
			Data.Update(owner, function(draft)
				draft.Gold = 0
				draft.PurchasedBuildings = {}
			end),
			"Fixture failed"
		)
		local kingdom = claim()
		assert(not Purchases.TryPurchase(owner, "RoyalMintUpgrader01"), "Hidden early upgrader purchased")
		local plates = kingdom:FindFirstChild("PurchasePlates") :: Folder
		local unlocks = kingdom:FindFirstChild("PurchaseUnlocks") :: Folder
		assert(not unlocks:FindFirstChild("RoyalMintUpgrader01"), "Unowned arch visible")
		move(getPart(kingdom, "FarmStartPlate"))
		assert(Farms.TryStart(owner), "Activation failed")
		assert(
			Data.Update(owner, function(draft)
				for _, id in
					{
						"FarmDropper02",
						"FarmDropper03",
						"FarmDropper04",
						"WoodenWalls",
						"RoyalMint",
						"RoyalMintDropper02",
						"RoyalMintDropper03",
						"RoyalMintDropper04",
						"RoyalMintDropper05",
						"RoyalMintDropper06",
						"RoyalMintDropper07",
						"RoyalMintDropper08",
					}
				do
					draft.PurchasedBuildings[id] = true
				end
				draft.Gold = 249
			end),
			"Prerequisite fixture failed"
		)
		local plate = getPart(plates, "RoyalMintUpgrader01")
		move(plate)
		assert(not Purchases.TryPurchase(owner, "RoyalMintUpgrader01"), "Underfunded purchase accepted")
		character:PivotTo(original)
		assert(
			Data.Update(owner, function(draft)
				draft.Gold = 250
			end),
			"Gold fixture failed"
		)
		task.wait(require(Shared.PurchaseConfig).TOUCH_COOLDOWN_SECONDS + 0.15)
		assert(not Purchases.TryPurchase(owner, "RoyalMintUpgrader01"), "Distant upgrader purchase accepted")
		task.wait(require(Shared.PurchaseConfig).TOUCH_COOLDOWN_SECONDS + 0.15)
		move(plate)
		assert(Purchases.TryPurchase(owner, "RoyalMintUpgrader01"), "Valid upgrader purchase failed")
		local snapshot = Data.GetSnapshot(owner)
		assert(
			snapshot and snapshot.Gold == 0 and snapshot.PurchasedBuildings.RoyalMintUpgrader01,
			"Wrong charge/ownership"
		)
		assert(not Purchases.TryPurchase(owner, "RoyalMintUpgrader01"), "Duplicate purchase accepted")
		assert(not plates:FindFirstChild("RoyalMintUpgrader01"), "Used plate remained")
		local arch = unlocks:FindFirstChild("RoyalMintUpgrader01") :: Model
		assert(arch and arch:FindFirstChild("UpgradeZone"), "Arch not revealed")
		character:PivotTo(original)
		local mint = unlocks:FindFirstChild("RoyalMint") :: Model
		local bundles = mint:FindFirstChild("ActiveBundles") :: Folder
		local first: BasePart? = nil
		local other: BasePart? = nil
		local timeout = os.clock() + 15
		repeat
			for _, coin in bundles:GetChildren() do
				if coin:IsA("BasePart") then
					if coin:GetAttribute("ProducerId") == "Dropper01" and coin.Color == Mint.UPGRADED_COLOR then
						first = coin
					end
					if coin:GetAttribute("ProducerId") == "Dropper02" then
						other = coin
					end
				end
			end
			task.wait(0.1)
		until (first and other) or os.clock() > timeout
		assert(first and other, "No actual upgraded first stream")
		assert(other.Color ~= Mint.UPGRADED_COLOR, "Arch upgraded downstream stream")
		assert(
			first.Size == game.ServerStorage.RoyalMintCoin.Size
				and first.Material == game.ServerStorage.RoyalMintCoin.Material,
			"Upgrade changed coin physics appearance contract"
		)
		-- Display state cannot alter the private token value.
		first:SetAttribute("GoldValue", 999999)
		local collectDeadline = os.clock() + 18
		repeat
			task.wait(0.25)
		until (mint:GetAttribute("UncollectedGold") :: number) > 20 or os.clock() > collectDeadline
		assert((mint:GetAttribute("UncollectedGold") :: number) > 20, "Upgraded production never reached collector")
		local farm = kingdom:FindFirstChild("StarterFarm") :: Model
		assert(mint:GetAttribute("UncollectedGold") == farm:GetAttribute("UncollectedGold"), "Shared total diverged")
		move(getPart(mint, "CollectPlate"))
		local expected = mint:GetAttribute("UncollectedGold") :: number
		local collected, amount = Farms.TryCollect(owner, "RoyalMint")
		assert(collected and amount == expected and amount < 999999, "Shared upgraded collection failed")
		local after = Data.GetSnapshot(owner)
		assert(after and after.Gold == amount, "Collected amount differs from saved Gold")
		Plots.Release(owner)
		assert(arch.Parent == nil and bundles.Parent == nil, "Release leaked arch or coins")
		task.wait(Config.PLOTS.CLAIM_COOLDOWN_SECONDS + 0.25)
		local restored = claim()
		local restoredUnlocks = restored:FindFirstChild("PurchaseUnlocks") :: Folder
		assert(restoredUnlocks:FindFirstChild("RoyalMintUpgrader01"), "Owned arch not restored")
		assert(
			not (restored:FindFirstChild("PurchasePlates") :: Folder):FindFirstChild("RoyalMintUpgrader01"),
			"Owned arch plate restored"
		)
		assert(not Farms.IsStarted(owner), "Reclaim auto-started")
		move(getPart(restored, "FarmStartPlate"))
		assert(Farms.TryStart(owner), "Restored activation failed")
		return nil
	end, debug.traceback)
	Plots.Release(owner)
	character:PivotTo(original)
	assert(
		Data.Update(owner, function(draft)
			draft.Gold = before.Gold
			draft.PurchasedBuildings = before.PurchasedBuildings
		end),
		"Fixture restore failed"
	)
	assert(ok, reason)
	print("All Mint upgrader prototype checks passed")
end
return Tests
