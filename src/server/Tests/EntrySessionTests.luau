--!strict
local Tests = {}
function Tests.Run(Session: any): ()
	local placements = 0
	local ready, succeeds = false, false
	local session = Session.new(1, function()
		return ready
	end, function()
		placements += 1
		return succeeds, "No free tycoon is available. Please retry."
	end)
	assert(not session.Request({}, 0), "Malformed payload accepted")
	assert(not session.Request("Play", 0), "Unready entry accepted")
	ready = true
	assert(not session.Request("Play", 0.5), "Cooldown bypassed")
	assert(placements == 0, "Cooldown or loading attempted placement")
	assert(not session.Request("Play", 1), "Failed placement accepted")
	assert(not session.Entered(), "Failed entry changed state")
	succeeds = true
	assert(session.Request("Play", 2), "Retry failed")
	assert(session.Entered() and placements == 2, "Retry did not commit entry")
	assert(session.Request("Play", 3), "Duplicate entry must acknowledge success")
	assert(placements == 2, "Duplicate entry teleported twice")
	print("All main menu entry checks passed")
end
return Tests
