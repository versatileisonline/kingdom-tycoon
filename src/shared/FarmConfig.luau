--!strict

return table.freeze({
	PRODUCTION_SECONDS = 3,
	PRODUCERS = table.freeze({
		table.freeze({ Name = "Starter", PurchaseId = "" }),
		table.freeze({ Name = "Dropper02", PurchaseId = "FarmDropper02" }),
		table.freeze({ Name = "Dropper03", PurchaseId = "FarmDropper03" }),
		table.freeze({ Name = "Dropper04", PurchaseId = "FarmDropper04" }),
	}),
	BUNDLE_VALUE = 1,
	MAX_BUNDLES = 12,
	BUNDLE_LIFETIME_SECONDS = 20,
	TICK_SECONDS = 0.25,
	CONVEYOR_SPEED = 8,
	COLLECT_DISTANCE = 8, -- Distance from the plate's surface, not its center.
	COLLECT_COOLDOWN_SECONDS = 1,
	START_DISTANCE = 5, -- Distance from the start plate's surface.
	START_COOLDOWN_SECONDS = 1,
	RUN_TESTS_IN_STUDIO = false,
})
