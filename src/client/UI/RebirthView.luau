--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.RebirthConfig)
local Hud = require(Shared.HudConfig)
local Style = require(script.Parent.RoyalStyle)
local View = {}
local C = Hud.COLORS
local function copy(key: string, fallback: string): string
	return Config.COPY[key] or fallback
end
local function text(parent: Instance, name: string, value: string, size: number, z: number): TextLabel
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Text = value
	item.TextColor3 = Color3.fromHex(C.Text)
	item.Font = require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT
	item.TextSize = math.max(10, math.floor(size * 0.75))
	item.BackgroundTransparency = 1
	item.ZIndex = z
	item.Parent = parent
	return item
end
local function surface(item: GuiObject, button: boolean): ()
	item.BorderSizePixel = 0
	item.BackgroundColor3 = if button then Color3.fromHex(C.Raised) else Color3.new(1, 1, 1)
	if not button then
		Style.Gradient(item, "333039", "141821")
	end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = item
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromHex(C.Border)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = item
end
local function button(
	parent: Instance,
	name: string,
	value: string,
	z: number,
	connections: { RBXScriptConnection }
): TextButton
	local item = Instance.new("TextButton")
	item.Name = name
	item.Text = value
	item.TextColor3 = Color3.fromHex(C.Text)
	item.Font = require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT
	item.TextSize = 13
	item.ZIndex = z
	item.Parent = parent
	surface(item, true)
	Style.Feedback(item, connections)
	return item
