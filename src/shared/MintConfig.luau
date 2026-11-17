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
local upgraders: { { Id: string, Multiplier: number } } = {}
for index = 1, 8 do
	table.insert(upgraders, table.freeze({ Id = string.format("RoyalMintUpgrader%02d", index), Multiplier = 2 }))
end
local first = table.freeze({
	PRODUCERS = table.freeze(producers),
	UPGRADERS = table.freeze(upgraders),
	UPGRADED_COLOR = Color3.fromRGB(255, 230, 96),
	RUN_UPGRADER_TESTS_IN_STUDIO = false,
	RUN_UPGRADER_CHAIN_TESTS_IN_STUDIO = false,
	PRODUCTION_SECONDS = 3,
	BUNDLE_VALUE = 3,
	MAX_BUNDLES = 32,
	COIN_COLLISION_GROUP = "KingdomMintCoins",
	TRACK_COLLISION_GROUP = "KingdomMintTrack",
	BUNDLE_LIFETIME_SECONDS = 20,
	CONVEYOR_SPEED = 8,
	RUN_TESTS_IN_STUDIO = false,
})

-- The original public fields remain aliases for first-lane consumers/tests.
local second = table.clone(first)
local secondProducers = {}
local secondUpgraders = {}
for index = 1, 8 do
	table.insert(
		secondProducers,
		table.freeze({
			Name = string.format("Dropper%02d", index),
			PurchaseId = if index == 1 then "RoyalMint02" else string.format("RoyalMint02Dropper%02d", index),
		})
	)
	table.insert(
		secondUpgraders,
		table.freeze({ Id = string.format("RoyalMint02Upgrader%02d", index), Multiplier = 2 })
	)
end
second.BUNDLE_VALUE = 9
second.PRODUCERS = table.freeze(secondProducers)
second.UPGRADERS = table.freeze(secondUpgraders)
local config = table.clone(first)
local sites: { [string]: typeof(first) } = { RoyalMint = first, RoyalMint02 = table.freeze(second) }
config.SITES = table.freeze(sites)
config.RUN_SECOND_LANE_TESTS_IN_STUDIO = false
return table.freeze(config)
