--!strict
local Tests = {}
function Tests.CheckCollectionRow(owned: boolean): ()
	local badge = game.Players.LocalPlayer.PlayerGui.KingdomHUD.GoldBadge
	local row = badge.CurrencyRow
	local collect = row.Collect
	local coin = row.Coin
	local gold = row.Gold
	assert(collect.Visible == owned, "Collect label follows confirmed ownership")
	if owned then
		local pending = game.Players.LocalPlayer:GetAttribute("UncollectedGold")
		assert(
			gold.Text == require(script.Parent.HudState).FormatGold(if typeof(pending) == "number" then pending else 0),
			"collection amount matches plate total"
		)
		local gap = require(game.ReplicatedStorage.Shared.HudConfig).UI.CoinGap
		assert(
			math.abs(coin.AbsolutePosition.X - collect.AbsolutePosition.X - collect.AbsoluteSize.X - gap) < 1,
			"Collect and coin have tight spacing"
		)
		assert(
			math.abs(gold.AbsolutePosition.X - coin.AbsolutePosition.X - coin.AbsoluteSize.X - gap) < 1,
			"coin and amount have tight spacing"
		)
		local center = (collect.AbsolutePosition.X + gold.AbsolutePosition.X + gold.AbsoluteSize.X) / 2
		assert(
			math.abs(center - badge.AbsolutePosition.X - badge.AbsoluteSize.X / 2) < 1,
			"collection row centered in badge"
		)
		assert(
			math.abs(
				coin.AbsolutePosition.Y + coin.AbsoluteSize.Y / 2 - badge.AbsolutePosition.Y - badge.AbsoluteSize.Y / 2
			) < 1,
			"coin vertically centered"
		)
	else
		assert(not badge.Active, "nonowner badge is display only")
	end
end
function Tests.Run(): ()
	local Settings = require(script.Parent.Parent.Controllers.SettingsController)
	local State = require(script.Parent.ShopState)
	local player = game.Players.LocalPlayer
	local gui = player.PlayerGui:WaitForChild("KingdomShopHUD")
	local shade = gui:FindFirstChild("ShopShade") :: TextButton
	local hud = player.PlayerGui:WaitForChild("KingdomHUD")
	local badge = hud:FindFirstChild("GoldBadge")
	assert(badge and badge:IsA("TextButton"), "Gold badge is the collection control")
	assert(not badge.Active and not badge.CurrencyRow.Collect.Visible, "unowned badge remains display only")
	assert(not gui:FindFirstChild("CollectNowButton"), "separate collect button removed")
	local panel = shade:FindFirstChild("ShopPanel") :: Frame
	local banner = panel:FindFirstChild("RoyalBanner") :: ImageLabel
	local title = banner:FindFirstChild("Title") :: TextLabel
	assert(title and title.AnchorPoint == Vector2.new(0.5, 0.5), "title anchored to ribbon")
	local offers = panel:FindFirstChild("Offers") :: ScrollingFrame
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
	assert(not player.PlayerGui.KingdomRebirthHUD.RebirthButton.Visible, "rebirth launcher covers shop")
	local firstCard = offers:FindFirstChild("CollectNow") :: Frame
	local layoutDeadline = os.clock() + 3
	repeat
		game:GetService("RunService").RenderStepped:Wait()
	until (
			firstCard.AbsolutePosition.X - offers.AbsolutePosition.X >= 3
			and firstCard.AbsolutePosition.Y - offers.AbsolutePosition.Y >= 3
		) or os.clock() > layoutDeadline
	for _, key in { "CollectNow", "DoubleGold", "AutoCollect" } do
		local card = offers:FindFirstChild(key) :: Frame
		assert(card:FindFirstChildOfClass("UIStroke"), "offer border exists: " .. key)
		assert(card.AbsolutePosition.X - offers.AbsolutePosition.X >= 3, "offer border clears clipping: " .. key)
		assert(card.AbsolutePosition.Y - offers.AbsolutePosition.Y >= 3, "top border clears clipping: " .. key)
	end

	Settings.Set("MenuOpen", true)
	task.wait()
	assert(not shade.Visible and Settings.Get("ShopOpen") == false, "settings replaces shop")
	Settings.Set("ShopOpen", true)
	task.wait()
	assert(Settings.Get("MenuOpen") == false and shade.Visible, "shop replaces settings")
	Settings.Set("ShopOpen", false)
	assert(player.PlayerGui.KingdomRebirthHUD.RebirthButton.Visible, "rebirth launcher did not return")
	assert(not badge.CurrencyRow.Collect.Visible and not badge.Active, "unowned collection stays disabled")
	Tests.CheckCollectionRow(false)
	print("[KingdomTycoon][ShopTests] All shop client checks passed")
end
return Tests
