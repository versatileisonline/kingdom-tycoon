--!strict
return table.freeze({
	ART = table.freeze({
		Coin = "rbxassetid://94873438043725",
		Corner = "rbxassetid://81173608072407",
		Banner = "rbxassetid://100935518284790",
	}),
	UI = table.freeze({
		PanelWidth = 460,
		PanelHeight = 440,
		OrnamentSize = 96,
		Margin = 32,
		BadgeCoinSize = 18,
		BadgeWidth = 220,
		BadgeHeight = 58,
		BadgeInset = 18,
		BadgeCollectExtraWidth = 78,
		CoinSize = 16,
		CoinGap = 4,
	}),
	DEFAULTS = table.freeze({
		Music = 0.25,
		WorldSounds = 1,
		HelperArrow = true,
		LowGraphics = false,
		MenuOpen = false,
		ShopOpen = false,
		RebirthOpen = false,
	}),
	COLORS = table.freeze({
		Panel = "201F25",
		Raised = "183E65",
		Border = "B38C45",
		Gold = "E7B84B",
		Text = "F5E8CE",
		Muted = "C8B697",
		Track = "12151E",
	}),
	-- Free Creator Store medieval court, peaceful keep and dramatic battle tracks.
	MUSIC_IDS = table.freeze({ 139186694323000, 87479584695420, 137177134668386 }),
	MUSIC_LOAD_SECONDS = 12,
	RUN_TESTS_IN_STUDIO = false,
})
