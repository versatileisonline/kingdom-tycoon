--!strict

return table.freeze({
	MAX_ARMY_SIZE = 10,
	LOG_PREFIX = "KingdomTycoon",
	DATA = table.freeze({
		SCHEMA_VERSION = 1,
		STARTING_GOLD = 0,
		STARTING_REBIRTHS = 0,
		LIVE_STORE_NAME = "KingdomTycoon_PlayerData",
		TEST_STORE_NAME = "KingdomTycoon_PlayerData_Test",
		STUDIO_MODE = "Mock", -- "Mock" or "Persistent"; published servers always use the live store.
		RUN_TESTS_IN_STUDIO = false, -- Run the mock suite from the normal server Script context.
		PLAYER_KEY_PREFIX = "Player_",
		LOAD_TIMEOUT_SECONDS = 120,
		SHUTDOWN_TIMEOUT_SECONDS = 25,
		WAIT_INTERVAL_SECONDS = 0.1,
		MAX_SAFE_INTEGER = 9007199254740991,
		MAX_BUILDING_ID_LENGTH = 128,
		MAX_SCHEMA_DEPTH = 32,
		TEST_TIMEOUT_SECONDS = 20,
		TEST_GOLD = 77,
		TEST_KEY_PREFIX = "Verify_",
	}),
})
