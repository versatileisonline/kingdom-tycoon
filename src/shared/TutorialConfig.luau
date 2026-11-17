--!strict
local Purchases = require(script.Parent.PurchaseConfig)
local Hud = require(script.Parent.HudConfig)
local function price(id: string): number
	for _, purchase in Purchases.PURCHASES do
		if purchase.Id == id then
			return purchase.Price
		end
	end
	error("Tutorial purchase is not configured: " .. id)
end
local paths: { [string]: { string } } = {
	StartFarm = { "FarmStartPlate" },
	FarmCollect = { "StarterFarm", "CollectPlate" },
	Walls = { "PurchasePlates", "WoodenWalls" },
	RoyalMint = { "PurchasePlates", "RoyalMint" },
	MintDropper02 = { "PurchasePlates", "RoyalMintDropper02" },
	MintCollect = { "PurchaseUnlocks", "RoyalMint", "CollectPlate" },
	Upgrader01 = { "PurchasePlates", "RoyalMintUpgrader01" },
}
for _, path in paths do
	table.freeze(path)
end
return table.freeze({
	STYLE = table.freeze({
		DisplayOrder = 5,
		Gold = Hud.COLORS.Gold,
		BrightGold = "FFF1A3",
		OutlineColor = "6B481C",
		MaxMarkers = 64,
		Spacing = 2,
		StartGap = 1.8,
		EndGap = 1.3,
		MarkerWidth = 1.2,
		MinPixels = 5,
		MaxPixels = 32,
		BaseTransparency = 0.62,
		PulseOpacity = 0.48,
		FlowSpeed = 5,
		Wavelength = 9,
	}),
	WORLD = table.freeze({ CharacterLift = 0.6, TargetLift = 0.25, NearDistance = 2 }),
	PRICES = table.freeze({
		Walls = price("WoodenWalls"),
		RoyalMint = price("RoyalMint"),
		MintDropper02 = price("RoyalMintDropper02"),
		Upgrader01 = price("RoyalMintUpgrader01"),
	}),
	ATTRIBUTES = table.freeze({
		WallsOwned = "TutorialWoodenWallsOwned",
		MintOwned = "TutorialRoyalMintOwned",
		MintDropper02Owned = "TutorialMintDropper02Owned",
		Upgrader01Owned = "TutorialRoyalMintUpgrader01Owned",
		FarmCollected = "TutorialFarmCollected",
		MintCollected = "TutorialMintCollected",
	}),
	TARGET_PATHS = table.freeze(paths),
	RUN_TESTS_IN_STUDIO = false,
})
