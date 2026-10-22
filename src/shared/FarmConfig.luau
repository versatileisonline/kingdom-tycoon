--!strict

return table.freeze({
	PRODUCTION_SECONDS = 3,
	BUNDLE_VALUE = 1,
	MAX_BUNDLES = 12,
	BUNDLE_LIFETIME_SECONDS = 20,
	TICK_SECONDS = 0.25,
	CONVEYOR_SPEED = 8,
	COLLECT_DISTANCE = 8, -- Distance from the plate's surface, not its center.
	COLLECT_COOLDOWN_SECONDS = 1,
	RUN_TESTS_IN_STUDIO = false,
})
