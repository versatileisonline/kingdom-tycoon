--!strict
local Tests = {}
function Tests.Run(): ()
	local Settings = require(script.Parent.Parent.Controllers.SettingsController)
	local State = require(script.Parent.ShopState)
	local player = game.Players.LocalPlayer
	local gui = player.PlayerGui:WaitForChild("KingdomShopHUD")
	local shade = gui:FindFirstChild("ShopShade") :: TextButton
	local collect = gui:FindFirstChild("CollectNowButton") :: TextButton
	assert(not collect:FindFirstChildOfClass("UIGradient"), "button text must remain bright")
	local function check(
		status: string,
		price: number?,
		available: boolean,
		expected: string,
		expectedEnabled: boolean
	): ()
		local text, enabled = State.Offer(status, price, available)
		assert(text == expected and enabled == expectedEnabled, "offer state")
	end
	check("Unowned", 49, true, "49 Robux", true)
	check("Owned", 49, true, "Owned", false)
	check("Unowned", nil, false, "Unavailable", false)
	Settings.Set("ShopOpen", true)
	task.wait()
	assert(shade.Visible, "shop opens")
	Settings.Set("MenuOpen", true)
	task.wait()
	assert(not shade.Visible and Settings.Get("ShopOpen") == false, "settings replaces shop")
	Settings.Set("ShopOpen", true)
	task.wait()
	assert(Settings.Get("MenuOpen") == false and shade.Visible, "shop replaces settings")
	Settings.Set("ShopOpen", false)
	assert(not collect.Visible, "unowned collection hidden")
	print("[KingdomTycoon][ShopTests] All shop client checks passed")
end
return Tests
