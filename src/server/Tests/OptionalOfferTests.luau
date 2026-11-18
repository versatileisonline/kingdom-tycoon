--!strict
local Tests = {}
function Tests.Run(Offers: any): ()
	local entries = {
		{ Id = "Dropper", Requires = nil },
		{ Id = "Decor", Requires = "Dropper", Optional = true },
		{ Id = "Sprint", Requires = "Dropper", Optional = true },
		{ Id = "Upgrade", Requires = "Dropper" },
		{ Id = "Mint2", Requires = "Upgrade" },
	}
	local owned = {}
	assert(Offers.IsVisible(entries[1], entries[1], owned, true), "Optional visibility mismatch")
	assert(not Offers.IsVisible(entries[2], entries[1], owned, true), "Optional visibility mismatch")
	owned.Dropper = true
	local nextEntry = Offers.Next(entries, owned)
	assert(nextEntry == entries[4], "Optional offers blocked production")
	assert(Offers.IsVisible(entries[2], nextEntry, owned, true), "Optional visibility mismatch")
	assert(Offers.IsVisible(entries[3], nextEntry, owned, true), "Optional visibility mismatch")
	assert(Offers.IsVisible(entries[4], nextEntry, owned, true), "Optional visibility mismatch")
	assert(not Offers.IsVisible(entries[5], nextEntry, owned, true), "Optional visibility mismatch")
	owned.Sprint = true
	assert(not Offers.IsVisible(entries[3], nextEntry, owned, true), "Optional visibility mismatch")
	owned.Upgrade = true
	assert(Offers.Next(entries, owned) == entries[5], "Optional visibility mismatch")
	assert(Offers.IsVisible(entries[2], entries[5], owned, true), "Skipped optional offer disappeared")
	assert(not Offers.IsVisible(entries[2], entries[5], owned, false), "Optional visibility mismatch")
	print("All optional offer checks passed")
end
return Tests
