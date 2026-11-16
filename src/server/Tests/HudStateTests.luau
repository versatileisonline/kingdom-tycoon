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
	print("All HUD state checks passed")
end
return Tests
