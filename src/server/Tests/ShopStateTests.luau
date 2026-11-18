--!strict
local Tests = {}
function Tests.Run(State: any): ()
	local function check(
		status: string,
		price: number?,
		available: boolean,
		expected: string,
		expectedEnabled: boolean
	): ()
		local label, enabled = State.Offer(status, price, available)
		assert(label == expected and enabled == expectedEnabled, "offer state: " .. status)
	end
	check("Owned", 49, true, "Owned", false)
	check("Unowned", 49, true, "49 Robux", true)
	check("Loading", 49, true, "Loading…", false)
	check("Unavailable", 49, true, "Unavailable", false)
	check("Unowned", nil, false, "Unavailable", false)
	print("[KingdomTycoon][ShopTests] All shop presentation checks passed")
end
return Tests
