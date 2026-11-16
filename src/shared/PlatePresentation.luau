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
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
end

-- Only monetary labels enable RichText; player-authored owner labels remain plain text.
function PlatePresentation.SetAmount(label: TextLabel, title: string, amount: number): ()
	local escaped = title:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	label.RichText = true
	label.Text =
		string.format('%s\n%d <font color="#%s">%s</font>', escaped, amount, HudConfig.COLORS.Gold, HudConfig.GOLD_ICON)
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
