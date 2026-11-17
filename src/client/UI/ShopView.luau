--!strict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.HudConfig)
local Shop = require(Shared.ShopConfig)
local Style = require(script.Parent.RoyalStyle)
local View = {}
local C = Config.COLORS
local function label(parent: Instance, name: string, text: string, size: number, z: number): TextLabel
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Text = text
	item.TextSize = size
	item.Font = Enum.Font.GothamBold
	item.BackgroundTransparency = 1
	item.TextColor3 = Color3.fromHex(C.Text)
	item.ZIndex = z
	item.Parent = parent
	return item
end
local function surface(item: GuiObject, corners: boolean, z: number): ()
	item.BackgroundColor3 = Color3.fromHex(C.Panel)
	item.BorderSizePixel = 0
	local rounding = Instance.new("UICorner")
	rounding.CornerRadius = UDim.new(0, 14)
	rounding.Parent = item
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromHex(C.Border)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = item
	if item:IsA("TextButton") then
		item.BackgroundColor3 = Color3.fromHex(C.Raised)
	else
		item.BackgroundColor3 = Color3.new(1, 1, 1)
		Style.Gradient(item, "333039", "141821")
	end
	if corners then
		Style.Corners(item, 42, z)
	end
end
local function button(
	parent: Instance,
	name: string,
	text: string,
	z: number,
	connections: { RBXScriptConnection }
): TextButton
	local item = Instance.new("TextButton")
	item.Name = name
	item.Text = text
	item.Font = Enum.Font.GothamBold
	item.TextSize = 17
	item.TextColor3 = Color3.fromHex(C.Text)
	item.ZIndex = z
	item.Parent = parent
	surface(item, false, z)
	Style.Feedback(item, connections)
	return item
end
local function illustration(parent: Instance, name: string, index: number, z: number): Frame
	local clip = Instance.new("Frame")
	clip.Name = name
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.ZIndex = z
	clip.Parent = parent
	local art = Instance.new("ImageLabel")
	art.Name = "Art"
	art.BackgroundTransparency = 1
	art.Image = Shop.ART_ATLAS
	art.Size = UDim2.fromScale(2, 2)
	art.Position = UDim2.fromScale(-(index % 2), -math.floor(index / 2))
	art.ZIndex = z
	art.Parent = clip
	return clip
