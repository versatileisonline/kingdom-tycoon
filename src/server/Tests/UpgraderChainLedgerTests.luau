--!strict
-- Accept real modules so this suite runs both in Studio and the pure Luau harness.
local Tests = {}
function Tests.Run(Mint: any, Purchase: any, Ledger: any): ()
	local expectedPrices = { 250, 300, 400, 600, 1000, 1900, 3800, 7500 }
	local expectedValues = { 768, 384, 192, 96, 48, 24, 12, 6 }
	assert(#Mint.UPGRADERS == 8, "Configure exactly eight Mint upgraders")
	local definitions = {}
	local orderedIds = {}
	for _, definition in Purchase.PURCHASES do
		if definition.UpgraderSite == "RoyalMint" then
			assert(definitions[definition.Id] == nil, "Duplicate Mint upgrader purchase")
			definitions[definition.Id] = definition
			table.insert(orderedIds, definition.Id)
		end
	end
	assert(#orderedIds == 8, "Configure exactly eight Mint upgrader purchases")
	for index = 1, 8 do
		local id = string.format("RoyalMintUpgrader%02d", index)
		local upgrader = Mint.UPGRADERS[index]
		local purchase = definitions[id]
		assert(upgrader.Id == id and orderedIds[index] == id, "Upgraders must remain in physical/purchase order")
		assert(upgrader.Multiplier == 2, "Every arch must double passing coins")
		assert(purchase and purchase.Price == expectedPrices[index], "Unexpected upgrader price")
		local prerequisite = if index == 1
			then "RoyalMintDropper08"
			else string.format("RoyalMintUpgrader%02d", index - 1)
		assert(purchase.Requires == prerequisite and not purchase.StudioOnly, "Incorrect live upgrade prerequisite")
	end
	local ledger = Ledger.new(16, 20, Mint.BUNDLE_VALUE, 9007199254740991)
	local expectedTotal = 0
	for dropper = 1, 8 do
		local token = {}
		assert(ledger.Register(token, 0), "Coin registration failed")
		for index = dropper, 8 do
			local upgrader = Mint.UPGRADERS[index]
			assert(ledger.ApplyUpgrade(token, upgrader.Id, upgrader.Multiplier, 1), "First passage failed")
			assert(not ledger.ApplyUpgrade(token, upgrader.Id, upgrader.Multiplier, 1), "One arch doubled a coin twice")
		end
		assert(ledger.GetValue(token) == expectedValues[dropper], "Incorrect stream-specific final coin value")
		assert(ledger.Remove(token, 2, true), "Upgraded arrival did not credit")
		assert(not ledger.Remove(token, 2, true), "Repeated upgraded arrival credited twice")
		expectedTotal += expectedValues[dropper]
	end
	assert(expectedTotal == 1530 and ledger.GetBalance() == 1530, "Full chain batch must credit exactly 1530 Gold")
	assert(expectedTotal / Mint.PRODUCTION_SECONDS == 510, "Expected theoretical Mint output is 510 Gold/second")
	assert(ledger.GetCount() == 0, "Arrivals retained token capacity")
	local committed = 0
	local success, amount = ledger.Collect(function(value: number): boolean
		committed += value
		return true
	end)
	assert(
		success and amount == 1530 and committed == 1530 and ledger.GetBalance() == 0,
		"Combined upgraded batch collection differs"
	)
	print("All eight-upgrader config and ledger checks passed")
end
return Tests
