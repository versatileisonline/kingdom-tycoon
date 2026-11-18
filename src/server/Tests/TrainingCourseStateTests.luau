--!strict
local Tests = {}
function Tests.Run(State: any): ()
	local s = State.New()
	assert(not State.Checkpoint(s, 1), "Unstarted checkpoint accepted")
	assert(State.Start(s, 10), "Start failed")
	assert(not State.Start(s, 11), "Duplicate start reset timer")
	assert(not State.Checkpoint(s, 2), "Skipped checkpoint accepted")
	assert(State.Checkpoint(s, 1), "First checkpoint rejected")
	assert(s.Checkpoint == 1 and State.Elapsed(s, 15) == 5, "Recovery must preserve timer/checkpoint")
	assert(not State.Finish(s, 15, 3), "Early finish accepted")
	assert(State.Checkpoint(s, 2) and State.Checkpoint(s, 3), "Ordered sections failed")
	assert(State.Finish(s, 20, 3) == 10 and s.Best == 10, "Finish time incorrect")
	assert(State.Start(s, 30), "Retry rejected")
	State.Cancel(s)
	assert(not s.Active and s.Best == 10, "Cancellation lost session best")
	assert(State.Start(s, 40), "Second retry rejected")
	for i = 1, 3 do
		State.Checkpoint(s, i)
	end
	assert(State.Finish(s, 48, 3) == 8 and s.Best == 8, "Best did not improve")
	assert(State.New().Best == nil, "New kingdom retained best")
	print("All medieval course state checks passed")
end
return Tests
