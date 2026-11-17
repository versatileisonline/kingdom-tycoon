--!strict

local producers: { { Name: string, PurchaseId: string } } = {}
for index = 1, 8 do
	table.insert(
		producers,
		table.freeze({
			Name = string.format("Dropper%02d", index),
			PurchaseId = if index == 1 then "RoyalMint" else string.format("RoyalMintDropper%02d", index),
		})
	)
end
return table.freeze({
	PRODUCERS = table.freeze(producers),
	PRODUCTION_SECONDS = 3,
	BUNDLE_VALUE = 3,
	MAX_BUNDLES = 32,
	COIN_COLLISION_GROUP = "KingdomMintCoins",
	TRACK_COLLISION_GROUP = "KingdomMintTrack",
	BUNDLE_LIFETIME_SECONDS = 20,
	CONVEYOR_SPEED = 8,
	RUN_TESTS_IN_STUDIO = false,
})
