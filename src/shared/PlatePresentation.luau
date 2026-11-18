--!strict
local Config = require(script.Parent.Config)
local HudConfig = require(script.Parent.HudConfig)
local settings = Config.PLATES
local PlatePresentation = {}

function PlatePresentation.Style(plate: BasePart): ()
	if plate:IsA("Part") then
		local frame = plate.CFrame
		local halfHeight = (
			math.abs(frame.RightVector.Y) * plate.Size.X
			+ math.abs(frame.UpVector.Y) * plate.Size.Y
			+ math.abs(frame.LookVector.Y) * plate.Size.Z
		) / 2
		local center =
			Vector3.new(plate.Position.X, plate.Position.Y + halfHeight - settings.THICKNESS / 2, plate.Position.Z)
		plate.Shape = Enum.PartType.Cylinder
		plate.Size = Vector3.new(settings.THICKNESS, settings.DIAMETER, settings.DIAMETER)
		plate.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2)
		local outline = plate:FindFirstChild("Outline")
		if outline ~= nil and outline:IsA("Part") then
			outline.Size = Vector3.new(
				settings.THICKNESS,
				settings.DIAMETER + 2 * settings.RIM_WIDTH,
				settings.DIAMETER + 2 * settings.RIM_WIDTH
			)
			outline.CFrame = plate.CFrame + Vector3.new(0, -settings.RIM_DROP, 0)
		end
	end
	local label = plate:FindFirstChildWhichIsA("TextLabel", true)
	if label == nil then
		return
	end
	local oldGui = label:FindFirstAncestorWhichIsA("LayerCollector")
	local existing = plate:FindFirstChild("PlateLabel")
	local billboard: BillboardGui
	if existing ~= nil and existing:IsA("BillboardGui") then
		billboard = existing
	else
		billboard = Instance.new("BillboardGui")
		billboard.Name = "PlateLabel"
		billboard.Parent = plate
	end
	billboard.Size = UDim2.fromOffset(settings.LABEL_WIDTH, settings.LABEL_HEIGHT)
	billboard.Adornee = plate
	-- Camera-relative up keeps screen X centered even with an oblique camera.
	billboard.StudsOffset = Vector3.new(0, settings.LABEL_OFFSET, 0)
	billboard.StudsOffsetWorldSpace = Vector3.zero
	billboard.ExtentsOffset = Vector3.zero
	billboard.ExtentsOffsetWorldSpace = Vector3.zero
	billboard.SizeOffset = Vector2.zero
	billboard.MaxDistance = settings.LABEL_DISTANCE
	billboard.AlwaysOnTop = true
	label.Parent = billboard
	if oldGui ~= nil and oldGui ~= billboard then
		oldGui:Destroy()
	end
	label.Size = UDim2.fromScale(1, 1)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Rotation = 0
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.TextSize = settings.LABEL_SIZE
	label.TextScaled = false
	label.TextWrapped = false
	label.Font = HudConfig.FONT
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = if label:FindFirstChild("CurrencyRow")
		then Enum.TextYAlignment.Top
		else Enum.TextYAlignment.Center
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
end

-- Native image/text composition keeps the entire price row centered at any amount.
function PlatePresentation.SetAmount(label: TextLabel, title: string, amount: number): ()
	label.RichText = false
	label.Text = title
	label.TextYAlignment = Enum.TextYAlignment.Top
	local row = label:FindFirstChild("CurrencyRow") :: Frame?
	if row == nil then
		row = Instance.new("Frame")
		row.Name = "CurrencyRow"
		row.BackgroundTransparency = 1
		row.AnchorPoint = Vector2.new(0.5, 1)
		row.Position = UDim2.fromScale(0.5, 1)
		row.Parent = label
		local value = Instance.new("TextLabel")
		value.Name = "Amount"
		value.BackgroundTransparency = 1
		value.Font = label.Font
		value.TextSize = label.TextSize
		value.TextColor3 = label.TextColor3
		value.TextStrokeTransparency = label.TextStrokeTransparency
		value.Parent = row
		local coin = Instance.new("ImageLabel")
		coin.Name = "Coin"
		coin.BackgroundTransparency = 1
		coin.Image = HudConfig.ART.Coin
		coin.Size = UDim2.fromOffset(HudConfig.UI.CoinSize, HudConfig.UI.CoinSize)
		coin.AnchorPoint = Vector2.new(1, 0.5)
		coin.Position = UDim2.fromScale(1, 0.5)
		coin.Parent = row
	end
	local value = row:FindFirstChild("Amount") :: TextLabel
	value.Text = string.format("%d", amount)
	local width = game:GetService("TextService")
		:GetTextSize(value.Text, label.TextSize, label.Font, Vector2.new(10000, 100)).X
	row.Size = UDim2.fromOffset(width + HudConfig.UI.CoinGap + HudConfig.UI.CoinSize, settings.LABEL_HEIGHT / 2)
	value.Size = UDim2.new(0, width, 1, 0)
end

function PlatePresentation.SetVisible(plate: BasePart, visible: boolean): ()
	plate.Transparency = if visible then 0 else 1
	plate.CanCollide = visible
	-- Keep CanTouch enabled on reusable claim plates; the private registry gates requests.
	for _, item in plate:GetDescendants() do
		if item:IsA("BasePart") then
			item.Transparency = if visible then 0 else 1
		end
		if item:IsA("LayerCollector") then
			item.Enabled = visible
		end
	end
end

return PlatePresentation
