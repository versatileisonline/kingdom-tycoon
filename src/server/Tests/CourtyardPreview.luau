--!strict
-- Opt-in normal-bootstrap Studio Mock fixture; never runs in published servers.
local Preview = {}
function Preview.Run(): ()
	local Server = script.Parent.Parent
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	local Data = require(Server.Services.DataService)
	assert(Data.GetStorageMode() == "Mock", "Mock only")
	local deadline = os.clock() + 90
	local player: Player?
	repeat
		player = game:GetService("Players"):GetPlayers()[1]
		if
			player
			and player.Character
			and player:GetAttribute("KingdomEntered") == true
			and Data.GetSnapshot(player)
		then
			break
		end
		task.wait(0.1)
	until os.clock() > deadline
	assert(
		player and player.Character and player:GetAttribute("KingdomEntered") == true,
		"Press Play to enter courtyard preview"
	)
	Server:SetAttribute("StudioPreviewFrontier", "RoyalMintUpgrader01")
	Server:SetAttribute("StudioPreviewGold", 100000)
	require(script.Parent.TutorialPreview).Run()
	assert(Data.Update(player, function(draft)
		for _, definition in require(game.ReplicatedStorage.Shared.PurchaseConfig).PURCHASES do
			if definition.Optional then
				draft.PurchasedBuildings[definition.Id] = true
			end
		end
	end))
	task.wait(0.3)
	local kingdom = require(Server.Services.PlotService).GetKingdom(player)
	assert(kingdom and player.Character, "Missing courtyard")
	player.Character:PivotTo(kingdom:GetPivot() * CFrame.new(44, 3, 53))
	Server:SetAttribute("CourtyardPreviewReady", true)
	print("Medieval courtyard preview ready (Studio Mock; all scenery, sword and training owned)")
end
return Preview
