--!strict
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local FarmConfig = require(Shared.FarmConfig)
local MintConfig = require(Shared.MintConfig)
local PurchaseConfig = require(Shared.PurchaseConfig)
local DataService = require(script.Parent.Parent.Services.DataService)
local PlotService = require(script.Parent.Parent.Services.PlotService)
local FarmService = require(script.Parent.Parent.Services.FarmService)
local PurchaseService = require(script.Parent.Parent.Services.PurchaseService)
local Tests = {}
local function part(parent: Instance, name: string): BasePart
	local found = parent:FindFirstChild(name)
	assert(found and found:IsA("BasePart"), "Missing part " .. name)
	return found
end
function Tests.Run(): ()
	assert(
		game:GetService("RunService"):IsStudio() and DataService.GetStorageMode() == "Mock",
		"Mint tests require Studio Mock"
	)
	assert(
		not FarmConfig.RUN_TESTS_IN_STUDIO
			and not PurchaseConfig.RUN_TESTS_IN_STUDIO
			and not Config.DATA.RUN_TESTS_IN_STUDIO
			and not Config.PLOTS.RUN_TESTS_IN_STUDIO
			and not require(Shared.HudConfig).RUN_TESTS_IN_STUDIO,
		"Run Mint tests separately"
	)
	require(script.Parent.SessionEarningsTests).Run()
	local owner: Player? = nil
	local deadline = os.clock() + 30
	repeat
		owner = Players:GetPlayers()[1]
		if
			owner
			and owner.Character
			and owner.Character:FindFirstChild("HumanoidRootPart")
			and DataService.GetSnapshot(owner)
		then
			break
		end
		task.wait(0.1)
	until os.clock() > deadline
	assert(owner and owner.Character, "Player not ready")
	local player = owner :: Player
	local character = player.Character :: Model
	local before = DataService.GetSnapshot(player)
	assert(before, "Data unavailable")
	assert(not PlotService.GetKingdom(player), "Run before claiming")
	local original = character:GetPivot()
	local plots = workspace:FindFirstChild("Plots")
	assert(plots, "Plots unavailable")
	local marker = part(plots:FindFirstChild("Plot01") :: Instance, "ClaimMarker")
	local function move(target: BasePart): ()
		character:PivotTo(CFrame.new(target.Position + Vector3.new(0, 3, 0)))
	end
	local function claim(): Model
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 10)))
		assert(PlotService.TryClaim(player, "Plot01"), "Claim failed")
		local kingdom = PlotService.GetKingdom(player)
		assert(kingdom, "No kingdom")
		return kingdom
	end
	local ok, reason = xpcall(function(): string?
		assert(
			DataService.Update(player, function(draft)
				draft.Gold = 10000
				draft.PurchasedBuildings = {}
			end),
			"Fixture setup failed"
		)
		local kingdom = claim()
		local start = part(kingdom, "FarmStartPlate")
		move(start)
		assert(FarmService.TryStart(player), "Start failed")
		local plates = kingdom:FindFirstChild("PurchasePlates") :: Folder
		local unlocks = kingdom:FindFirstChild("PurchaseUnlocks") :: Folder
		assert(not unlocks:FindFirstChild("RoyalMint"), "Future Mint visible")
		for _, id in { "FarmDropper02", "FarmDropper03", "FarmDropper04", "WoodenWalls" } do
			move(part(plates, id))
			assert(PurchaseService.TryPurchase(player, id), "Prerequisite failed " .. id)
		end
		assert(not PurchaseService.TryPurchase(player, "RoyalMintDropper03"), "Hidden purchase accepted")
		local mintPlate = part(plates, "RoyalMint")
		assert(
			DataService.Update(player, function(draft)
				draft.Gold = 59
			end),
			"Gold setup failed"
		)
		move(mintPlate)
		assert(not PurchaseService.TryPurchase(player, "RoyalMint"), "Underfunded purchase accepted")
		character:PivotTo(original) -- Wait away from the plate to avoid native touch purchases.
		assert(
			DataService.Update(player, function(draft)
				draft.Gold = 10000
			end),
			"Gold setup failed"
		)
		task.wait(PurchaseConfig.TOUCH_COOLDOWN_SECONDS + 0.1)
		move(mintPlate)
		assert(PurchaseService.TryPurchase(player, "RoyalMint"), "Mint purchase failed")
		assert(not PurchaseService.TryPurchase(player, "RoyalMint"), "Duplicate purchase accepted")
		local mint = unlocks:FindFirstChild("RoyalMint") :: Model
		assert(mint, "Mint missing")
		local producers = mint:FindFirstChild("Producers") :: Folder
		assert(#producers:GetChildren() == 1, "Future producers visible")
		for index = 2, 8 do
			local id = string.format("RoyalMintDropper%02d", index)
			local balance = DataService.GetSnapshot(player)
			assert(balance, "Missing snapshot")
			move(part(plates, id))
			assert(PurchaseService.TryPurchase(player, id), "Dropper purchase failed " .. id)
			local after = DataService.GetSnapshot(player)
			local expectedPrice = ({ 70, 90, 110, 130, 150, 170, 190 })[index - 1]
			assert(after and after.Gold == balance.Gold - expectedPrice, "Wrong purchase price")
			assert(#producers:GetChildren() == index, "Wrong visible producer count")
		end
		character:PivotTo(original)
		local farm = kingdom:FindFirstChild("StarterFarm") :: Model
		local active = mint:FindFirstChild("ActiveBundles") :: Folder
		-- Capture real coins from every producer; shared balance alone could be farm income.
		local samples: { [string]: BasePart? } = {}
		local sampleDeadline = os.clock() + 5
		repeat
			for _, coin in active:GetChildren() do
				if coin:IsA("BasePart") then
					local id = coin:GetAttribute("ProducerId")
					if typeof(id) == "string" and samples[id] == nil then
						samples[id] = coin
					end
				end
			end
			task.wait(0.1)
		until os.clock() >= sampleDeadline
		local pit = part(mint, "CollectionPit")
		local transitDeadline = os.clock() + 14
		repeat
			local pending = false
			for _, coin in samples do
				if coin ~= nil and coin.Parent == active then
					pending = true
				end
			end
			if not pending then
				break
			end
			task.wait(0.1)
		until os.clock() >= transitDeadline
		for index = 1, 8 do
			local id = string.format("Dropper%02d", index)
			local coin = samples[id]
			assert(coin ~= nil, "No physical coin from " .. id)
			assert(
				coin.Parent == nil and (coin.Position - pit.Position).Magnitude < 8,
				"Coin failed to reach pit before expiry: " .. id
			)
		end
		local endTime = os.clock() + 25
		repeat
			task.wait(0.25)
		until (mint:GetAttribute("UncollectedGold") :: number) > 10 or os.clock() > endTime
		assert((mint:GetAttribute("UncollectedGold") :: number) > 10, "No combined earnings")
		assert(
			mint:GetAttribute("UncollectedGold") == farm:GetAttribute("UncollectedGold"),
			"Collector balances disagree"
		)
		assert(#active:GetChildren() <= MintConfig.MAX_BUNDLES, "Mint cap exceeded")
		assert(not FarmService.TryCollect(player, "RoyalMint"), "Distant collection accepted")
		assert(not FarmService.TryCollect(player, "UnknownSite"), "Unknown collector accepted")
		local collector = part(mint, "CollectPlate")
		assert(
			DataService.Update(player, function(draft)
				draft.Gold = Config.DATA.MAX_SAFE_INTEGER
			end),
			"Overflow setup failed"
		)
		move(collector)
		local retained = mint:GetAttribute("UncollectedGold")
		assert(not FarmService.TryCollect(player, "RoyalMint"), "Overflow collection accepted")
		assert(mint:GetAttribute("UncollectedGold") == retained, "Failed collection lost funds")
		character:PivotTo(original)
		assert(
			DataService.Update(player, function(draft)
				draft.Gold = 100
			end),
			"Gold reset failed"
		)
		task.wait(FarmConfig.COLLECT_COOLDOWN_SECONDS + 0.25)
		move(collector)
		local expected = mint:GetAttribute("UncollectedGold") :: number
		local collected, amount = FarmService.TryCollect(player, "RoyalMint")
		assert(collected and amount == expected, "Mint did not collect combined total")
		assert(
			farm:GetAttribute("UncollectedGold") == 0 and mint:GetAttribute("UncollectedGold") == 0,
			"Both labels did not reset"
		)
		assert(not FarmService.TryCollect(player), "Second collector credited twice")
		character:PivotTo(original)
		task.wait(16)
		move(part(farm, "CollectPlate"))
		assert(FarmService.TryCollect(player), "Farm collector did not collect shared total")
		PlotService.Release(player)
		assert(active.Parent == nil, "Live coins survived release")
		task.wait(Config.PLOTS.CLAIM_COOLDOWN_SECONDS + 0.25)
		local restored = claim()
		local restoredUnlocks = restored:FindFirstChild("PurchaseUnlocks") :: Folder
		local restoredMint = restoredUnlocks:FindFirstChild("RoyalMint") :: Model
		assert(restoredMint, "Owned Mint not restored")
		local restoredProducers = restoredMint:FindFirstChild("Producers") :: Folder
		assert(#restoredProducers:GetChildren() == 8, "Owned droppers not restored")
		assert(restoredMint:GetAttribute("UncollectedGold") == 0, "Reclaim retained earnings")
		task.wait(4)
		assert((restoredMint:GetAttribute("ActiveBundleCount") :: number) == 0, "Mint produced before Start Farm")
		move(part(restored, "FarmStartPlate"))
		assert(FarmService.TryStart(player), "Restored production did not activate")
		return nil
	end, debug.traceback)
	PlotService.Release(player)
	character:PivotTo(original)
	assert(
		DataService.Update(player, function(draft)
			draft.Gold = before.Gold
			draft.PurchasedBuildings = before.PurchasedBuildings
		end),
		"Fixture restore failed"
	)
	assert(ok, reason)
	print("All Royal Mint checks passed")
end
return Tests
