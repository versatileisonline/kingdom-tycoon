--!strict
local Tests = {}
function Tests.CheckLayout(): ()
	local player = game.Players.LocalPlayer
	local gui = player.PlayerGui:FindFirstChild("KingdomRebirthHUD")
	assert(gui ~= nil, "rebirth HUD exists")
	local shade = gui:FindFirstChild("RebirthShade") :: TextButton
	local panel = shade:FindFirstChild("RebirthPanel") :: Frame
	local cards = panel:FindFirstChild("Cards") :: ScrollingFrame
	local layout = cards:FindFirstChildOfClass("UIGridLayout")
	local confirm = panel:FindFirstChild("Confirm") :: TextButton
	local progress = panel:FindFirstChild("Progress") :: Frame
	local camera = workspace.CurrentCamera
	assert(camera ~= nil and layout ~= nil, "viewport and grid available")
	local viewport = camera.ViewportSize
	assert(layout.FillDirectionMaxCells == (if viewport.X < 740 then 1 else 3), "narrow screens stack cards")
	assert(cards.AbsoluteSize.Y > 80, "cards remain scrollable on short screens")
	assert(panel.AbsolutePosition.X >= 0 and panel.AbsolutePosition.Y >= 0, "panel clears viewport origin")
	assert(panel.AbsolutePosition.X + panel.AbsoluteSize.X <= viewport.X, "panel fits viewport width")
	assert(panel.AbsolutePosition.Y + panel.AbsoluteSize.Y <= viewport.Y, "panel fits viewport height")
	assert(
		confirm.AbsolutePosition.Y >= progress.AbsolutePosition.Y + progress.AbsoluteSize.Y,
		"confirmation clears progress"
	)
	assert(
		confirm.AbsolutePosition.Y + confirm.AbsoluteSize.Y <= panel.AbsolutePosition.Y + panel.AbsoluteSize.Y,
		"confirmation fits panel"
	)
	if viewport.X < 740 then
		assert(cards.AbsoluteCanvasSize.Y > cards.AbsoluteSize.Y, "stacked cards can scroll")
	end
end
function Tests.Run(): ()
	local State = require(script.Parent.RebirthState)
	local Config = require(game.ReplicatedStorage.Shared.RebirthConfig)
	local Settings = require(script.Parent.Parent.Controllers.SettingsController)
	local request = State.Requests()
	local first = request.Begin(0)
	assert(first ~= nil and request.Begin(0) == nil, "duplicate submissions are blocked")
	assert(not request.Resolve(first + 1, 0), "unrelated response cannot settle pending request")
	assert(request.Resolve(first, 0), "matching reply settles request")
	local second = request.Begin(0)
	assert(second ~= nil and second ~= first, "retry has distinct identity")
	assert(not request.Resolve(first, 0), "late reply cannot settle retry")
	assert(request.Resolve(second, 0), "retry resolves independently")
	local below = State.Presentation(true, 99999, 0, false, true, true, false)
	assert(not below.Enabled and below.Progress < 1, "banked Gold threshold enforced")
	local ready = State.Presentation(true, 100000, 0, false, true, true, false)
	assert(ready.Enabled and ready.Progress == 1, "exact threshold enables confirmation")
	assert(ready.CurrentMultiplier == 1 and ready.NextMultiplier == 1.5, "first rebirth reward")
	local passed = State.Presentation(true, 100000, 0, true, true, true, false)
	assert(passed.CurrentMultiplier == 2 and passed.NextMultiplier == 3, "Gold pass stacks multiplicatively")
	assert(not State.Presentation(false, 100000, 0, false, true, true, false).Enabled, "loading blocks request")
	assert(not State.Presentation(true, 100000, 0, false, false, true, false).Enabled, "dead character blocks request")
	assert(not State.Presentation(true, 100000, 0, false, true, false, false).Enabled, "missing kingdom blocks request")
	assert(not State.Presentation(true, 100000, 0, false, true, true, true).Enabled, "busy blocks request")
	assert(Config.Target(1) == 200000, "next requirement doubles")
	for _, key in { "MenuOpen", "ShopOpen", "RebirthOpen" } do
		Settings.Set(key, true)
		for _, other in { "MenuOpen", "ShopOpen", "RebirthOpen" } do
			assert(Settings.Get(other) == (key == other), "only one menu may remain open")
		end
	end
	local gui = game.Players.LocalPlayer.PlayerGui:WaitForChild("KingdomRebirthHUD", 10)
	assert(gui ~= nil, "rebirth HUD constructed")
	local shade = gui:FindFirstChild("RebirthShade") :: TextButton
	assert(shade.Visible, "rebirth opens")
	local panel = shade:FindFirstChild("RebirthPanel") :: Frame
	local banner = panel:FindFirstChild("RoyalBanner") :: ImageLabel
	local title = banner:FindFirstChild("Title") :: TextLabel
	assert(title.Text == "Rebirth", "title uses royal banner")
	local cards = panel:FindFirstChild("Cards") :: ScrollingFrame
	for _, key in { "Reward", "Resets", "Keep" } do
		assert(cards:FindFirstChild(key), "all three explanatory cards exist")
	end
	game:GetService("RunService").RenderStepped:Wait()
	Tests.CheckLayout()
	Settings.Set("RebirthOpen", false)
	task.wait()
	assert(not shade.Visible, "rebirth closes")
	print("[KingdomTycoon][RebirthTests] All rebirth client checks passed")
end
return Tests
