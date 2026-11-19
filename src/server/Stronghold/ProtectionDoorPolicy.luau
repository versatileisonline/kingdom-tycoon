--!strict
local Policy = {}
function Policy.MayDamage(ownerId: number, visitorId: number?, enabled: boolean, protected: boolean): boolean
	return enabled and visitorId ~= nil and visitorId ~= ownerId and not protected
end
return Policy
