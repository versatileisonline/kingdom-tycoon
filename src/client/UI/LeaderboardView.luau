--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Hud = require(Shared.HudConfig)
local Config = require(Shared.LeaderboardConfig)
local Style = require(script.Parent.RoyalStyle)
local State = require(script.Parent.LeaderboardState)
local View = {}
local C = Hud.COLORS
local function label(
	parent: Instance,
	name: string,
	text: string,
	x: number,
	y: number,
	width: number,
	size: number
): TextLabel
	local item = Instance.new("TextLabel")
	item.Name, item.Text, item.Font = name, text, Hud.FONT
	item.TextSize, item.TextColor3 = size + 2, Color3.fromHex(C.Text)
	item.TextStrokeColor3, item.TextStrokeTransparency = Color3.fromHex(C.Track), 0.65
	item.BackgroundTransparency = 1
	item.Position, item.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(width, 48)
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextTruncate = Enum.TextTruncate.AtEnd
	if name == "Gold" or name == "Rebirths" then
		item.TextScaled = true
		local limit = Instance.new("UITextSizeConstraint")
		limit.MinTextSize, limit.MaxTextSize, limit.Parent = 9, size + 2, item
	end
	item.ZIndex, item.Parent = 4, parent
	return item
end
local function border(item: GuiObject, color: string): ()
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness = Color3.fromHex(color), 2
	stroke.ApplyStrokeMode, stroke.Parent = Enum.ApplyStrokeMode.Border, item
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 6), item
end
function View.new(parent: Instance, localId: number)
	local screen = Instance.new("ScreenGui")
	screen.Name, screen.ResetOnSpawn, screen.DisplayOrder = "KingdomLeaderboard", false, 25
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.IgnoreGuiInset = true
	local panel = Instance.new("Frame")
	panel.Name, panel.AnchorPoint = "Panel", Vector2.new(1, 0)
	panel.Position, panel.Size = UDim2.new(1, -24, 0, 24), UDim2.fromOffset(Config.WIDTH, Config.HEIGHT)
	panel.BackgroundColor3, panel.BorderSizePixel = Color3.fromHex(C.Raised), 0
	panel.Visible, panel.Parent = false, screen
	border(panel, C.Border)
	Style.Corners(panel, 55, 3)
	local scale = Instance.new("UIScale")
	scale.Parent = panel
	local banner = Style.Image(panel, "RoyalBanner", Hud.ART.Banner, 5)
	banner.Position, banner.Size = UDim2.fromOffset(35, -25), UDim2.fromOffset(700, 110)
	local title = label(banner, "Title", "SERVER LEADERBOARD", 35, 22, 630, 22)
	title.TextXAlignment, title.ZIndex = Enum.TextXAlignment.Center, 6
	local subtitle = label(panel, "Subtitle", "Players in this server", 100, 64, 600, 12)
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	local close = Instance.new("TextButton")
	close.Name, close.Text, close.Font = "Close", "X", Hud.FONT
	close.TextSize, close.TextColor3 = 24, Color3.fromHex(C.Gold)
	close.BackgroundColor3 = Color3.fromHex(C.Raised)
	close.Position, close.Size = UDim2.new(1, -54, 0, 8), UDim2.fromOffset(40, 40)
	close.ZIndex, close.Parent = 7, panel
	border(close, C.Border)
	local columns = {
		{ "Rank", "#", 20, 40 },
		{ "Player", "Player", 118, 270 },
		{ "LifetimeGold", "Lifetime Gold", 400, 210 },
		{ "Rebirths", "Rebirths", 640, 140 },
	}
	for _, column in columns do
		label(panel, column[1] :: string, column[2] :: string, column[3] :: number, 100, column[4] :: number, 12)
	end
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name, scroll.BackgroundTransparency, scroll.BorderSizePixel = "Players", 1, 0
	scroll.Position, scroll.Size = UDim2.fromOffset(16, 148), UDim2.new(1, -32, 1, -200)
	scroll.AutomaticCanvasSize, scroll.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ScrollBarThickness, scroll.ScrollBarImageColor3 = Config.SCROLLBAR_WIDTH, Color3.fromHex(C.Gold)
	scroll.Parent = panel
	-- UIStroke extends outside the row. Keep both endpoints inside the clipped
	-- viewport and reserve a separate lane for the scrollbar on the right.
	local padding = Instance.new("UIPadding")
	padding.PaddingTop, padding.PaddingBottom = UDim.new(0, Config.ROW_INSET), UDim.new(0, Config.ROW_INSET)
	padding.PaddingLeft = UDim.new(0, Config.ROW_INSET)
	padding.PaddingRight = UDim.new(0, Config.SCROLLBAR_WIDTH + Config.SCROLLBAR_GAP)
	padding.Parent = scroll
	local layout = Instance.new("UIListLayout")
	layout.SortOrder, layout.Padding, layout.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 4), scroll
	local footer = label(panel, "Footer", "Tab to close", 160, Config.HEIGHT - 48, 480, 12)
	footer.TextXAlignment, footer.TextColor3 = Enum.TextXAlignment.Center, Color3.fromHex(C.Muted)
	local launcher = Instance.new("TextButton")
	launcher.Name, launcher.Text = "LeaderboardButton", ""
	launcher.BackgroundColor3 = Color3.fromHex(C.Raised)
	launcher.AnchorPoint = Vector2.new(1, 0)
	launcher.Size, launcher.Parent = UDim2.fromOffset(Config.LAUNCHER_WIDTH, Config.LAUNCHER_HEIGHT), screen
	border(launcher, C.Border)
	local launcherCorner = launcher:FindFirstChildOfClass("UICorner") :: UICorner
	launcherCorner.CornerRadius = UDim.new(0, 12)
	Style.Corners(launcher, 30, 2)
	local icon = Style.Image(launcher, "LeaderboardIcon", Config.LAUNCHER_ART, 3)
	icon.AnchorPoint, icon.Position = Vector2.new(0, 0.5), UDim2.new(0, 6, 0.5, 0)
	icon.Size = UDim2.fromOffset(Config.LAUNCHER_ICON_SIZE, Config.LAUNCHER_ICON_SIZE)
	local caption =
		label(launcher, "Caption", "Ranks", Config.LAUNCHER_TEXT_INSET, 0, 78, Config.LAUNCHER_TEXT_SIZE - 2)
	caption.Size = UDim2.fromOffset(Config.LAUNCHER_WIDTH - Config.LAUNCHER_TEXT_INSET - 6, Config.LAUNCHER_HEIGHT)
	caption.TextStrokeColor3, caption.TextStrokeTransparency = caption.TextColor3, Hud.UI.LauncherStrokeTransparency
	local rows: { [number]: Frame } = {}
	local function portrait(row: Frame, content: string): ()
		local avatar = row:FindFirstChild("Avatar") :: ImageLabel
		avatar.Image = content
	end
	local fit: () -> ()
	local function render(entries: { State.Entry }, portraits: { [number]: string }): ()
		local present: { [number]: boolean } = {}
		for index, entry in entries do
			present[entry.UserId] = true
			local row = rows[entry.UserId]
			if not row then
				row = Instance.new("Frame")
				row.Name, row.Size, row.BorderSizePixel =
					tostring(entry.UserId), UDim2.new(1, 0, 0, Config.ROW_HEIGHT), 0
				row.Parent = scroll
				rows[entry.UserId] = row
				local avatar = Instance.new("ImageLabel")
				avatar.Name, avatar.Position, avatar.Size = "Avatar", UDim2.fromOffset(48, 4), UDim2.fromOffset(48, 48)
				avatar.BackgroundColor3, avatar.BorderSizePixel = Color3.fromHex(C.Raised), 0
				avatar.ZIndex, avatar.Parent = 4, row
				label(row, "Rank", "", 4, 4, 40, 17)
				label(row, "Player", entry.Name, 102, 4, 270, 13)
				label(row, "Gold", "", 384, 4, 230, 14).TextColor3 = Color3.fromHex(C.Gold)
				label(row, "Rebirths", "", 624, 4, 120, 14)
				if entry.UserId == localId then
					border(row, C.Gold)
					local you = label(row, "You", "YOU", 324, 4, 48, 10)
					you.TextColor3 = Color3.fromHex(C.Gold)
					local playerLabel = row:FindFirstChild("Player") :: TextLabel
					playerLabel.Size = UDim2.fromOffset(218, 48)
				end
			end
			row.LayoutOrder = index
			row.BackgroundColor3 = Color3.fromHex(
				if entry.UserId == localId
					then Config.ROW_COLORS.LocalPlayer
					elseif index % 2 == 0 then Config.ROW_COLORS.Even
					else Config.ROW_COLORS.Odd
			)
			local rankLabel = row:FindFirstChild("Rank") :: TextLabel
			rankLabel.Text = if entry.LifetimeGold ~= nil then tostring(index) else "-"
			local nameLabel = row:FindFirstChild("Player") :: TextLabel
			nameLabel.Text = entry.Name
			local goldLabel = row:FindFirstChild("Gold") :: TextLabel
			goldLabel.Text = State.Format(entry.LifetimeGold)
			local rebirthLabel = row:FindFirstChild("Rebirths") :: TextLabel
			rebirthLabel.Text = State.Format(entry.Rebirths)
			portrait(row, portraits[entry.UserId] or "")
		end
		for id, row in rows do
			if not present[id] then
				row:Destroy()
				rows[id] = nil
			end
		end
		fit()
	end
	fit = function(): ()
		local viewport = screen.AbsoluteSize
		local inset = game:GetService("GuiService"):GetGuiInset().Y
		-- Both HUDs ignore the inset. Reuse Settings' authored position because
		-- GuiService's inset can become ready after the HUD was constructed.
		local hudScreen = parent:FindFirstChild("KingdomHUD")
		local settingsButton = if hudScreen then hudScreen:FindFirstChild("SettingsButton") else nil
		local settingsPosition = UDim2.new(1, -20, 0, inset + 16)
		local settingsWidth = Config.LAUNCHER_HEIGHT
		if settingsButton and settingsButton:IsA("GuiObject") then
			settingsPosition = settingsButton.Position
			settingsWidth = settingsButton.Size.X.Offset
		end
		local width = math.min(Config.WIDTH, math.max(280, (viewport.X - 48) / Config.PANEL_SCALE))
		local height = math.min(Config.HEIGHT, math.max(220, (viewport.Y - inset - 64) / Config.PANEL_SCALE))
		local compact = width < Config.WIDTH
		local shortLayout = Config.SHORT_LAYOUT
		local short = height < shortLayout.Height
		panel.Size = UDim2.fromOffset(width, height)
		panel.Position = UDim2.new(1, -24, 0, inset + 24)
		scale.Scale = Config.PANEL_SCALE
		launcher.Position = UDim2.new(
			settingsPosition.X.Scale,
			settingsPosition.X.Offset - settingsWidth - Config.LAUNCHER_GAP,
			settingsPosition.Y.Scale,
			settingsPosition.Y.Offset
		)
		banner.Position, banner.Size =
			UDim2.fromOffset(20, -25), UDim2.new(1, -64, 0, if short then shortLayout.BannerHeight else 110)
		title.Position, title.Size = UDim2.fromOffset(12, 22), UDim2.new(1, -24, 0, 48)
		title.TextSize = if compact then 14 else 24
		subtitle.Position, subtitle.Size = UDim2.fromOffset(16, 64), UDim2.new(1, -32, 0, 32)
		subtitle.TextSize = if compact then 10 else 14
		subtitle.Visible, footer.Visible = not short, not short
		scroll.Position = UDim2.fromOffset(16, if short then shortLayout.ScrollTop else 148)
		scroll.Size = UDim2.new(1, -32, 1, if short then -(shortLayout.ScrollTop + shortLayout.ScrollBottom) else -200)
		footer.Position, footer.Size = UDim2.new(0, 16, 1, -48), UDim2.new(1, -32, 0, 48)
		for _, column in columns do
			local heading = panel:FindFirstChild(column[1] :: string) :: TextLabel
			if compact then
				local key = column[1]
				heading.Position = UDim2.fromOffset(
					if key == "Rank" then 20 elseif key == "Rebirths" then width - 92 else 92,
					if key == "LifetimeGold" or key == "Rebirths"
						then (if short then shortLayout.ValuesHeadingY else 119)
						else (if short then shortLayout.PlayerHeadingY else 88)
				)
				heading.Size = UDim2.fromOffset(if key == "Rebirths" then 76 else width - 110, 24)
				heading.TextSize = if key == "Rebirths" then 10 else 12
			else
				heading.Position =
					UDim2.fromOffset(column[3] :: number, if short then shortLayout.WideHeadingY else 100)
				heading.Size, heading.TextSize = UDim2.fromOffset(column[4] :: number, 48), 14
			end
		end
		for _, row in rows do
			local avatar = row:FindFirstChild("Avatar") :: ImageLabel
			local name = row:FindFirstChild("Player") :: TextLabel
			local gold = row:FindFirstChild("Gold") :: TextLabel
			local rebirths = row:FindFirstChild("Rebirths") :: TextLabel
			local you = row:FindFirstChild("You") :: TextLabel?
			avatar.Position, avatar.Size =
				UDim2.fromOffset(if compact then 28 else 48, 4),
				UDim2.fromOffset(if compact then 36 else 48, if compact then 36 else 48)
			name.Position, name.Size =
				UDim2.fromOffset(if compact then 76 else 102, if compact then -8 else 4),
				UDim2.fromOffset(if compact then width - 180 elseif you then 218 else 270, 48)
			gold.Position, gold.Size =
				UDim2.fromOffset(if compact then 76 else 384, if compact then 21 else 4),
				UDim2.fromOffset(if compact then width - 192 else 230, if compact then 30 else 48)
			rebirths.Position, rebirths.Size =
				UDim2.fromOffset(if compact then width - 100 else 624, if compact then 21 else 4),
				UDim2.fromOffset(if compact then 64 else 120, if compact then 30 else 48)
			if you then
				you.Position = UDim2.fromOffset(if compact then width - 94 else 324, if compact then -8 else 4)
			end
		end
	end
	screen.Parent = parent
	return {
		Screen = screen,
		Panel = panel,
		Close = close,
		Launcher = launcher,
		Render = render,
		SetOpen = function(open: boolean): ()
			panel.Visible = open
			launcher.Visible = not open
		end,
		SetAvailable = function(available: boolean): ()
			screen.Enabled = available
		end,
		Fit = fit,
	}
end
return View
