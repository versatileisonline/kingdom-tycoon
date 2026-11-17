--!strict
local Tests = {}
function Tests.Run(mint: any, purchases: any): ()
	local sites = mint.SITES
	assert(sites and sites.RoyalMint02, "Second Mint site missing")
	assert(sites.RoyalMint02.MAX_BUNDLES == 32, "Second lane needs independent cap")
	local prices = {
		12000,
		12200,
		12400,
		12600,
		12800,
		13000,
		13200,
		13400,
		13600,
		13800,
		14000,
		14200,
		14500,
		15000,
		16500,
		19500,
	}
	assert(sites.RoyalMint02.BUNDLE_VALUE == 9, "Second lane coins must be triple value")
	local previous = "RoyalMintUpgrader08"
	for index, price in prices do
		local id = if index == 1
			then "RoyalMint02"
			elseif index <= 8 then string.format("RoyalMint02Dropper%02d", index)
			else string.format("RoyalMint02Upgrader%02d", index - 8)
		local found = nil
		for _, definition in purchases.PURCHASES do
			if definition.Id == id then
				found = definition
			end
		end
		assert(
			found and found.Price == price and found.Requires == previous,
			"Second-lane price/prerequisite mismatch: " .. id
		)
		assert((if index <= 8 then found.ProductionSite else found.UpgraderSite) == "RoyalMint02", "Wrong site routing")
		if index <= 8 then
			assert(sites.RoyalMint02.PRODUCERS[index].PurchaseId == id, "Wrong producer purchase")
		else
			assert(sites.RoyalMint02.UPGRADERS[index - 8].Id == id, "Wrong upgrader purchase")
		end
		previous = id
	end
	assert(
		sites.RoyalMint.PRODUCERS == mint.PRODUCERS and sites.RoyalMint.BUNDLE_VALUE == 3,
		"First Mint compatibility changed"
	)
	print("All second Mint configuration checks passed")
end
return Tests
