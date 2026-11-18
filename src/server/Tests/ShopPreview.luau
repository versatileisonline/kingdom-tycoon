--!strict
-- Explicit, transient Studio Mock fixture. Never saved as pass ownership.
local Preview = {}
function Preview.Run(): ()
	local Server = script.Parent.Parent
	local Entitlements = require(Server.Services.EntitlementService)
	assert(Entitlements.IsPreview(), "Studio Mock shop preview only")
	local Players = game:GetService("Players")
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	-- Leave the plot free for EntryService.TryEnter until the player presses Play.
	while player.Parent == Players and Entitlements.IsPreview() and player:GetAttribute("KingdomEntered") ~= true do
		task.wait(0.1)
	end
	if player.Parent ~= Players or not Entitlements.IsPreview() then
		return
	end
	Server:SetAttribute("StudioPreviewFrontier", "RoyalMintUpgrader01")
	Server:SetAttribute("StudioPreviewGold", 25000)
	require(script.Parent.TutorialPreview).Run()
	for _, offer in require(game.ReplicatedStorage.Shared.ShopConfig).OFFERS do
		Entitlements.SetPreview(player, offer.Key, false)
	end
	Server:SetAttribute("StudioPreviewFrontier", nil)
	Server:SetAttribute("StudioPreviewGold", nil)
	player:SetAttribute("ShopPreviewReady", true)
	print("[KingdomTycoon][ShopPreview] Shop preview ready (Studio Mock)")
end
return Preview
