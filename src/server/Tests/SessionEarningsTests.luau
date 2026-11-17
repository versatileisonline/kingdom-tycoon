--!strict
local SessionEarnings = require(script.Parent.Parent.Farms.SessionEarnings)
local FarmLedger = require(script.Parent.Parent.Farms.FarmLedger)
local Tests = {}
function Tests.Run(): ()
	local account = SessionEarnings.new(100)
	local farm = FarmLedger.new(12, 20, 1, 100, account)
	local mint = FarmLedger.new(32, 20, 3, 100, account)
	assert(farm.Register("wheat", 0) and mint.Register("coin", 0), "Shared earnings invariant failed")
	assert(farm.Remove("wheat", 1, true) and mint.Remove("coin", 1, true), "Shared earnings invariant failed")
	assert(
		account.GetBalance() == 4 and farm.GetBalance() == 4 and mint.GetBalance() == 4,
		"Shared earnings invariant failed"
	)
	assert(not mint.Remove("coin", 1, true), "Duplicate arrival credited")
	local ok = account.Collect(function(_amount)
		return false
	end)
	assert(not ok and account.GetBalance() == 4, "Failed save lost shared earnings")
	local credits = 0
	local collected, amount = account.Collect(function(value)
		credits += value
		return true
	end)
	assert(collected and amount == 4 and credits == 4 and account.GetBalance() == 0, "Shared earnings invariant failed")
	assert(not account.Collect(function(_value)
		error("Empty collection committed")
	end), "Empty collection accepted")
	assert(
		account.Credit(99) and not account.Credit(3) and account.GetBalance() == 99,
		"Shared earnings invariant failed"
	)
	assert(not account.Credit(-1) and not account.Credit(0 / 0), "Shared earnings invariant failed")
	farm.Clear()
	assert(account.GetBalance() == 99, "Site cleanup erased another site earnings")
	account.Clear()
	assert(account.GetBalance() == 0, "Shared earnings invariant failed")
	local isolated = FarmLedger.new(1, 20, 1, 100)
	assert(isolated.Register("old", 0) and isolated.Remove("old", 1, true), "Shared earnings invariant failed")
	isolated.Clear()
	assert(isolated.GetBalance() == 0, "Legacy ledger cleanup changed")
	print("All shared session earnings checks passed")
end
return Tests
