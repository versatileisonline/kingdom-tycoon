--!strict
local Tests = {}
function Tests.Run(State: any): ()
	local input = {
		{ UserId = 3, Name = "Loading" },
		{ UserId = 2, Name = "Second", LifetimeGold = 20, Rebirths = 8 },
		{ UserId = 1, Name = "First", LifetimeGold = 20, Rebirths = 0 },
		{ UserId = 4, Name = "Last", LifetimeGold = 0, Rebirths = 0 },
	}
	local sorted = State.Sort(input)
	assert(sorted[1].UserId == 1 and sorted[2].UserId == 2, "Gold ties must use stable UserId order")
	assert(sorted[3].UserId == 4 and sorted[4].LifetimeGold == nil, "Loading players rank after ready players")
	assert(input[1].UserId == 3, "Sorting mutated source")
	assert(State.Format(1240500) == "1,240,500" and State.Format(0) == "0", "Exact Gold formatting")
	assert(State.Format(nil) == "...", "Loading must not appear as zero")
	assert(#State.Sort({}) == 0, "Empty server")
	print("[LeaderboardClientTests] All checks passed")
end
return Tests
