--!strict
-- Swept point/box intersection prevents a timed tick from skipping a thin zone.
local Crossing = {}
function Crossing.IntersectsBox(
	x0: number,
	y0: number,
	z0: number,
	x1: number,
	y1: number,
	z1: number,
	halfX: number,
	halfY: number,
	halfZ: number
): boolean
	local start = { x0, y0, z0 }
	local finish = { x1, y1, z1 }
	local half = { halfX, halfY, halfZ }
	local enter, leave = 0, 1
	for axis = 1, 3 do
		local a, b, h = start[axis], finish[axis], half[axis]
		if a ~= a or b ~= b or math.abs(a) == math.huge or math.abs(b) == math.huge then
			return false
		end
		local delta = b - a
		if delta == 0 then
			if math.abs(a) > h then
				return false
			end
		else
			local first, last = (-h - a) / delta, (h - a) / delta
			if first > last then
				first, last = last, first
			end
			enter = math.max(enter, first)
			leave = math.min(leave, last)
			if enter > leave then
				return false
			end
		end
	end
	return true
end
function Crossing.Crosses(from: Vector3, to: Vector3, frame: CFrame, size: Vector3, forward: Vector3): boolean
	if (to - from):Dot(forward) <= 0 then
		return false
	end
	local a, b = frame:PointToObjectSpace(from), frame:PointToObjectSpace(to)
	return Crossing.IntersectsBox(a.X, a.Y, a.Z, b.X, b.Y, b.Z, size.X / 2, size.Y / 2, size.Z / 2)
end
return Crossing
