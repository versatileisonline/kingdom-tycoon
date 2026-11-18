--!strict
local Tests = {}
function Tests.Run(Accounts: any, Ledger: any): ()
	local multiplier = 1
	local account = Accounts.new(100000, function()
		return multiplier
	end)
	assert(account.Credit(7), "base credit")
	multiplier = 2
	assert(account.GetBalance() == 7, "pass must not double old pending earnings")
	assert(account.Credit(3) and account.GetBalance() == 13, "new earnings double exactly once")
	local success = account.Collect(function()
		return false
	end)
	assert(not success and account.GetBalance() == 13, "failed credit retained")
	local collected = 0
	assert(
		account.Collect(function(value)
			collected += value
			return true
		end),
		"collect succeeds"
	)
	assert(collected == 13 and account.GetBalance() == 0, "banking must not double again")
	assert(not account.Collect(function()
		error("duplicate bank")
	end), "empty collection rejected")
	local ledger = Ledger.new(4, 20, 3, 100000, account)
	local token = {}
	assert(ledger.Register(token, 0), "register")
	assert(ledger.ApplyUpgrade(token, "Arch", 2, 1), "arch")
	assert(ledger.Remove(token, 2, true), "arrival")
	assert(account.GetBalance() == 12, "pass stacks after arch exactly once")
	assert(not ledger.Remove(token, 2, true) and account.GetBalance() == 12, "duplicate arrival rejected")
	local capped = Accounts.new(10, function()
		return 2
	end)
	assert(not capped.Credit(6) and capped.GetBalance() == 0, "scaled cap respected")
	assert(not capped.Credit(0 / 0) and not capped.Credit(math.huge), "invalid numbers rejected")
	print("[KingdomTycoon][ShopTests] All shop economy checks passed")
end
return Tests
