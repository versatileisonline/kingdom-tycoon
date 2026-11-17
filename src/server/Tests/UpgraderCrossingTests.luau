--!strict
local Tests = {}
function Tests.Run(Crossing: any): ()
	local function hit(x0: number, y0: number, z0: number, x1: number, y1: number, z1: number): boolean
		return Crossing.IntersectsBox(x0, y0, z0, x1, y1, z1, 4, 2, 2)
	end
	assert(hit(0, 0, -5, 0, 0, 5), "Fast segment skipped box")
	assert(hit(0, 0, 0, 0, 0, 1), "Forward passage starting inside missed")
	assert(hit(4, 0, -5, 4, 0, 5), "Boundary passage missed")
	assert(not hit(5, 0, -5, 5, 0, 5), "Side miss accepted")
	assert(not hit(0, 3, -5, 0, 3, 5), "Above-zone miss accepted")
	assert(not hit(0, 0, 3, 0, 0, 5), "Already-past coin accepted")
	assert(not hit(0, 0, -5, 0, 0, -3), "Not-yet-reached coin accepted")
	assert(not hit(0 / 0, 0, -5, 0, 0, 5), "NaN segment accepted")
	print("All upgrader crossing geometry checks passed")
end
function Tests.RunEngine(Crossing: any): ()
	local frame = CFrame.new(10, 5, 20) * CFrame.Angles(0, math.pi / 3, 0)
	local from = frame:PointToWorldSpace(Vector3.new(0, 0, 5))
	local to = frame:PointToWorldSpace(Vector3.new(0, 0, -5))
	local size = Vector3.new(8, 4, 4)
	assert(Crossing.Crosses(from, to, frame, size, frame.LookVector), "Rotated forward crossing missed")
	assert(not Crossing.Crosses(to, from, frame, size, frame.LookVector), "Reverse crossing accepted")
	assert(not Crossing.Crosses(from, from, frame, size, frame.LookVector), "Stationary coin accepted")
	assert(
		not Crossing.Crosses(to, to + frame.LookVector * 5, frame, size, frame.LookVector),
		"Past coin retroactively upgraded"
	)
	print("All upgrader directional crossing checks passed")
end
return Tests
