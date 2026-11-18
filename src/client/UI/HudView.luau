--!strict
local UIS = game:GetService("UserInputService")
local Config = require(game:GetService("ReplicatedStorage").Shared.HudConfig)
local Style = require(script.Parent.RoyalStyle)
local C = Config.COLORS
local View = {}
local function color(hex: string): Color3
	return Color3.fromHex(hex)
end
local function round(item: GuiObject, radius: number): ()
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = item
end
local function stroke(item: GuiObject): ()
	local s = Instance.new("UIStroke")
	s.Color = color(C.Border)
	s.Transparency = 0.25
	s.Thickness = 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = item
end
local function text(parent: Instance, name: string, content: string, size: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Text = content
	l.TextColor3 = color(C.Text)
	l.Font = require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT
	l.TextStrokeColor3, l.TextStrokeTransparency = color(C.Track), 0.65
	l.TextSize = math.max(12, math.floor(size * 0.75) + 2)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end
local function button(parent: Instance, name: string, content: string): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = content
	b.TextSize = 13
	b.Font = require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT
	b.TextStrokeColor3, b.TextStrokeTransparency = color(C.Track), 0.65
	b.TextColor3 = color(C.Text)
	b.BackgroundColor3 = color(C.Raised)
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Parent = parent
	round(b, 12)
	return b
end
function View.new(parent: Instance, settings: any)
	local connections: { RBXScriptConnection } = {}
	local screen = Instance.new("ScreenGui")
	screen.Name = "KingdomHUD"
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 10
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = nil
	local badge = Instance.new("TextButton")
	badge.Text = ""
	badge.Active = false
	badge.Selectable = false
	badge.AutoButtonColor = false
	badge.Name = "GoldBadge"
	badge.AnchorPoint = Vector2.new(0, 1)
	badge.Position = UDim2.new(0, 28, 1, -28)
	badge.Size = UDim2.fromOffset(Config.UI.BadgeWidth, Config.UI.BadgeHeight)
	badge.BackgroundColor3 = color(C.Panel)
	badge.BorderSizePixel = 0
	badge.Parent = screen
	round(badge, 16)
	stroke(badge)
	Style.Gradient(badge, "313039", "141720")
	Style.Corners(badge, 42, 2)
	local currencyRow = Instance.new("Frame")
	currencyRow.Name = "CurrencyRow"
	currencyRow.BackgroundTransparency = 1
	currencyRow.AnchorPoint = Vector2.new(0.5, 0.5)
	currencyRow.Position = UDim2.fromScale(0.5, 0.5)
	currencyRow.Size = UDim2.new(1, -2 * Config.UI.BadgeInset, 0, 28)
	currencyRow.ZIndex = 3
	currencyRow.Parent = badge
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 2 * Config.UI.CoinGap)
	rowLayout.Parent = currencyRow
	local collectLabel = text(currencyRow, "Collect", "Collect", 18)
	collectLabel.Font = require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT
	collectLabel.TextColor3 = color(C.Gold)
	collectLabel.Size = UDim2.fromOffset(0, 28)
	collectLabel.AutomaticSize = Enum.AutomaticSize.X
	collectLabel.LayoutOrder = 1
	collectLabel.ZIndex = 3
	collectLabel.Visible = false
	collectLabel.TextSize = Config.UI.CollectTextSize
	collectLabel.TextStrokeColor3 = collectLabel.TextColor3
	collectLabel.TextStrokeTransparency = Config.UI.LauncherStrokeTransparency
	local coin = Style.Image(currencyRow, "Coin", Config.ART.Coin, 3)
	coin.Size = UDim2.fromOffset(Config.UI.BadgeCoinSize, Config.UI.BadgeCoinSize)
	coin.LayoutOrder = 2
	local gold = text(currencyRow, "Gold", "—", 20)
	gold.Font = require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT
	gold.TextColor3 = color(C.Gold)
	gold.Size = UDim2.fromOffset(0, 28)
	gold.AutomaticSize = Enum.AutomaticSize.X
	gold.TextStrokeColor3 = gold.TextColor3
	gold.TextStrokeTransparency = Config.UI.LauncherStrokeTransparency
	gold.LayoutOrder = 3
	gold.ZIndex = 3
	local open = button(screen, "SettingsButton", "⚙")
	open.TextSize = 22
	open.AnchorPoint = Vector2.new(1, 0)
	open.Position = UDim2.new(1, -20, 0, game:GetService("GuiService"):GetGuiInset().Y + 16)
	open.Size = UDim2.fromOffset(52, 52)
	Style.Corners(open, 30, 2)
	Style.Feedback(open, connections)
	stroke(open)
	local hint = text(screen, "Hint", "", 13)
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -28)
	hint.Size = UDim2.new(0.5, 0, 0, 30)
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.TextStrokeTransparency = 0.5
	local shade = Instance.new("TextButton")
	shade.Name = "SettingsShade"
	shade.Text = ""
	shade.AutoButtonColor = false
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.5
	shade.Size = UDim2.fromScale(1, 1)
	shade.Visible = false
	shade.ZIndex = 10
	shade.Parent = screen
	local panel = Instance.new("Frame")
	panel.Name = "SettingsPanel"
	panel.Active = true
	local panelScale = Instance.new("UIScale")
	panelScale.Parent = panel
	local camera = workspace.CurrentCamera
	local function fit(): ()
		if camera then
			panelScale.Scale = math.min(
				1,
				math.max(
					0.1,
					math.min(
						(camera.ViewportSize.Y - 2 * Config.UI.Margin) / Config.UI.PanelHeight,
						(camera.ViewportSize.X - 2 * Config.UI.Margin) / Config.UI.PanelWidth
					)
				)
			)
		end
	end
	if camera then
		table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))
	end
	fit()
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(Config.UI.PanelWidth, Config.UI.PanelHeight)
	panel.BackgroundColor3 = color(C.Panel)
	panel.BorderSizePixel = 0
	panel.ZIndex = 11
	panel.Parent = shade
	round(panel, 20)
	stroke(panel)
	Style.Gradient(panel, "333039", "141821")
	Style.Corners(panel, Config.UI.OrnamentSize, 14)
	local banner = Style.Image(panel, "RoyalBanner", Config.ART.Banner, 15)
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, -24)
	banner.Size = UDim2.new(1, -64, 0, 108)
	local title = text(panel, "Title", "Settings", 25)
	title.Font = require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT
	title.Position = UDim2.fromOffset(72, 2)
	title.Size = UDim2.new(1, -144, 0, 48)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextStrokeTransparency = 0.6
	title.ZIndex = 16
	local close = button(panel, "Close", "X")
	close.Position = UDim2.new(1, -44, 0, -6)
	close.Size = UDim2.fromOffset(34, 34)
	close.ZIndex = 17
	stroke(close)
	Style.Feedback(close, connections)
	local renderers: { () -> () } = {}
	local function slider(key: string, label: string, y: number): ()
		local caption = text(panel, key .. "Label", label, 15)
		caption.Position = UDim2.fromOffset(40, y)
		caption.Size = UDim2.new(1, -100, 0, 24)
		caption.ZIndex = 12
		local value = text(panel, key .. "Value", "", 13)
		value.Position = UDim2.new(1, -100, 0, y)
		value.Size = UDim2.fromOffset(60, 24)
		value.TextXAlignment = Enum.TextXAlignment.Right
		value.TextColor3 = color(C.Muted)
		value.ZIndex = 12
		local track = button(panel, key .. "Slider", "")
		track.Position = UDim2.fromOffset(40, y + 30)
		track.Size = UDim2.new(1, -80, 0, 22)
		track.BackgroundColor3 = color(C.Track)
		track.ZIndex = 12
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BorderSizePixel = 0
		fill.BackgroundColor3 = color(C.Gold)
		fill.ZIndex = 13
		fill.Parent = track
		round(fill, 10)
		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.Size = UDim2.fromOffset(22, 22)
		knob.AnchorPoint = Vector2.new(0.5, 0)
		knob.BackgroundColor3 = color(C.Gold)
		stroke(knob)
		knob.BorderSizePixel = 0
		knob.ZIndex = 14
		knob.Parent = track
		round(knob, 11)
		local drag: InputObject? = nil
		local function setAt(x: number): ()
			settings.Set(key, (x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X))
		end
		table.insert(
			connections,
			track.InputBegan:Connect(function(input: InputObject): ()
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					drag = input
					setAt(input.Position.X)
				elseif input.KeyCode == Enum.KeyCode.Left then
					settings.Set(key, (settings.Get(key) :: number) - 0.05)
				elseif input.KeyCode == Enum.KeyCode.Right then
					settings.Set(key, (settings.Get(key) :: number) + 0.05)
				end
			end)
		)
		table.insert(
			connections,
			UIS.InputChanged:Connect(function(input: InputObject): ()
				if
					drag
					and (
						input == drag
						or input.UserInputType == Enum.UserInputType.MouseMovement
							and drag.UserInputType == Enum.UserInputType.MouseButton1
					)
				then
					setAt(input.Position.X)
				end
			end)
		)
		table.insert(
			connections,
			UIS.InputEnded:Connect(function(input: InputObject): ()
				if input == drag then
					drag = nil
				end
			end)
		)
		table.insert(
			connections,
			UIS.WindowFocusReleased:Connect(function(): ()
				drag = nil
			end)
		)
		table.insert(renderers, function(): ()
			local v = settings.Get(key) :: number
			value.Text = string.format("%d%%", math.floor(v * 100 + 0.5))
			fill.Size = UDim2.fromScale(v, 1)
			knob.Position = UDim2.fromScale(v, 0)
			if not shade.Visible then
				drag = nil
			end
		end)
	end
	local function toggle(key: string, label: string, y: number): ()
		local caption = text(panel, key .. "Label", label, 15)
		caption.Position = UDim2.fromOffset(40, y)
		caption.Size = UDim2.new(1, -130, 0, 40)
		caption.ZIndex = 12
		local b = button(panel, key .. "Toggle", "")
		b.Position = UDim2.new(1, -112, 0, y)
		b.Size = UDim2.fromOffset(72, 36)
		b.ZIndex = 12
		stroke(b)
		Style.Feedback(b, connections)
		table.insert(
			connections,
			b.Activated:Connect(function(): ()
				settings.Set(key, not settings.Get(key))
			end)
		)
		table.insert(renderers, function(): ()
			local on = settings.Get(key) == true
			b.Text = if on then "On" else "Off"
			b.TextColor3 = if on then color(C.Gold) else color(C.Muted)
		end)
	end
	slider("Music", "Music", 112)
	slider("WorldSounds", "World sounds", 188)
	toggle("HelperArrow", "Helper arrow", 276)
	toggle("LowGraphics", "Low graphics", 330)
	local subtitle = text(panel, "Subtitle", "MAKE YOURSELF AT HOME", 11)
	subtitle.TextColor3 = color(C.Muted)
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.Position = UDim2.fromOffset(40, 76)
	subtitle.Size = UDim2.new(1, -80, 0, 20)
	subtitle.ZIndex = 12
	local footnote = text(panel, "Footnote", "Preferences apply to this session", 11)
	footnote.TextColor3 = color(C.Muted)
	footnote.TextXAlignment = Enum.TextXAlignment.Center
	footnote.Position = UDim2.fromOffset(40, 394)
	footnote.Size = UDim2.new(1, -80, 0, 20)
	footnote.ZIndex = 12
	local function refresh(): ()
		badge.Visible = settings.Get("MainMenuOpen") ~= true
		open.Visible = settings.Get("MainMenuOpen") ~= true
		hint.Visible = settings.Get("MainMenuOpen") ~= true
		shade.Visible = settings.Get("MenuOpen") == true
		for _, render in renderers do
			render()
		end
	end
	table.insert(connections, settings.Observe(refresh))
	table.insert(
		connections,
		open.Activated:Connect(function(): ()
			settings.Set("MenuOpen", not settings.Get("MenuOpen"))
		end)
	)
	table.insert(
		connections,
		close.Activated:Connect(function(): ()
			settings.Set("MenuOpen", false)
		end)
	)
	table.insert(
		connections,
		shade.Activated:Connect(function(): ()
			settings.Set("MenuOpen", false)
		end)
	)
	table.insert(
		connections,
		UIS.InputBegan:Connect(function(input: InputObject): ()
			if input.KeyCode == Enum.KeyCode.Escape and settings.Get("MenuOpen") == true then
				settings.Set("MenuOpen", false)
			end
		end)
	)
	table.insert(
		connections,
		screen.Destroying:Connect(function(): ()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
		end)
	)
	refresh()
	screen.Parent = parent
	return {
		Screen = screen,
		Gold = gold,
		Hint = hint,
		GoldButton = badge,
		CollectLabel = collectLabel,
		Coin = coin,
		RowLayout = rowLayout,
	}
end
return View
