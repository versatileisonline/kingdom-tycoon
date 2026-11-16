--!strict
local Tests = {}
function Tests.Run(): ()
	local shared = game:GetService("ReplicatedStorage").Shared
	local config = require(shared.Config)
	assert(
		config.DATA.STUDIO_MODE == "Mock"
			and not config.DATA.RUN_TESTS_IN_STUDIO
			and not config.PLOTS.RUN_TESTS_IN_STUDIO
			and not require(shared.PurchaseConfig).RUN_TESTS_IN_STUDIO
			and not require(shared.FarmConfig).RUN_TESTS_IN_STUDIO,
		"Run HUD tests alone in Mock"
	)
	local data = require(script.Parent.Parent.Services.DataService)
	local deadline = os.clock() + config.DATA.TEST_TIMEOUT_SECONDS
	local player: Player? = nil
	repeat
		player = game:GetService("Players"):GetPlayers()[1]
		if player and player:GetAttribute("GoldReady") == true then
			break
		end
		task.wait(0.1)
	until os.clock() > deadline
	assert(player ~= nil and player:GetAttribute("GoldReady") == true, "Gold presentation never ready")
	local owner = player :: Player
	local before = data.GetSnapshot(owner)
	assert(before ~= nil, "Snapshot unavailable")
	local ok, reason = pcall(function(): string?
		assert(data.Update(owner, function(draft): ()
			draft.Gold = 1234567
		end))
		task.wait(0.2)
		assert(owner:GetAttribute("Gold") == 1234567, "Committed Gold not presented")
		owner:SetAttribute("Gold", 9000000)
		assert((data.GetSnapshot(owner) :: any).Gold == 1234567, "Presentation changed authoritative data")
		return nil
	end)
	assert(data.Update(owner, function(draft): ()
		draft.Gold = before.Gold
	end))
	assert(ok, reason)
	print("All HUD presentation checks passed")
end
return Tests
