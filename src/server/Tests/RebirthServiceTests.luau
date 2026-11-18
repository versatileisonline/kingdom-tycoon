--!strict
local Tests = {}
function Tests.Run(): ()
	local Server = script.Parent.Parent
	local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local Data = require(Server.Services.DataService)
	local Plots = require(Server.Services.PlotService)
	local Farms = require(Server.Services.FarmService)
	local Rebirth = require(Server.Services.RebirthService)
	local Entitlements = require(Server.Services.EntitlementService)
	local Config = require(Shared.RebirthConfig)
	assert(game:GetService("RunService"):IsStudio() and Data.GetStorageMode() == "Mock", "Studio Mock only")
	require(script.Parent.RebirthEconomyTests).Run(require(Server.Farms.SessionEarnings), Config)
	local player: Player? = nil
	local deadline = os.clock() + 30
	repeat
		player = game:GetService("Players"):GetPlayers()[1]
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
	assert(before and Plots.GetKingdom(owner) == nil, "run before claim")
	local ownership: { [string]: boolean } = {}
	for _, offer in require(Shared.ShopConfig).OFFERS do
		ownership[offer.Key] = Entitlements.Owns(owner, offer.Key)
	end
	local function cooldown(): ()
		task.wait(Config.REQUEST_COOLDOWN + 0.1)
	end
	local function pending(): number
		local value = owner:GetAttribute("UncollectedGold")
		return if typeof(value) == "number" then value else 0
	end
	local ok, reason = xpcall(function()
		assert(
			Data.Update(owner, function(draft)
				draft.Gold = 99999
				draft.Rebirths = 0
				draft.PurchasedBuildings = { FarmDropper02 = true }
			end),
			"initial fixture"
		)
		local marker = workspace.Plots.Plot01.ClaimMarker
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 10)))
		assert(Plots.TryClaim(owner, "Plot01"), "claim fixture")
		local old = Plots.GetKingdom(owner) :: Model
		local plotId = Plots.GetPlotId(owner)
		local accepted = Rebirth.TryRebirth(owner, 0)
		assert(not accepted and Plots.GetKingdom(owner) == old, "below target preserves kingdom")
		local rejectedData = Data.GetSnapshot(owner)
		assert(rejectedData and rejectedData.Gold == 99999, "rejected rebirth preserves Gold")
		local failed, message = Plots.ResetKingdom(owner, function(): (boolean, string?)
			assert(Plots.IsResetting(owner), "reset interaction gate active during commit")
			return false, "deliberate rejected update"
		end)
		assert(not failed and message == "deliberate rejected update", "failed commit reported")
		assert(
			Plots.GetKingdom(owner) == old and old.Parent ~= nil and not Plots.IsResetting(owner),
			"failed commit retains live clone and releases gate"
		)
		assert(not Plots.ResetKingdom(owner, function(): (boolean, string?)
			error("deliberate mutation failure")
		end), "throwing commit rejected")
		assert(Plots.GetKingdom(owner) == old and not Plots.IsResetting(owner), "throwing commit preserves kingdom")
		local start = old:FindFirstChild("FarmStartPlate") :: BasePart
		character:PivotTo(CFrame.new(start.Position + Vector3.new(0, 3, 0)))
		assert(Farms.TryStart(owner), "start production fixture")
		character:PivotTo(CFrame.new(start.Position + Vector3.new(25, 3, 0)))
		local earningsDeadline = os.clock() + 25
		repeat
			task.wait(0.1)
		until pending() > 0 or os.clock() > earningsDeadline
		assert(pending() > 0, "physical fixture has uncollected earnings")
		assert(
			Data.Update(owner, function(draft)
				draft.Gold = 100000
			end),
			"exact target fixture"
		)
		cooldown()
		assert(Rebirth.TryRebirth(owner, 0), "exact banked target succeeds without full purchase chain")
		local after = Data.GetSnapshot(owner)
		assert(
			after and after.Gold == 0 and after.Rebirths == 1 and next(after.PurchasedBuildings) == nil,
			"reset and reward committed together"
		)
		local kingdom = Plots.GetKingdom(owner)
		assert(
			kingdom and kingdom ~= old and old.Parent == nil and Plots.GetPlotId(owner) == plotId,
			"same plot replacement destroys previous kingdom"
		)
		assert(
			pending() == 0 and owner:GetAttribute("StarterFarmStarted") ~= true,
			"pending earnings and started state cleared"
		)
		local newStart = kingdom:FindFirstChild("FarmStartPlate") :: BasePart
		assert(newStart and newStart.Parent ~= nil and newStart.Transparency < 1, "free Start Farm available again")
		for key, owned in ownership do
			assert(Entitlements.Owns(owner, key) == owned, "permanent passes preserved")
		end
		assert(not Rebirth.TryRebirth(owner, 0), "immediate duplicate rejected")
		cooldown()
		assert(not Rebirth.TryRebirth(owner, 0), "stale expected rebirth rejected after cooldown")
		local duplicateData = Data.GetSnapshot(owner)
		assert(duplicateData and duplicateData.Rebirths == 1, "duplicate never increments count")
		assert(
			Data.Update(owner, function(draft)
				draft.Gold = 199999
			end),
			"second target fixture"
		)
		cooldown()
		assert(not Rebirth.TryRebirth(owner, 1), "second rebirth requires doubled target")
		assert(
			Data.Update(owner, function(draft)
				draft.Gold = 200000
			end),
			"second exact target"
		)
		cooldown()
		assert(Rebirth.TryRebirth(owner, 1), "second exact target succeeds")
		after = Data.GetSnapshot(owner)
		assert(after and after.Rebirths == 2 and after.Gold == 0, "second reward applied once")
	end, debug.traceback)
	Plots.Release(owner)
	assert(
		Data.Update(owner, function(draft)
			draft.Gold = before.Gold
			draft.Rebirths = before.Rebirths
			draft.PurchasedBuildings = before.PurchasedBuildings
		end),
		"restore player fixture"
	)
	if character.Parent then
		character:PivotTo(original)
	end
	assert(ok, reason)
	print("[KingdomTycoon][RebirthTests] All rebirth service checks passed")
end
return Tests
