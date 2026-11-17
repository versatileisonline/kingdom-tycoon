--!strict
return table.freeze({
	GOLD_ICON = "●",
	DEFAULTS = table.freeze({
		Music = 0.25,
		WorldSounds = 1,
		HelperArrow = true,
		LowGraphics = false,
		MenuOpen = false,
	}),
	COLORS = table.freeze({
		Panel = "39291F",
		Raised = "513A29",
		Border = "A77E43",
		Gold = "E7B84B",
		Text = "F5E8CE",
		Muted = "C8B697",
		Track = "241B16",
	}),
	-- Free Creator Store medieval court, peaceful keep and dramatic battle tracks.
	MUSIC_IDS = table.freeze({ 139186694323000, 87479584695420, 137177134668386 }),
	MUSIC_LOAD_SECONDS = 12,
	RUN_TESTS_IN_STUDIO = false,
})
