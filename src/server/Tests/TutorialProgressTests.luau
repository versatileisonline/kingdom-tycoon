--!strict
local Tests = {}
function Tests.Run(Progress: any): ()
	local owner = Instance.new("Folder")
	Progress.Publish(owner, nil)
	assert(owner:GetAttribute("TutorialWoodenWallsOwned") == nil, "Unavailable ownership not cleared")
	Progress.Publish(owner, {
		PurchasedBuildings = {
			WoodenWalls = true,
			RoyalMint = true,
			RoyalMintDropper02 = false,
			RoyalMintUpgrader01 = true,
		},
	})
	assert(
		owner:GetAttribute("TutorialWoodenWallsOwned") == true
			and owner:GetAttribute("TutorialMintDropper02Owned") == false,
		"Ownership presentation wrong"
	)
	Progress.ResetCollections(owner)
	assert(
		owner:GetAttribute("TutorialFarmCollected") == false and owner:GetAttribute("TutorialMintCollected") == false,
		"Collection tutorial not reset"
	)
	Progress.MarkCollected(owner, "UnknownSite")
	assert(
		owner:GetAttribute("TutorialFarmCollected") == false and owner:GetAttribute("TutorialMintCollected") == false,
		"Wrong site completed tutorial"
	)
	Progress.MarkCollected(owner, "StarterFarm")
	assert(
		owner:GetAttribute("TutorialFarmCollected") == true and owner:GetAttribute("TutorialMintCollected") == false,
		"Farm collection completed wrong site"
	)
	Progress.MarkCollected(owner, "RoyalMint")
	assert(owner:GetAttribute("TutorialMintCollected") == true, "Mint collection not completed")
	Progress.ResetCollections(owner)
	assert(
		owner:GetAttribute("TutorialFarmCollected") == false and owner:GetAttribute("TutorialMintCollected") == false,
		"Claim reset retained tutorial state"
	)
	owner:Destroy()
	print("All tutorial presentation checks passed")
end
return Tests
