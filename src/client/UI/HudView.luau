--!strict
local UIS = game:GetService("UserInputService")
local Config = require(game:GetService("ReplicatedStorage").Shared.HudConfig)
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
	s.Thickness = 1
	s.Parent = item
end
local function text(parent: Instance, name: string, content: string, size: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Text = content
	l.TextColor3 = color(C.Text)
	l.Font = Enum.Font.GothamMedium
	l.TextSize = size
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end
local function button(parent: Instance, name: string, content: string): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = content
	b.TextSize = 15
	b.Font = Enum.Font.GothamBold
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
	screen.Parent = parent
	local badge = Instance.new("Frame")
	badge.Name = "GoldBadge"
	badge.AnchorPoint = Vector2.new(0, 1)
	badge.Position = UDim2.new(0, 20, 1, -20)
	badge.Size = UDim2.fromOffset(190, 52)
	badge.BackgroundColor3 = color(C.Panel)
	badge.BorderSizePixel = 0
	badge.Parent = screen
	round(badge, 16)
	stroke(badge)
	local coin = text(badge, "Coin", "●", 32)
	coin.Position = UDim2.fromOffset(15, 0)
	coin.Size = UDim2.fromOffset(38, 52)
	coin.TextColor3 = color(C.Gold)
	local gold = text(badge, "Gold", "—", 20)
	gold.Font = Enum.Font.GothamBold
	gold.TextColor3 = color(C.Gold)
	gold.Position = UDim2.fromOffset(56, 0)
	gold.Size = UDim2.new(1, -66, 1, 0)
	local open = button(screen, "SettingsButton", "⚙")
	open.AnchorPoint = Vector2.new(1, 0)
	open.Position = UDim2.new(1, -20, 0, game:GetService("GuiService"):GetGuiInset().Y + 16)
	open.Size = UDim2.fromOffset(48, 48)
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
			panelScale.Scale = math.min(1, math.max(0.1, (camera.ViewportSize.Y - 32) / 354))
		end
	end
	if camera then
		table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))
	end
	fit()
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -32, 0, 354)
	panel.BackgroundColor3 = color(C.Panel)
	panel.BorderSizePixel = 0
	panel.ZIndex = 11
	panel.Parent = shade
	round(panel, 20)
	stroke(panel)
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(420, 354)
	constraint.Parent = panel
	local title = text(panel, "Title", "Settings", 25)
	title.Font = Enum.Font.GothamBold
	title.Position = UDim2.fromOffset(24, 18)
	title.Size = UDim2.new(1, -100, 0, 38)
	title.ZIndex = 12
	local close = button(panel, "Close", "×")
	close.Position = UDim2.new(1, -58, 0, 18)
	close.Size = UDim2.fromOffset(34, 34)
	close.ZIndex = 12
	local renderers: { () -> () } = {}
	local function slider(key: string, label: string, y: number): ()
		local caption = text(panel, key .. "Label", label, 15)
		caption.Position = UDim2.fromOffset(24, y)
		caption.Size = UDim2.new(1, -100, 0, 24)
		caption.ZIndex = 12
		local value = text(panel, key .. "Value", "", 13)
		value.Position = UDim2.new(1, -84, 0, y)
		value.Size = UDim2.fromOffset(60, 24)
		value.TextXAlignment = Enum.TextXAlignment.Right
		value.TextColor3 = color(C.Muted)
		value.ZIndex = 12
		local track = button(panel, key .. "Slider", "")
		track.Position = UDim2.fromOffset(24, y + 30)
		track.Size = UDim2.new(1, -48, 0, 22)
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
		knob.BackgroundColor3 = color(C.Text)
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
		caption.Position = UDim2.fromOffset(24, y)
		caption.Size = UDim2.new(1, -130, 0, 40)
		caption.ZIndex = 12
		local b = button(panel, key .. "Toggle", "")
		b.Position = UDim2.new(1, -96, 0, y)
		b.Size = UDim2.fromOffset(72, 36)
		b.ZIndex = 12
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
	slider("Music", "Music", 78)
	slider("WorldSounds", "World sounds", 150)
	toggle("HelperArrow", "Helper arrow", 224)
	toggle("LowGraphics", "Low graphics", 278)
	local function refresh(): ()
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
	return { Screen = screen, Gold = gold, Hint = hint }
end
return View
