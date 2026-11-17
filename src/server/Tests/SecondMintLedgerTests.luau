--!strict
local Tests = {}
function Tests.Run(Ledger: any, Account: any): ()
	local a = Account.new(9007199254740991)
	local one = Ledger.new(32, 20, 3, 9007199254740991, a)
	local two = Ledger.new(32, 20, 9, 9007199254740991, a)
	for index = 1, 8 do
		local t1, t2 = {}, {}
		assert(one.Register(t1, 0) and two.Register(t2, 0), "Registration failed")
		assert(not two.ApplyUpgrade(t1, "foreign", 2, 1), "Foreign token accepted")
		for arch = index, 8 do
			assert(one.ApplyUpgrade(t1, "a" .. arch, 2, 1))
			assert(two.ApplyUpgrade(t2, "b" .. arch, 2, 1))
			assert(not two.ApplyUpgrade(t2, "b" .. arch, 2, 1), "Duplicate upgrade accepted")
		end
		assert(one.Remove(t1, 2, true) and two.Remove(t2, 2, true), "Arrival failed")
	end
	assert(a.GetBalance() == 6120, "Combined exact waves incorrect")
	assert(not a.Collect(function()
		return false
	end) and a.GetBalance() == 6120, "Failed credit lost earnings")
	local ok, amount = a.Collect(function(n)
		return n == 6120
	end)
	assert(ok and amount == 6120 and a.GetBalance() == 0, "Shared collection incorrect")
	print("Two-lane ledger isolation, exact 6120 payout and failed-credit retention passed")
end
return Tests
