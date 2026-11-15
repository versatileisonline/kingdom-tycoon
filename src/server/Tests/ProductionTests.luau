--!strict
local Scheduler = require(script.Parent.Parent.Farms.ProducerScheduler)
local Tests = {}

function Tests.Run(): ()
	local scheduler = Scheduler.new(4, 3)
	scheduler.SetEnabled(1, true, 0)
	assert(#scheduler.TakeDue(2, 12) == 0, "Produced before interval")
	assert(scheduler.TakeDue(3, 12)[1] == 1, "Starter failed to produce")
	for index = 2, 4 do
		scheduler.SetEnabled(index, true, 3)
	end
	assert(#scheduler.TakeDue(6, 12) == 4, "Owned droppers did not produce together")
	assert(#scheduler.TakeDue(6, 12) == 0, "Duplicate production at same time")
	assert(#scheduler.TakeDue(60, 12) == 4, "Missed time produced catch-up burst")
	local served: { [number]: boolean } = {}
	for now = 63, 72, 3 do
		local due = scheduler.TakeDue(now, 1)
		assert(#due == 1, "Exceeded shared capacity")
		served[due[1]] = true
	end
	for index = 1, 4 do
		assert(served[index], "Capacity contention starved a producer")
	end
	assert(#scheduler.TakeDue(75, 0) == 0, "Produced at capacity")
	assert(#scheduler.TakeDue(75, 12) == 0, "Capacity skip accumulated backlog")
	scheduler.SetEnabled(4, false, 75)
	assert(#scheduler.TakeDue(78, 12) == 3, "Disabled producer still ran")
	scheduler.SetEnabled(1, true, 79)
	assert(#scheduler.TakeDue(81, 12) == 3, "Refresh reset an existing timer")
	print("All producer scheduling checks passed")
end

return Tests
