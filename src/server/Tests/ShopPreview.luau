--!strict
-- Explicit, transient Studio Mock fixture. Never saved as pass ownership.
local Preview = {}
function Preview.Run(): ()
	local Server = script.Parent.Parent
	local Entitlements = require(Server.Services.EntitlementService)
	assert(Entitlements.IsPreview(), "Studio Mock shop preview only")
	Server:SetAttribute("StudioPreviewFrontier", "RoyalMintUpgrader01")
	Server:SetAttribute("StudioPreviewGold", 25000)
	require(script.Parent.TutorialPreview).Run()
	local player = game.Players:GetPlayers()[1]
	assert(player, "Preview player unavailable")
	for _, offer in require(game.ReplicatedStorage.Shared.ShopConfig).OFFERS do
		Entitlements.SetPreview(player, offer.Key, false)
	end
	Server:SetAttribute("StudioPreviewFrontier", nil)
	Server:SetAttribute("StudioPreviewGold", nil)
	player:SetAttribute("ShopPreviewReady", true)
	print("[KingdomTycoon][ShopPreview] Shop preview ready (Studio Mock)")
end
return Preview
