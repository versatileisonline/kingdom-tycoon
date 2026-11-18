--!strict
local Tests = {}
function Tests.Run(owner: Player): ()
	local Server = script.Parent.Parent
	local Entitlements = require(Server.Services.EntitlementService)
	assert(Entitlements.IsPreview(), "Studio Mock preview required")
	local previous = Server:GetAttribute("StudioShopPreview")
	local ok, reason = xpcall(function()
		Entitlements.SetPreview(owner, "DoubleGold", true)
		Server:SetAttribute("StudioShopPreview", false)
		assert(not Entitlements.Owns(owner, "DoubleGold"), "disabling preview immediately rejects cached grants")
		task.wait()
		assert(owner:GetAttribute("ShopPreview") == false, "preview presentation disabled")
		Server:SetAttribute("StudioShopPreview", true)
		task.wait()
		assert(not Entitlements.Owns(owner, "DoubleGold"), "re-enabled preview starts unowned")
	end, debug.traceback)
	Server:SetAttribute("StudioShopPreview", previous)
	task.wait()
	assert(ok, reason)
	print("[KingdomTycoon][ShopTests] All preview mode lifecycle checks passed")
end
return Tests
