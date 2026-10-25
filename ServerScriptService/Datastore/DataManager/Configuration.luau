return {
	AUTOSAVE_INTERVAL = 300,
	KEEP_SAVES_STUDIO = true,
	MAX_RETRIES = 5,
	LEADERBOARD_CACHE_DURATION = 30,
	DEFAULT_DATA = table.freeze({
		Coins = 0,
		XP = 0,
		Kills = 0,
		PermissionLevel = 0,
		SelectedTag = "",
		Tags = table.freeze({
			VIP = false,
			Tester = true,
			["Lead Developer"] = false
		}),
		Settings = table.freeze({
			Keybinds = table.freeze({
				Sprint = "LeftShift",
				Dash = "Q",
				Shiftlock = "LeftAlt",
				Hook = "E",
				Uppercut = "R",
				BodyShot = "F",
				Overhand = "C",
				Block = "G",
			})
		})
	}),
	DEFAULT_SESSION_DATA = table.freeze({
		Kills = 0,
		Deaths = 0
	}),
}