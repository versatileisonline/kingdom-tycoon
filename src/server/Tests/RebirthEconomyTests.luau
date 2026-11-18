--!strict
local Tests = {}
function Tests.Run(Accounts: any, Config: any): ()
	assert(Config.Target(0) == 100000 and Config.Target(1) == 200000 and Config.Target(2) == 400000, "doubling targets")
	assert(Config.Target(36) ~= nil and Config.Target(37) == nil, "safe-integer target boundary")
	for _, invalid in { -1, 0.5, math.huge, 0 / 0 } do
		assert(Config.Target(invalid) == nil, "invalid rebirth count rejected")
	end
	assert(
		Config.Multiplier(0) == 1 and Config.Multiplier(1) == 1.5 and Config.Multiplier(2) == 2,
		"permanent half-step reward"
	)
	local maximum = 9007199254740991
	local large = Accounts.new(maximum, function()
		return 1.5
	end)
	assert(not large.Credit(6004799503160661) and large.GetBalance() == 0, "rounded overflow rejected")
	local account = Accounts.new(100, function()
		return Config.Multiplier(1)
	end)
	assert(account.Credit(1) and account.GetBalance() == 1, "first fractional arrival preserves integer balance")
	assert(account.Credit(1) and account.GetBalance() == 3, "two arrivals retain the half Gold")
	local credited = 0
	assert(
		account.Collect(function(value: number): boolean
			credited += value
			return true
		end),
		"fractional account collects"
	)
	assert(credited == 3 and account.GetBalance() == 0, "banking does not apply multiplier twice")
	assert(account.Credit(1), "new remainder")
	account.Clear()
	assert(account.Credit(1) and account.GetBalance() == 1, "reset clears fractional remainder")
	assert(
		account.Collect(function(): boolean
			return true
		end),
		"collect whole Gold"
	)
	assert(account.Credit(1) and account.GetBalance() == 2, "collection preserves fractional remainder")
	local stacked = Accounts.new(100, function()
		return Config.Multiplier(1) * 2
	end)
	assert(stacked.Credit(3) and stacked.GetBalance() == 9, "Gold pass multiplies rebirth bonus")
	local bounded = Accounts.new(2, function()
		return 1.5
	end)
	assert(bounded.Credit(1), "first bounded credit")
	assert(
		not bounded.Credit(1) and bounded.GetBalance() == 1,
		"overflow rejects whole arrival without changing balance"
	)
	for _, invalid in { 0, -1, 1.25, math.huge, 0 / 0 } do
		local invalidAccount = Accounts.new(100, function()
			return invalid
		end)
		assert(not invalidAccount.Credit(1) and invalidAccount.GetBalance() == 0, "invalid multiplier rejected")
	end
	assert(
		not account.Credit(0 / 0) and not account.Credit(math.huge) and not account.Credit(0.5),
		"invalid arrivals rejected"
	)
	print("[KingdomTycoon][RebirthTests] All rebirth economy checks passed")
end
return Tests
