--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Mint = require(Shared.MintConfig)
local Data = require(script.Parent.Parent.Services.DataService)
local Plots = require(script.Parent.Parent.Services.PlotService)
local Farms = require(script.Parent.Parent.Services.FarmService)
local Purchases = require(script.Parent.Parent.Services.PurchaseService)
local Tests = {}
function Tests.Run(): ()
	assert(game:GetService("RunService"):IsStudio() and Data.GetStorageMode() == "Mock", "Studio Mock only")
	assert(
		not Mint.RUN_TESTS_IN_STUDIO
			and not Mint.RUN_UPGRADER_TESTS_IN_STUDIO
			and not require(Shared.FarmConfig).RUN_TESTS_IN_STUDIO
			and not require(Shared.PurchaseConfig).RUN_TESTS_IN_STUDIO
			and not require(Shared.HudConfig).RUN_TESTS_IN_STUDIO
			and not Config.DATA.RUN_TESTS_IN_STUDIO
			and not Config.PLOTS.RUN_TESTS_IN_STUDIO,
		"Run chain tests separately"
	)
	require(script.Parent.UpgraderChainLedgerTests).Run(
		Mint,
		require(Shared.PurchaseConfig),
		require(script.Parent.Parent.Farms.FarmLedger)
	)
	local owner: Player? = nil
	local deadline = os.clock() + 30
	repeat
		owner = game.Players:GetPlayers()[1]
		if
			owner
			and owner.Character
			and owner.Character:FindFirstChild("HumanoidRootPart")
			and Data.GetSnapshot(owner)
		then
			break
		end
		task.wait(0.1)
	until os.clock() > deadline
	assert(owner and owner.Character, "Player not ready")
	local player = owner :: Player
	local character = player.Character :: Model
	local before = Data.GetSnapshot(player)
	assert(before and not Plots.GetKingdom(player), "Run before claiming")
	local original = character:GetPivot()
	local function part(parent: Instance, name: string): BasePart
		local found = parent:FindFirstChild(name)
		assert(found and found:IsA("BasePart"), "Missing " .. name)
		return found
	end
	local function move(p: BasePart): ()
		character:PivotTo(CFrame.new(p.Position + Vector3.new(0, 3, 0)))
	end
	local marker = workspace.Plots.Plot01.ClaimMarker
	local function claim(): Model
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 10)))
		assert(Plots.TryClaim(player, "Plot01"), "Claim failed")
		local k = Plots.GetKingdom(player)
		assert(k, "No kingdom")
		return k
	end
	local ok, reason = xpcall(function(): string?
		assert(
			Data.Update(player, function(draft)
				draft.Gold = 20000
				draft.PurchasedBuildings = {}
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
			end),
			"Fixture setup failed"
		)
		local k = claim()
		local unlocks = k:FindFirstChild("PurchaseUnlocks") :: Folder
		local plates = k:FindFirstChild("PurchasePlates") :: Folder
		for index = 1, 8 do
			assert(not unlocks:FindFirstChild(string.format("RoyalMintUpgrader%02d", index)), "Future arch visible")
		end
		move(part(k, "FarmStartPlate"))
		assert(Farms.TryStart(player), "Start failed")
		assert(not Purchases.TryPurchase(player, "RoyalMintUpgrader08"), "Hidden last purchase accepted")
		local prices = { 250, 300, 400, 600, 1000, 1900, 3800, 7500 }
		local pending: BasePart? = nil
		for index = 1, 8 do
			if index == 2 then
				local model = unlocks:FindFirstChild("RoyalMint") :: Model
				local coins = model:FindFirstChild("ActiveBundles") :: Folder
				local limit = os.clock() + 5
				repeat
					for _, c in coins:GetChildren() do
						if c:IsA("BasePart") and c:GetAttribute("ProducerId") == "Dropper01" then
							pending = c
						end
					end
					if not pending then
						task.wait(0.05)
					end
				until pending or os.clock() > limit
				assert(pending and pending.Color ~= Mint.UPGRADED_COLOR, "Pending crossing fixture failed")
				for _, c in coins:GetChildren() do
					if c:IsA("BasePart") and c ~= pending then
						c.CFrame += Vector3.new(0, 0, 1000)
					end
				end
				local f = k:FindFirstChild("StarterFarm") :: Model
				for _, c in (f:FindFirstChild("ActiveBundles") :: Folder):GetChildren() do
					if c:IsA("BasePart") then
						c.CFrame += Vector3.new(0, 0, 1000)
					end
				end
				pending.Anchored = true
				pending.CFrame = CFrame.new(k:GetPivot():PointToWorldSpace(Vector3.new(-80, 4, -48)))
					* pending.CFrame.Rotation
			end
			local id = string.format("RoyalMintUpgrader%02d", index)
			assert(#plates:GetChildren() == 1 and plates:FindFirstChild(id), "Wrong purchase frontier")
			local snapshot = Data.GetSnapshot(player)
			assert(snapshot, "Snapshot missing")
			move(part(plates, id))
			assert(Purchases.TryPurchase(player, id), "Purchase failed " .. id)
			local after = Data.GetSnapshot(player)
			assert(after and after.Gold == snapshot.Gold - prices[index], "Wrong chain charge")
			assert(not Purchases.TryPurchase(player, id), "Duplicate purchase accepted")
			if index == 2 then
				assert(pending, "Missing pending coin")
				task.wait(0.35)
				assert(
					pending.Color == Mint.UPGRADED_COLOR,
					"Buying arch 2 erased pending passage through owned arch 1"
				)
				local model = unlocks:FindFirstChild("RoyalMint") :: Model
				pending.CFrame += part(model, "CollectionPit").Position - pending.Position
				task.wait(0.35)
				assert(
					model:GetAttribute("UncollectedGold") == 12,
					"Coin did not receive both old and new arch multipliers"
				)
			end
			local arch = unlocks:FindFirstChild(id) :: Model
			assert(arch, "Arch missing")
			local laser = part(arch, "GoldHologram")
			assert(
				laser.Material == Enum.Material.Neon
					and laser.Transparency > 0
					and laser.Transparency < 1
					and not laser.CanCollide
					and not laser.CanTouch
					and not laser.CanQuery,
				"Gold curtain contract failed"
			)
		end
		-- Restart the owned chain to isolate a fresh first-wave payout fixture.
		Plots.Release(player)
		task.wait(Config.PLOTS.CLAIM_COOLDOWN_SECONDS + 0.25)
		k = claim()
		unlocks = k:FindFirstChild("PurchaseUnlocks") :: Folder
		plates = k:FindFirstChild("PurchasePlates") :: Folder
		move(part(k, "FarmStartPlate"))
		assert(Farms.TryStart(player), "Owned chain restart failed")
		character:PivotTo(original)
		assert(#plates:GetChildren() == 0, "Completed chain left plates")
		local mint = unlocks:FindFirstChild("RoyalMint") :: Model
		local farm = k:FindFirstChild("StarterFarm") :: Model
		local bundles = mint:FindFirstChild("ActiveBundles") :: Folder
		local samples: { [string]: BasePart? } = {}
		local sampleDeadline = os.clock() + 5
		repeat
			for _, c in bundles:GetChildren() do
				if c:IsA("BasePart") then
					local id = c:GetAttribute("ProducerId")
					if typeof(id) == "string" then
						samples[id] = c
					end
				end
			end
			local count = 0
			for _ in samples do
				count += 1
			end
			if count == 8 then
				break
			end
			task.wait(0.05)
		until os.clock() > sampleDeadline
		for i = 1, 8 do
			assert(samples[string.format("Dropper%02d", i)], "Missing registered first wave")
		end
		assert(mint:GetAttribute("UncollectedGold") == 0, "Fixture did not isolate first wave")
		for _, w in (farm:FindFirstChild("ActiveBundles") :: Folder):GetChildren() do
			if w:IsA("BasePart") then
				w.CFrame += Vector3.new(0, 0, 1000)
			end
		end
		local pit = part(mint, "CollectionPit")
		-- Registered real coins jump across the whole path within one tick. This pins
		-- eight swept crossings and exact private values independently of frame timing.
		for _, coin in samples do
			if coin then
				coin.Anchored = true
				coin.CFrame += pit.Position - coin.Position
			end
		end
		local creditDeadline = os.clock() + 1
		repeat
			task.wait(0.05)
		until mint:GetAttribute("UncollectedGold") == 1530 or os.clock() > creditDeadline
		assert(
			mint:GetAttribute("UncollectedGold") == 1530,
			"Eight actual streams did not credit 768+384+192+96+48+24+12+6"
		)
		assert(farm:GetAttribute("UncollectedGold") == 1530, "Shared chain total diverged")
		move(part(mint, "CollectPlate"))
		local collected, amount = Farms.TryCollect(player, "RoyalMint")
		assert(collected and amount == 1530, "Chain collection failed")
		character:PivotTo(original)
		local observed: { [BasePart]: string } = {}
		local arrivals: { [string]: number } = {}
		local soakDeadline = os.clock() + 30
		repeat
			for _, c in bundles:GetChildren() do
				if c:IsA("BasePart") then
					local id = c:GetAttribute("ProducerId")
					assert(typeof(id) == "string", "Missing producer")
					observed[c] = id
				end
			end
			for c, id in observed do
				if c.Parent ~= bundles then
					assert((c.Position - pit.Position).Magnitude < 8, "Natural coin lost before collector")
					arrivals[id] = (arrivals[id] or 0) + 1
					observed[c] = nil
				end
			end
			assert(#bundles:GetChildren() <= Mint.MAX_BUNDLES, "Chain coin cap exceeded")
			task.wait(0.1)
		until os.clock() > soakDeadline
		for i = 1, 8 do
			assert((arrivals[string.format("Dropper%02d", i)] or 0) >= 3, "Natural stream starved")
		end
		Plots.Release(player)
		assert(bundles.Parent == nil, "Release leaked coins")
		task.wait(Config.PLOTS.CLAIM_COOLDOWN_SECONDS + 0.25)
		local restored = claim()
		local restoredUnlocks = restored:FindFirstChild("PurchaseUnlocks") :: Folder
		for i = 1, 8 do
			assert(
				restoredUnlocks:FindFirstChild(string.format("RoyalMintUpgrader%02d", i)),
				"Owned chain not restored"
			)
		end
		assert(not Farms.IsStarted(player), "Reclaim auto-started")
		return nil
	end, debug.traceback)
	Plots.Release(player)
	character:PivotTo(original)
	assert(
		Data.Update(player, function(draft)
			draft.Gold = before.Gold
			draft.PurchasedBuildings = before.PurchasedBuildings
		end),
		"Fixture restore failed"
	)
	assert(ok, reason)
	print("All eight Mint upgrader chain checks passed")
end
return Tests
