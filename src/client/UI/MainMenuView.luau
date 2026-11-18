--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.MainMenuConfig)
local Colors = require(Shared.HudConfig).COLORS
local Style = require(script.Parent.RoyalStyle)
local View = {}
function View.new(parent: Instance)
	local connections: { RBXScriptConnection } = {}
	local screen = Instance.new("ScreenGui")
	screen.Name = "KingdomMainMenu"
	screen.IgnoreGuiInset, screen.ResetOnSpawn = true, false
	screen.DisplayOrder = 5 -- Existing Settings HUD renders above the backdrop.
	local backdrop = Instance.new("Frame")
	backdrop.Name, backdrop.Size = "Backdrop", UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3, backdrop.BorderSizePixel = Color3.fromHex("141821"), 0
	backdrop.Parent = screen
	Style.Gradient(backdrop, "242B39", "101218")
	local panel = Instance.new("Frame")
	panel.Name, panel.BackgroundTransparency = "Menu", 1
	panel.AnchorPoint, panel.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
	panel.Size, panel.Parent = UDim2.fromOffset(Config.WIDTH, Config.HEIGHT), backdrop
	local scale = Instance.new("UIScale")
	scale.Parent = panel
	local function label(name: string, value: string, y: number, height: number, size: number): TextLabel
		local item = Instance.new("TextLabel")
		item.Name, item.Text = name, value
		item.BackgroundTransparency, item.Font = 1, require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT
		item.TextColor3, item.TextSize = Color3.fromHex(Colors.Gold), size + 2
		item.Position, item.Size = UDim2.fromOffset(0, y), UDim2.new(1, 0, 0, height)
		item.Parent = panel
		return item
	end
	local title = label("Title", Config.TITLE, 40, 100, 42)
	title.TextWrapped = true
	title.TextStrokeColor3, title.TextStrokeTransparency = Color3.fromHex("080A0F"), 0
	local rule = Instance.new("Frame")
	rule.Name, rule.BorderSizePixel = "GoldRule", 0
	rule.BackgroundColor3 = Color3.fromHex(Colors.Border)
	rule.Position, rule.Size = UDim2.new(0.5, -72, 0, 154), UDim2.fromOffset(144, 3)
	rule.Parent = panel
	local function button(name: string, value: string, y: number): TextButton
		local shadow = Instance.new("Frame")
		shadow.Name, shadow.BorderSizePixel = name .. "Shadow", 0
		shadow.Position, shadow.Size = UDim2.new(0.5, -174, 0, y + 6), UDim2.fromOffset(354, 58)
		shadow.BackgroundColor3, shadow.Parent = Color3.fromHex("080A0F"), panel
		local item = Instance.new("TextButton")
		item.Name, item.Text, item.Font =
			name, value, require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT
		item.TextSize, item.TextColor3 = 26, Color3.fromHex(Colors.Text)
		item.BackgroundColor3, item.BorderSizePixel = Color3.fromHex(Colors.Raised), 0
		item.Position, item.Size = UDim2.new(0.5, -178, 0, y), UDim2.fromOffset(356, 56)
		item.Parent = panel
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode, stroke.Thickness = Enum.ApplyStrokeMode.Border, 3
		stroke.Color, stroke.Parent = Color3.fromHex(Colors.Border), item
		Style.Feedback(item, connections)
		return item
	end
	local play = button("Play", "PLAY", 202)
	local settings = button("Settings", "SETTINGS", 278)
	play.NextSelectionDown, settings.NextSelectionUp = settings, play
	local status = label("Status", "Loading…", 356, 38, 14)
	status.Font, status.TextWrapped = require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT, true
	status.TextColor3 = Color3.fromHex(Colors.Muted)
	local cameraConnection: RBXScriptConnection? = nil
	local function fit(): ()
		local camera = workspace.CurrentCamera
		if camera then
			scale.Scale = math.min(
				1,
				(camera.ViewportSize.X - 2 * Config.MARGIN) / Config.WIDTH,
				(camera.ViewportSize.Y - 2 * Config.MARGIN) / Config.HEIGHT
			)
		end
	end
	local function bind(): ()
		if cameraConnection then
			cameraConnection:Disconnect()
		end
		local camera = workspace.CurrentCamera
		if camera then
			cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
		end
		fit()
	end
	table.insert(connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bind))
	bind()
	table.insert(
		connections,
		screen.Destroying:Connect(function()
			if cameraConnection then
				cameraConnection:Disconnect()
			end
			for _, connection in connections do
				connection:Disconnect()
			end
		end)
	)
	-- Parent last: no half-built menu flashes.
	screen.Parent = parent
	return { Screen = screen, Panel = panel, Play = play, Settings = settings, Status = status }
end
return View