end
function View.new(parent: Instance, settings: any)
	local connections: { RBXScriptConnection } = {}
	local screen = Instance.new("ScreenGui")
	screen.Name = "KingdomShopHUD"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 20
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = parent
	local open = button(screen, "ShopButton", "     Shop", 2, connections)
	open.Position = UDim2.new(0, 28, 0.38, 0)
	open.Size = UDim2.fromOffset(132, 48)
	local shopIcon = illustration(open, "ShopIcon", 0, 3)
	shopIcon.Position = UDim2.fromOffset(6, 3)
	shopIcon.Size = UDim2.fromOffset(42, 42)
	local collect = button(screen, "CollectNowButton", "Collect Now\n—", 2, connections)
	collect.AnchorPoint = Vector2.new(0, 1)
	collect.Position = UDim2.new(0, 28, 1, -94)
	collect.Size = UDim2.fromOffset(220, 68)
	collect.Visible = false
	collect.TextSize = 17
	local autoStatus = label(screen, "AutoCollectStatus", "Auto-Collect active", 13, 2)
	autoStatus.AnchorPoint = Vector2.new(0, 1)
	autoStatus.Position = UDim2.new(0, 28, 1, -100)
	autoStatus.Size = UDim2.fromOffset(220, 24)
	autoStatus.Visible = false
	autoStatus.TextColor3 = Color3.fromHex(C.Gold)
	local shade = Instance.new("TextButton")
	shade.Name = "ShopShade"
	shade.Text = ""
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.4
	shade.Size = UDim2.fromScale(1, 1)
	shade.Visible = false
	shade.AutoButtonColor = false
	shade.ZIndex = 10
	shade.Parent = screen
	local panel = Instance.new("Frame")
	panel.Name = "ShopPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Active = true
	panel.ZIndex = 11
	panel.Parent = shade
	surface(panel, true, 12)
	local banner = Style.Image(panel, "RoyalBanner", Config.ART.Banner, 15)
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, -20)
	banner.Size = UDim2.new(1, -76, 0, 100)
	local title = label(panel, "Title", "Royal Shop", 28, 16)
	title.Font = Enum.Font.Fondamento
	title.Position = UDim2.fromOffset(52, 8)
	title.Size = UDim2.new(1, -104, 0, 46)
	local close = button(panel, "Close", "×", 17, connections)
	close.Position = UDim2.new(1, -50, 0, 12)
	close.Size = UDim2.fromOffset(36, 36)
	local subtitle = label(panel, "Subtitle", "Permanent passes • Yours to keep", 14, 13)
	subtitle.Position = UDim2.fromOffset(20, 78)
	subtitle.Size = UDim2.new(1, -40, 0, 24)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Offers"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(20, 116)
	scroll.Size = UDim2.new(1, -40, 1, -190)
	scroll.ScrollBarThickness = 4
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ZIndex = 12
	scroll.Parent = panel
	local layout = Instance.new("UIGridLayout")
	layout.CellPadding = UDim2.fromOffset(14, 14)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll
	local cards: { [string]: TextButton } = {}
	for index, offer in Shop.OFFERS do
		local card = Instance.new("Frame")
		card.Name = offer.Key
		card.LayoutOrder = index
		card.ZIndex = 13
		card.Parent = scroll
		surface(card, false, 13)
		local heading = label(card, "Name", offer.Name, 22, 14)
		heading.Font = Enum.Font.Fondamento
		heading.Position = UDim2.fromOffset(8, 14)
		heading.Size = UDim2.new(1, -16, 0, 32)
		local icon = illustration(card, "Illustration", index, 14)
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0, 48)
		icon.Size = UDim2.fromOffset(146, 146)
		local description = label(card, "Description", offer.Description, 14, 14)
		description.Font = Enum.Font.GothamMedium
		description.TextWrapped = true
		description.Position = UDim2.fromOffset(14, 199)
		description.Size = UDim2.new(1, -28, 0, 68)
		local buy = button(card, "Buy", "Loading…", 14, connections)
		buy.Position = UDim2.new(0, 14, 1, -60)
		buy.Size = UDim2.new(1, -28, 0, 44)
		cards[offer.Key] = buy
	end
	local footer = label(panel, "Footer", "One-time purchase. Permanent benefit.", 12, 13)
	footer.Position = UDim2.new(0, 20, 1, -64)
	footer.Size = UDim2.new(1, -40, 0, 20)
	local retry = button(panel, "Retry", "Refresh", 13, connections)
	retry.AnchorPoint = Vector2.new(1, 1)
	retry.Position = UDim2.new(1, -20, 1, -12)
	retry.Size = UDim2.fromOffset(88, 28)
	retry.TextSize = 12
	local previewReset = button(panel, "PreviewReset", "Reset preview", 13, connections)
	previewReset.AnchorPoint = Vector2.new(0, 1)
	previewReset.Position = UDim2.new(0, 20, 1, -12)
	previewReset.Size = UDim2.fromOffset(120, 28)
	previewReset.TextSize = 12
	previewReset.Visible = false
	local message = label(screen, "ShopMessage", "", 13, 30)
	message.AnchorPoint = Vector2.new(0.5, 1)
	message.Position = UDim2.new(0.5, 0, 1, -12)
	message.Size = UDim2.new(0.7, 0, 0, 30)
	message.TextStrokeTransparency = 0.3
	message.TextWrapped = true
	local function fit(): ()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local viewport = camera.ViewportSize
		local narrow = viewport.X < 740
		local width = math.min(840, viewport.X - 32)
		local height = math.min(560, viewport.Y - 48)
		panel.Size = UDim2.fromOffset(width, height)
		local cardWidth = if narrow then width - 44 else math.floor((width - 72) / 3)
		layout.FillDirectionMaxCells = if narrow then 1 else 3
		layout.CellSize = UDim2.fromOffset(cardWidth, 338)
		scroll.CanvasSize = UDim2.fromOffset(0, if narrow then 3 * 338 + 2 * 14 else 338)
		-- Keep controls clear of the native touch thumbstick/jump area.
		open.Position = UDim2.new(0, if narrow then 12 else 28, 0.30, 0)
		collect.Position = UDim2.new(0, if narrow then 12 else 28, 1, if narrow then -220 else -94)
		collect.Size = UDim2.fromOffset(if narrow then 170 else 220, 60)
		autoStatus.Position = UDim2.new(0, if narrow then 12 else 28, 1, if narrow then -226 else -100)
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
	table.insert(
		connections,
		open.Activated:Connect(function()
			settings.Set("ShopOpen", settings.Get("ShopOpen") ~= true)
		end)
	)
	table.insert(
		connections,
		close.Activated:Connect(function()
			settings.Set("ShopOpen", false)
		end)
	)
	table.insert(
		connections,
		shade.Activated:Connect(function()
			settings.Set("ShopOpen", false)
		end)
	)
	table.insert(
		connections,
		settings.Observe(function()
			shade.Visible = settings.Get("ShopOpen") == true
		end)
	)
	table.insert(
		connections,
		game:GetService("UserInputService").InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Escape and settings.Get("ShopOpen") == true then
				settings.Set("ShopOpen", false)
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
		Cards = cards,
		Collect = collect,
		Auto = autoStatus,
		Message = message,
		Retry = retry,
		PreviewReset = previewReset,
		Subtitle = subtitle,
		Footer = footer,
	}
end
return View
