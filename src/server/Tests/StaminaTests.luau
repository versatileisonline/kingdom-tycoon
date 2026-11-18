--!strict
local Tests = {}
function Tests.Run(Stamina: any): ()
	local s = Stamina.New()
	Stamina.SetHeld(s, true)
	Stamina.Step(s, 6, true, true)
	assert(s.Remaining == 0 and s.Exhausted and not s.Active, "Six-second exhaustion failed")
	Stamina.Step(s, 1, true, true)
	assert(s.Remaining == 0, "Recovery delay missing")
	Stamina.Step(s, 4, true, true)
	assert(s.Remaining == 6 and not s.Active, "Held sprint auto-restarted after exhaustion")
	Stamina.SetHeld(s, false)
	Stamina.SetHeld(s, true)
	Stamina.Step(s, 1, true, true)
	assert(s.Active and s.Remaining == 5, "Release did not rearm sprint")
	local still = Stamina.New()
	Stamina.SetHeld(still, true)
	Stamina.Step(still, 2, false, true)
	assert(still.Remaining == 6 and not still.Active, "Standing drained stamina")
	Stamina.Step(s, 1, true, false)
	assert(not s.Active and not s.Held, "Revoked sprint remained active")
	print("All stamina checks passed")
end
return Tests
