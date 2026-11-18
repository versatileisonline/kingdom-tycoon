--!strict
local Tests = {}
function Tests.Run(State: any, defaults: any): ()
	local state = State.new(defaults)
	assert(state.Get("Music") == 0.25 and state.Get("WorldSounds") == 1, "Defaults wrong")
	assert(state.Set("Music", 3) and state.Get("Music") == 1, "Volume not clamped")
	assert(state.Set("Music", -1) and state.Get("Music") == 0, "Mute failed")
	assert(not state.Set("Music", 0 / 0), "NaN accepted")
	assert(not state.Set("HelperArrow", 1), "Invalid boolean accepted")
	assert(state.Set("HelperArrow", false) and state.Get("HelperArrow") == false, "Toggle failed")
	assert(not state.Set("Unknown", true), "Unknown preference accepted")
	assert(State.FormatGold(nil) == "—", "Unavailable Gold presented as zero")
	assert(State.FormatGold(1234567) == "1,234,567", "Gold formatting incorrect")
	assert(State.new(defaults).Get("Music") == 0.25, "Preferences leaked between sessions")
	assert(State.DisplayGold(true, false, 26364, 112) == 26364, "nonowner keeps normal Gold display")
	assert(State.DisplayGold(true, true, 26364, 112) == 112, "collection badge matches plate total")
	assert(State.DisplayGold(true, true, 26476, 0) == 0, "successful collection resets display to zero")
	assert(State.DisplayGold(true, true, 26476, 3) == 3, "new arrivals update collection display")
	assert(State.DisplayGold(true, false, 26476, 3) == 26476, "revoking preview restores normal Gold")
	assert(State.DisplayGold(false, true, 26476, 112) == nil, "unready data not displayed")
	assert(State.DisplayGold(true, true, 26476, nil) == 0, "unclaimed owner has no pending earnings")
	print("All HUD state checks passed")
end
return Tests
