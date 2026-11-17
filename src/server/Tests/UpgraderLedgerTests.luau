--!strict
local Ledger = require(script.Parent.Parent.Farms.FarmLedger)
local Tests = {}
function Tests.Run(): ()
	local ledger = Ledger.new(32, 20, 3, 100)
	assert(ledger.Register("coin", 0), "Register failed")
	assert(ledger.ApplyUpgrade("coin", "first", 2, 1), "First crossing did not upgrade")
	assert(not ledger.ApplyUpgrade("coin", "first", 2, 2), "Repeated crossing doubled twice")
	assert(ledger.GetValue("coin") == 6, "Wrong private value")
	assert(
		ledger.ApplyUpgrade("coin", "second", 2, 3) and ledger.GetValue("coin") == 12,
		"Distinct upgrades did not compose"
	)
	assert(not ledger.ApplyUpgrade("missing", "first", 2, 1), "Unknown coin upgraded")
	assert(not ledger.ApplyUpgrade("coin", "bad", 0 / 0, 1), "NaN multiplier accepted")
	assert(not ledger.ApplyUpgrade("coin", "bad", -2, 1), "Negative multiplier accepted")
	assert(not ledger.ApplyUpgrade("coin", "huge", 100, 1), "Overflow multiplier accepted")
	assert(ledger.Remove("coin", 4, true) and ledger.GetBalance() == 12, "Collector ignored upgraded value")
	assert(not ledger.Remove("coin", 4, true), "Duplicate arrival credited")
	assert(ledger.Register("expired", 0), "Expiry fixture failed")
	assert(not ledger.ApplyUpgrade("expired", "first", 2, 20), "Expired coin upgraded")
	assert(not ledger.Remove("expired", 20, true), "Expired coin credited")
	assert(
		ledger.Register("normal", 0) and ledger.Remove("normal", 1, true) and ledger.GetBalance() == 15,
		"Unupgraded coin value changed"
	)
	ledger.Clear()
	assert(
		ledger.GetCount() == 0 and ledger.GetValue("coin") == nil and ledger.GetBalance() == 0,
		"Cleanup retained token values"
	)
	print("All upgrader ledger checks passed")
end
return Tests
