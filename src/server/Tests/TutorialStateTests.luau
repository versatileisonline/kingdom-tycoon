--!strict
local Tests = {}
function Tests.Run(State: any): ()
	local prices = { Walls = 40, RoyalMint = 60, MintDropper02 = 70, Upgrader01 = 250 }
	local input = {
		Ready = true,
		Started = false,
		FarmCollected = false,
		MintCollected = false,
		WallsOwned = false,
		MintOwned = false,
		MintDropper02Owned = false,
		Upgrader01Owned = false,
		Gold = 0,
		Balance = 0,
	}
	assert(State.Select(input, prices) == "StartFarm", "Free initial farm guidance missing")
	input.Ready = false
	assert(State.Select(input, prices) == nil, "Loading data showed a tutorial target")
	input.Ready = true
	input.Started = true
	assert(State.Select(input, prices) == nil, "Empty collector received guidance")
	input.Balance = 1
	assert(State.Select(input, prices) == "FarmCollect", "First available farm earnings not guided")
	input.FarmCollected = true
	input.Balance = 10
	input.Gold = 39
	assert(State.Select(input, prices) == nil, "Unaffordable walls guided or collector repeated")
	input.Gold = 40
	assert(State.Select(input, prices) == "Walls", "Affordable walls not guided")
	input.WallsOwned = true
	input.Gold = 59
	assert(State.Select(input, prices) == nil, "Unaffordable Mint guided")
	input.Gold = 60
	assert(State.Select(input, prices) == "RoyalMint", "First Mint not guided")
	input.MintOwned = true
	input.Gold = 69
	assert(State.Select(input, prices) == nil, "Unaffordable indoor dropper guided")
	input.Gold = 70
	assert(State.Select(input, prices) == "MintDropper02", "First paid indoor dropper not guided")
	input.MintDropper02Owned = true
	input.Balance = 0
	assert(State.Select(input, prices) == nil, "Empty Mint collector guided")
	input.Balance = 1
	assert(State.Select(input, prices) == "MintCollect", "First Mint collection missing")
	input.MintCollected = true
	input.Gold = 249
	assert(State.Select(input, prices) == nil, "Unavailable upgrader guided")
	input.Gold = 250
	assert(State.Select(input, prices) == "Upgrader01", "First affordable upgrader missing")
	input.Upgrader01Owned = true
	input.Gold = 100000
	input.Balance = 100
	assert(State.Select(input, prices) == nil, "Completed tutorial repeated familiar purchases/collections")
	input.Started = false
	assert(State.Select(input, prices) == "StartFarm", "New claim did not require activation")
	input.Started = true
	input.Gold = 0 / 0
	input.Upgrader01Owned = false
	assert(State.Select(input, prices) == nil, "NaN Gold passed affordability")
	input.Gold = 40
	input.WallsOwned = false
	input.MintOwned = false
	input.MintDropper02Owned = false
	assert(State.Select(input, prices) == "Walls", "Stage choice depends on previous client-local state")
	print("All tutorial stage checks passed")
end
return Tests
