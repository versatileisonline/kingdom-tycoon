--!strict
local Config = require(game:GetService("ReplicatedStorage").Shared.HudConfig)
local TweenService = game:GetService("TweenService")
local Style = {}
function Style.Image(parent: Instance, name: string, asset: string, z: number): ImageLabel
	local item = Instance.new("ImageLabel")
	item.Name = name
	item.BackgroundTransparency = 1
	item.Image = asset
	item.ScaleType = Enum.ScaleType.Fit
	item.ZIndex = z
	item.Parent = parent
	return item
end
function Style.Gradient(parent: GuiObject, top: string, bottom: string): ()
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromHex(top), Color3.fromHex(bottom))
	gradient.Rotation = 90
	gradient.Parent = parent
end
function Style.Corners(parent: GuiObject, size: number, z: number): ()
	for index, position in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(1, 1), Vector2.new(0, 1) } do
		local corner = Style.Image(parent, "GoldCorner" .. index, Config.ART.Corner, z)
		corner.Size = UDim2.fromOffset(size, size)
		corner.AnchorPoint = position
		corner.Position =
			UDim2.new(position.X, if position.X == 0 then -12 else 12, position.Y, if position.Y == 0 then -12 else 12)
		corner.Rotation = (index - 1) * 90
	end
end
function Style.Feedback(button: TextButton, connections: { RBXScriptConnection }): ()
	local base = button.BackgroundColor3
	local tween: Tween? = nil
	local function paint(bright: boolean): ()
		if tween then
			tween:Cancel()
		end
		tween = TweenService:Create(
			button,
			TweenInfo.new(0.12),
			{ BackgroundColor3 = if bright then base:Lerp(Color3.fromHex(Config.COLORS.Gold), 0.22) else base }
		)(tween :: Tween):Play()
	end
	table.insert(
		connections,
		button.MouseEnter:Connect(function()
			paint(true)
		end)
	)
	table.insert(
		connections,
		button.MouseLeave:Connect(function()
			paint(false)
		end)
	)
	table.insert(
		connections,
		button.SelectionGained:Connect(function()
			paint(true)
		end)
	)
	table.insert(
		connections,
		button.SelectionLost:Connect(function()
			paint(false)
		end)
	)
	table.insert(
		connections,
		button.MouseButton1Down:Connect(function()
			paint(true)
		end)
	)
	table.insert(
		connections,
		button.MouseButton1Up:Connect(function()
			paint(false)
		end)
	)
	table.insert(
		connections,
		button.Destroying:Connect(function()
			if tween then
				tween:Cancel()
			end
		end)
	)
end
return Style
