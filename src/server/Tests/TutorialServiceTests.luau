--!strict
local Tests = {}
function Tests.Run(): ()
	local Shared = game.ReplicatedStorage.Shared
	local Config = require(Shared.Config)
	assert(game:GetService("RunService"):IsStudio() and Config.DATA.STUDIO_MODE == "Mock", "Studio Mock only")
	local suites: { { RUN_TESTS_IN_STUDIO: boolean } } = {
		require(Shared.FarmConfig),
		require(Shared.PurchaseConfig),
		require(Shared.HudConfig),
		require(Shared.MintConfig),
	}
	for _, settings in suites do
		assert(not settings.RUN_TESTS_IN_STUDIO, "Run tutorial suite separately")
	end
	local Data = require(script.Parent.Parent.Services.DataService)
	local Plots = require(script.Parent.Parent.Services.PlotService)
	local Farms = require(script.Parent.Parent.Services.FarmService)
	require(script.Parent.TutorialProgressTests).Run(require(script.Parent.Parent.Presentation.TutorialProgress))
	require(script.Parent.TutorialStateTests).Run(
		require(game.StarterPlayer.StarterPlayerScripts.Client.UI.TutorialState)
	)
	local p: Player? = nil
	local limit = os.clock() + 30
	repeat
		p = game.Players:GetPlayers()[1]
		if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and Data.GetSnapshot(p) then
			break
		end
		task.wait(0.1)
	until os.clock() > limit
	assert(p and p.Character, "Player unavailable")
	local owner = p :: Player
	local c = owner.Character :: Model
	local before = Data.GetSnapshot(owner)
	assert(before and not Plots.GetKingdom(owner), "Run before claiming")
	local position = c:GetPivot()
	local function part(parent: Instance, name: string): BasePart
		local v = parent:FindFirstChild(name)
		assert(v and v:IsA("BasePart"), "Missing " .. name)
		return v
	end
	local function move(v: BasePart): ()
		c:PivotTo(CFrame.new(v.Position + Vector3.new(0, 3, 0)))
	end
	local ok, reason = xpcall(function(): string?
		assert(
			Data.Update(owner, function(draft)
				draft.Gold = 0
				draft.PurchasedBuildings = {
					FarmDropper02 = true,
					FarmDropper03 = true,
					FarmDropper04 = true,
					WoodenWalls = true,
					RoyalMint = true,
					RoyalMintDropper02 = true,
				}
			end),
			"Fixture setup failed"
		)
		assert(
			owner:GetAttribute("TutorialWoodenWallsOwned") == true
				and owner:GetAttribute("TutorialRoyalMintOwned") == true
				and owner:GetAttribute("TutorialMintDropper02Owned") == true
				and owner:GetAttribute("TutorialRoyalMintUpgrader01Owned") == false,
			"Ownership signals differ from committed data"
		)
		local marker = workspace.Plots.Plot01.ClaimMarker
		c:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 10)))
		assert(Plots.TryClaim(owner, "Plot01"), "Claim failed")
		local k = Plots.GetKingdom(owner)
		assert(k, "Kingdom absent")
		assert(
			owner:GetAttribute("TutorialFarmCollected") == false
				and owner:GetAttribute("TutorialMintCollected") == false,
			"Claim did not reset collection guidance"
		)
		move(part(k, "FarmStartPlate"))
		assert(Farms.TryStart(owner), "Start failed")
		c:PivotTo(position)
		local farm = k:FindFirstChild("StarterFarm") :: Model
		local mint = (k:FindFirstChild("PurchaseUnlocks") :: Folder):FindFirstChild("RoyalMint") :: Model
		local incomeLimit = os.clock() + 20
		repeat
			task.wait(0.25)
		until (farm:GetAttribute("UncollectedGold") :: number) >= 1 or os.clock() > incomeLimit
		assert((farm:GetAttribute("UncollectedGold") :: number) >= 1, "No production")
		assert(
			Data.Update(owner, function(draft)
				draft.Gold = Config.DATA.MAX_SAFE_INTEGER
			end),
			"Overflow fixture failed"
		)
		move(part(farm, "CollectPlate"))
		assert(not Farms.TryCollect(owner), "Overflow collection accepted")
		assert(
			owner:GetAttribute("TutorialFarmCollected") == false
				and owner:GetAttribute("TutorialMintCollected") == false,
			"Failed collection completed tutorial"
		)
		c:PivotTo(position)
		assert(
			Data.Update(owner, function(draft)
				draft.Gold = 0
			end),
			"Fixture reset failed"
		)
		task.wait(1.3)
		move(part(farm, "CollectPlate"))
		assert(Farms.TryCollect(owner), "Farm collection failed")
		assert(
			owner:GetAttribute("TutorialFarmCollected") == true and owner:GetAttribute("TutorialMintCollected") == false,
			"Farm collect completed wrong tutorial"
		)
		c:PivotTo(position)
		task.wait(3.5)
		move(part(mint, "CollectPlate"))
		assert(Farms.TryCollect(owner, "RoyalMint"), "Mint collection failed")
		assert(
			owner:GetAttribute("TutorialMintCollected") == true,
			"Successful Mint collection did not complete guidance"
		)
		Plots.Release(owner)
		assert(
			owner:GetAttribute("TutorialFarmCollected") == false
				and owner:GetAttribute("TutorialMintCollected") == false,
			"Release retained stale tutorial"
		)
		return nil
	end, debug.traceback)
	Plots.Release(owner)
	c:PivotTo(position)
	assert(
		Data.Update(owner, function(draft)
			draft.Gold = before.Gold
			draft.PurchasedBuildings = before.PurchasedBuildings
		end),
		"Restore failed"
	)
	assert(ok, reason)
	print("All tutorial service checks passed")
end
return Tests
