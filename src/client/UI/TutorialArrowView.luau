--!strict
local Config = require(game:GetService("ReplicatedStorage").Shared.TutorialConfig)
local Style = Config.STYLE
local View = {}
export type Layout = {
	StartX: number,
	StartY: number,
	TipX: number,
	TipY: number,
	ShaftX: number,
	ShaftY: number,
	LeftX: number,
	LeftY: number,
	RightX: number,
	RightY: number,
}
export type Arrow = {
	Gui: ScreenGui,
	Update: (Vector3, Vector3, Camera) -> boolean,
	Hide: () -> (),
	Destroy: () -> (),
}
local function finite(value: number): boolean
	return value == value and math.abs(value) ~= math.huge
end

-- Work in viewport pixels so thickness remains readable as the camera moves.
-- Positive-depth offscreen targets are clipped along the same character/plate ray.
function View.CalculateLayout(x0: number, y0: number, x1: number, y1: number, width: number, height: number): Layout?
	for _, value in { x0, y0, x1, y1, width, height } do
		if not finite(value) then
			return nil
		end
	end
	local inset = Style.Inset
	if width <= inset * 2 or height <= inset * 2 or x0 < 0 or x0 > width or y0 < 0 or y0 > height then
		return nil
	end
	local dx, dy = x1 - x0, y1 - y0
	local distance = math.sqrt(dx * dx + dy * dy)
	if not finite(distance) or distance < Style.MinPixels then
		return nil
	end
	local t = 1
	if dx > 0 and x1 > width - inset then
		t = math.min(t, (width - inset - x0) / dx)
	elseif dx < 0 and x1 < inset then
		t = math.min(t, (inset - x0) / dx)
	end
	if dy > 0 and y1 > height - inset then
		t = math.min(t, (height - inset - y0) / dy)
	elseif dy < 0 and y1 < inset then
		t = math.min(t, (inset - y0) / dy)
	end
	local length = distance * t - Style.EndpointGap * 2
	if t <= 0 or length < Style.MinPixels then
		return nil
	end
	local ux, uy = dx / distance, dy / distance
	local startX, startY = x0 + ux * Style.EndpointGap, y0 + uy * Style.EndpointGap
	local tipX, tipY = x0 + dx * t - ux * Style.EndpointGap, y0 + dy * t - uy * Style.EndpointGap
	local head = math.min(Style.HeadLength, length * Style.MaxHeadFraction)
	local baseX, baseY = tipX - ux * head, tipY - uy * head
	return {
		StartX = startX,
		StartY = startY,
		TipX = tipX,
		TipY = tipY,
		ShaftX = tipX - ux * head * Style.NeckFraction,
		ShaftY = tipY - uy * head * Style.NeckFraction,
		LeftX = baseX - uy * head * Style.HeadSpread,
		LeftY = baseY + ux * head * Style.HeadSpread,
		RightX = baseX + uy * head * Style.HeadSpread,
		RightY = baseY - ux * head * Style.HeadSpread,
	}
end

function View.new(parent: Instance): Arrow
	local gui = Instance.new("ScreenGui")
	gui.Name = "FirstPurchaseArrow"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = Style.DisplayOrder
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = false
	local gold = Color3.fromHex(Style.Gold)
	local outline = Color3.fromHex(Style.OutlineColor)
	local function makeBar(name: string): Frame
		local bar = Instance.new("Frame")
		bar.Name = name
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.BackgroundColor3 = gold
		bar.BorderSizePixel = 0
		bar.Active = false
		bar.Selectable = false
		bar.ZIndex = 2
		local stroke = Instance.new("UIStroke")
		stroke.Color = outline
		stroke.Thickness = Style.Outline
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = bar
		bar.Parent = gui
		return bar
	end
	local shaft = makeBar("Shaft")
	local left = makeBar("ArrowheadLeft")
	local right = makeBar("ArrowheadRight")
	local destroyed = false
	local function hide(): ()
		if not destroyed then
			gui.Enabled = false
		end
	end
	local function barBetween(bar: Frame, x0: number, y0: number, x1: number, y1: number): ()
		local dx, dy = x1 - x0, y1 - y0
		bar.Position = UDim2.fromOffset((x0 + x1) / 2, (y0 + y1) / 2)
		bar.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), Style.Thickness)
		bar.Rotation = math.deg(math.atan2(dy, dx))
	end
	gui.Parent = parent
	return {
		Gui = gui,
		Update = function(from: Vector3, to: Vector3, camera: Camera): boolean
			if destroyed then
				return false
			end
			if
				not (
					finite(from.X)
					and finite(from.Y)
					and finite(from.Z)
					and finite(to.X)
					and finite(to.Y)
					and finite(to.Z)
				)
			then
				hide()
				return false
			end
			local a = camera:WorldToViewportPoint(from)
			local b = camera:WorldToViewportPoint(to)
			if not (a.Z > 0 and b.Z > 0) then
				hide()
				return false
			end
			local viewport = camera.ViewportSize
			local layout = View.CalculateLayout(a.X, a.Y, b.X, b.Y, viewport.X, viewport.Y)
			if not layout then
				hide()
				return false
			end
			barBetween(shaft, layout.StartX, layout.StartY, layout.ShaftX, layout.ShaftY)
			barBetween(left, layout.LeftX, layout.LeftY, layout.TipX, layout.TipY)
			barBetween(right, layout.RightX, layout.RightY, layout.TipX, layout.TipY)
			gui.Enabled = true
			return true
		end,
		Hide = hide,
		Destroy = function(): ()
			if destroyed then
				return
			end
			gui.Enabled = false
			destroyed = true
			gui:Destroy()
		end,
	}
end
return View
