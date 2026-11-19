--!strict
local Tests = {}
function Tests.Run(policy: any): ()
	assert(not policy.MayDamage(1, 1, true, false), "Owner must survive")
	assert(policy.MayDamage(1, 2, true, false), "Visitor must die regardless of PvP")
	assert(not policy.MayDamage(1, nil, true, false), "NPC immunity")
	assert(not policy.MayDamage(1, 2, false, false), "Disabled ward")
	assert(not policy.MayDamage(1, 2, true, true), "Spawn shield")
	print("[KingdomTycoon][Stronghold] All protection door policy checks passed")
end
return Tests