end
local function art(parent: Instance, name: string, index: number, z: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = true
	frame.ZIndex = z
	frame.Parent = parent
	local image = Style.Image(frame, "Art", Config.ART_ATLAS, z)
	image.Size = UDim2.fromScale(2, 2)
	image.Position = UDim2.fromScale(-(index % 2), -math.floor(index / 2))
	image.ScaleType = Enum.ScaleType.Stretch
	return frame
end
function View.new(parent: Instance, settings: any)
	local connections: { RBXScriptConnection } = {}
	local screen = Instance.new("ScreenGui")
	screen.Name = "KingdomRebirthHUD"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 20
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = parent
	local open = button(screen, "RebirthButton", "     " .. copy("Title", "Rebirth"), 2, connections)
	open.Size = UDim2.fromOffset(132, 48)
	local launcher = art(open, "RebirthIcon", 3, 3)
	launcher.Size = UDim2.fromOffset(42, 42)
	launcher.Position = UDim2.fromOffset(6, 3)
	local shade = Instance.new("TextButton")
	shade.Name = "RebirthShade"
	shade.Text = ""
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.4
	shade.AutoButtonColor = false
	shade.Visible = false
	shade.ZIndex = 10
	shade.Parent = screen
	local panel = Instance.new("Frame")
	panel.Name = "RebirthPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Active = true
	panel.ZIndex = 11
	panel.Parent = shade
	surface(panel, false)
	local panelScale = Instance.new("UIScale")
	panelScale.Parent = panel
	Style.Corners(panel, 42, 12)
	local banner = Style.Image(panel, "RoyalBanner", Hud.ART.Banner, 15)
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, -20)
	banner.Size = UDim2.new(1, -76, 0, 100)
	local title = text(banner, "Title", copy("Title", "Rebirth"), 28, 16)
	title.Font = require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.42)
	title.Size = UDim2.new(0.78, 0, 0, 40)
	local close = button(panel, "Close", "X", 17, connections)
	close.Position = UDim2.new(1, -50, 0, 12)
	close.Size = UDim2.fromOffset(36, 36)
	local subtitle = text(panel, "Subtitle", copy("Subtitle", "Start fresh. Build faster."), 16, 13)
	subtitle.Position = UDim2.fromOffset(20, 78)
	subtitle.Size = UDim2.new(1, -40, 0, 24)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Cards"
	scroll.Position = UDim2.fromOffset(20, 112)
	scroll.Size = UDim2.new(1, -40, 1, -278)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ZIndex = 12
	scroll.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 4)
	padding.Parent = scroll
	local layout = Instance.new("UIGridLayout")
	layout.CellPadding = UDim2.fromOffset(14, 14)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll
	local reward: TextLabel? = nil
	local count: TextLabel? = nil
	for index, key in { "Reward", "Resets", "Keep" } do
		local card = Instance.new("Frame")
		card.Name = key
		card.LayoutOrder = index
		card.ZIndex = 13
		card.Parent = scroll
		surface(card, false)
		local heading =
			text(card, "Heading", copy(key .. "Title", ({ "Your reward", "Resets", "You keep" })[index]), 22, 14)
		heading.Font = require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT
		heading.Position = UDim2.fromOffset(8, 12)
		heading.Size = UDim2.new(1, -16, 0, 32)
		local picture = art(card, "Illustration", index - 1, 14)
		picture.AnchorPoint = Vector2.new(0.5, 0)
		picture.Position = UDim2.new(0.5, 0, 0, 46)
		picture.Size = UDim2.fromOffset(142, 142)
		if key == "Reward" then
			local multiplierLabel = text(card, "Multiplier", "1× → 1.5×", 27, 14)
			multiplierLabel.TextColor3 = Color3.fromHex(C.Gold)
			multiplierLabel.Position = UDim2.fromOffset(8, 190)
			multiplierLabel.Size = UDim2.new(1, -16, 0, 38)
			local description =
				text(card, "Description", copy("RewardDescription", "Permanent Gold multiplier"), 13, 14)
			description.Position = UDim2.fromOffset(8, 232)
			description.Size = UDim2.new(1, -16, 0, 32)
			description.TextWrapped = true
			reward = multiplierLabel
			local countLabel = text(card, "Count", "Rebirth 0 → 1", 14, 14)
			countLabel.TextColor3 = Color3.fromHex(C.Muted)
			countLabel.Position = UDim2.fromOffset(8, 274)
			countLabel.Size = UDim2.new(1, -16, 0, 26)
			count = countLabel
		else
			local body = text(
				card,
				"Description",
				if key == "Resets"
					then copy("ResetsDescription", "All Gold\nPurchased buildings\nUncollected earnings")
					else copy("KeepDescription", "Permanent passes\nRebirth bonuses\nYour plot"),
				15,
				14
			)
			body.Position = UDim2.fromOffset(12, 194)
			body.Size = UDim2.new(1, -24, 0, 110)
			body.TextWrapped = true
			body.LineHeight = 1.5
		end
	end
	local progress = Instance.new("Frame")
	progress.Name = "Progress"
	progress.BackgroundColor3 = Color3.fromHex(C.Track)
	progress.Position = UDim2.new(0, 28, 1, -155)
	progress.Size = UDim2.new(1, -56, 0, 30)
	progress.ClipsDescendants = true
	progress.ZIndex = 13
	progress.Parent = panel
	local rounding = Instance.new("UICorner")
	rounding.CornerRadius = UDim.new(0, 12)
	rounding.Parent = progress
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.fromHex(C.Gold)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.ZIndex = 14
	fill.Parent = progress
	local fillRounding = rounding:Clone()
	fillRounding.Parent = fill
	local amount = text(progress, "Amount", "Loading…", 16, 15)
	amount.TextStrokeTransparency = 0.4
	amount.Size = UDim2.fromScale(1, 1)
	local status = text(panel, "Status", "", 13, 13)
	status.Position = UDim2.new(0, 20, 1, -121)
	status.Size = UDim2.new(1, -40, 0, 20)
	status.TextColor3 = Color3.fromHex(C.Muted)
	local warning = text(panel, "Warning", copy("Warning", "Your kingdom will reset."), 16, 13)
	warning.Position = UDim2.new(0, 20, 1, -97)
	warning.Size = UDim2.new(1, -40, 0, 24)
	warning.TextColor3 = Color3.fromHex(C.Gold)
	local cancel = button(panel, "Cancel", copy("Cancel", "Cancel"), 13, connections)
	cancel.AnchorPoint = Vector2.new(1, 1)
	cancel.Position = UDim2.new(0.5, -8, 1, -18)
	cancel.Size = UDim2.new(0.35, 0, 0, 44)
	local confirm = button(panel, "Confirm", copy("Confirm", "Rebirth"), 13, connections)
	confirm.AnchorPoint = Vector2.new(0, 1)
	confirm.Position = UDim2.new(0.5, 8, 1, -18)
	confirm.Size = UDim2.new(0.35, 0, 0, 44)
	local message = text(screen, "RebirthMessage", "", 14, 30)
	message.AnchorPoint = Vector2.new(0.5, 1)
	message.Position = UDim2.new(0.5, 0, 1, -12)
	message.Size = UDim2.new(0.8, 0, 0, 32)
	message.TextStrokeTransparency = 0.3
	message.TextWrapped = true
	local function fit(): ()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local viewport = camera.ViewportSize
		local narrow = viewport.X < 740
		local scale = math.min(1, math.max(1, viewport.Y - 48) / 440)
		panelScale.Scale = scale
		local width = math.min(Config.UI.PanelWidth, (viewport.X - 32) / scale)
		local height = math.min(Config.UI.PanelHeight, math.max(440, (viewport.Y - 48) / scale))
		panel.Size = UDim2.fromOffset(width, height)
		local cardWidth = if narrow then width - 48 else math.floor((width - 76) / 3)
		layout.FillDirectionMaxCells = if narrow then 1 else 3
		layout.CellSize = UDim2.fromOffset(cardWidth, 316)
		scroll.CanvasSize = UDim2.fromOffset(0, if narrow then 3 * 316 + 2 * 14 + 8 else 324)
		open.Position = UDim2.new(0, if narrow then 12 else 28, 0.30, 58)
	end
	local cameraConnection: RBXScriptConnection? = nil
	local function cameraChanged(): ()
		if cameraConnection then
			cameraConnection:Disconnect()
		end
		local camera = workspace.CurrentCamera
		if camera then
			cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
		end
		fit()
	end
	table.insert(connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged))
	cameraChanged()
	local function hide(): ()
		settings.Set("RebirthOpen", false)
	end
	for _, item in { close, cancel, shade } do
		table.insert(connections, item.Activated:Connect(hide))
	end
	table.insert(
		connections,
		open.Activated:Connect(function()
			settings.Set("RebirthOpen", settings.Get("RebirthOpen") ~= true)
		end)
	)
	table.insert(
		connections,
		settings.Observe(function()
			shade.Visible = settings.Get("RebirthOpen") == true
		end)
	)
	table.insert(
		connections,
		game:GetService("UserInputService").InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Escape and settings.Get("RebirthOpen") == true then
				hide()
			end
		end)
	)
	table.insert(
		connections,
		screen.Destroying:Connect(function()
			if cameraConnection then
				cameraConnection:Disconnect()
			end
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
		end)
	)
	return {
		Screen = screen,
		Open = open,
		Shade = shade,
		Panel = panel,
		Confirm = confirm,
		Reward = reward,
		Count = count,
		Fill = fill,
		Amount = amount,
		Status = status,
		Message = message,
	}
end
return View
