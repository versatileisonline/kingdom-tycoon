--!strict
local Config = require(game:GetService("ReplicatedStorage").Shared.TutorialConfig)
local Style = Config.STYLE
local View = {}
export type Arrow = {
	Gui: ScreenGui,
	Update: (Vector3, Vector3, Camera) -> boolean,
	Hide: () -> (),
	Destroy: () -> (),
}
local function finite(value: number): boolean
	return value == value and math.abs(value) ~= math.huge
end
-- Bounded marker count, even for targets across the kingdom. No server work.
function View.CalculateDistances(distance: number): { number }
	if not finite(distance) or distance <= Style.StartGap + Style.EndGap then
		return {}
	end
	local available = distance - Style.StartGap - Style.EndGap
	local count = math.min(Style.MaxMarkers, math.floor(available / Style.Spacing) + 1)
	local step = if count > 1 then available / (count - 1) else 0
	local result: { number } = {}
	for index = 1, count do
		result[index] = Style.StartGap + (index - 1) * step
	end
	return result
end
function View.Pulse(distance: number, elapsed: number): number
	-- A crest moves toward increasing world distance (the objective).
	local phase = (distance - elapsed * Style.FlowSpeed) / Style.Wavelength
	return (0.5 + 0.5 * math.cos(phase * math.pi * 2)) ^ 3
end
function View.new(parent: Instance): Arrow
	local gui = Instance.new("ScreenGui")
	gui.Name = "FirstPurchaseArrow"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = Style.DisplayOrder
	gui.Enabled = false
	local markers: { TextLabel } = {}
	for index = 1, Style.MaxMarkers do
		local marker = Instance.new("TextLabel")
		marker.Name = "Arrowhead" .. index
		marker.AnchorPoint = Vector2.new(0.5, 0.5)
		marker.BackgroundTransparency = 1
		marker.BorderSizePixel = 0
		marker.Text = "▲"
		marker.Font = Enum.Font.GothamBold
		marker.TextScaled = true
		marker.TextColor3 = Color3.fromHex(Style.Gold)
		marker.TextStrokeColor3 = Color3.fromHex(Style.OutlineColor)
		marker.TextStrokeTransparency = 0.7
		marker.Active = false
		marker.Selectable = false
		marker.Visible = false
		marker.Parent = gui
		markers[index] = marker
	end
	local destroyed = false
	local function hide(): ()
		if not destroyed then
			gui.Enabled = false
		end
	end
	gui.Parent = parent
	return {
		Gui = gui,
		Update = function(from: Vector3, to: Vector3, camera: Camera): boolean
			if destroyed then
				return false
			end
			for _, value in { from.X, from.Y, from.Z, to.X, to.Y, to.Z } do
				if not finite(value) then
					hide()
					return false
				end
			end
			local delta = to - from
			local distance = delta.Magnitude
			local positions = View.CalculateDistances(distance)
			if #positions == 0 then
				hide()
				return false
			end
			local direction = delta.Unit
			local elapsed = os.clock()
			local visible = false
			for index, marker in markers do
				marker.Visible = false
				local along = positions[index]
				if along == nil then
					continue
				end
				local world = from + direction * along
				local point, onscreen = camera:WorldToViewportPoint(world)
				if point.Z <= 0 or not onscreen then
					continue
				end
				local nextPoint = camera:WorldToViewportPoint(world + direction)
				local dx, dy = nextPoint.X - point.X, nextPoint.Y - point.Y
				if dx * dx + dy * dy < 0.01 then
					continue
				end
				local edge = camera:WorldToViewportPoint(world + camera.CFrame.RightVector * Style.MarkerWidth)
				local pixels = math.clamp(math.abs(edge.X - point.X), Style.MinPixels, Style.MaxPixels)
				local pulse = View.Pulse(along, elapsed)
				marker.Position = UDim2.fromOffset(point.X, point.Y)
				marker.Size = UDim2.fromOffset(pixels, pixels)
				marker.Rotation = math.deg(math.atan2(dy, dx)) + 90
				marker.TextTransparency = Style.BaseTransparency - pulse * Style.PulseOpacity
				marker.TextColor3 = Color3.fromHex(Style.Gold):Lerp(Color3.fromHex(Style.BrightGold), pulse)
				marker.Visible = true
				visible = true
			end
			gui.Enabled = visible
			return visible
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
