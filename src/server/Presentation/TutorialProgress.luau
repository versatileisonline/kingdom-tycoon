--!strict
-- Read-only UI presentation. These attributes never authorize gameplay actions.
local Progress = {}
local ownedAttributes: { [string]: string } = {
	WoodenWalls = "TutorialWoodenWallsOwned",
	RoyalMint = "TutorialRoyalMintOwned",
	RoyalMintDropper02 = "TutorialMintDropper02Owned",
	RoyalMintUpgrader01 = "TutorialRoyalMintUpgrader01Owned",
}
function Progress.Publish(player: Instance, data: { PurchasedBuildings: { [string]: boolean } }?): ()
	for id, attribute in ownedAttributes do
		player:SetAttribute(attribute, if data then data.PurchasedBuildings[id] == true else nil)
	end
end
function Progress.ResetCollections(player: Instance): ()
	player:SetAttribute("TutorialFarmCollected", false)
	player:SetAttribute("TutorialMintCollected", false)
end
function Progress.MarkCollected(player: Instance, siteId: string): ()
	if siteId == "StarterFarm" then
		player:SetAttribute("TutorialFarmCollected", true)
	elseif siteId == "RoyalMint" then
		player:SetAttribute("TutorialMintCollected", true)
	end
end
return Progress
