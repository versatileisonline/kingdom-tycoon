--!strict
local Tests = {}
function Tests.RunMath(View: any): ()
	local distances = View.CalculateDistances(20)
	assert(#distances > 3 and distances[1] > 0 and distances[#distances] < 20, "Repeated trail/end gaps missing")
	for index = 2, #distances do
		assert(distances[index] > distances[index - 1], "Trail reversed")
	end
	assert(#View.CalculateDistances(10000) <= 64, "Unbounded marker count")
	assert(#View.CalculateDistances(1) == 0, "Near-target trail shown")
	assert(#View.CalculateDistances(0 / 0) == 0 and #View.CalculateDistances(math.huge) == 0, "Invalid length accepted")
	assert(View.Pulse(0, 0) > View.Pulse(2, 0), "No translucent brightness wave")
	assert(math.abs(View.Pulse(0, 0) - View.Pulse(5, 1)) < 0.001, "Pulse does not flow toward objective")
	print("All tutorial arrow layout checks passed")
end
function Tests.Run(View: any): ()
	Tests.RunMath(View)
	local parent = Instance.new("Folder")
	local view = View.new(parent)
	local ok, reason = xpcall(function(): string?
		assert(view.Gui.Name == "FirstPurchaseArrow" and not view.Gui.Enabled, "Arrow initialization incorrect")
		assert(
			view.Gui:IsA("ScreenGui") and view.Gui.IgnoreGuiInset and not view.Gui.ResetOnSpawn,
			"Arrow coordinate/lifecycle contract incorrect"
		)
		local camera = workspace.CurrentCamera
		assert(camera and camera.ViewportSize.X > 100, "Camera viewport unavailable")
		local frame = camera.CFrame
		local from = frame:PointToWorldSpace(Vector3.new(0, -1, -10))
		local target = frame:PointToWorldSpace(Vector3.new(3, -1, -30))
		assert(view.Update(from, target, camera) and view.Gui.Enabled, "Projected arrow not visible")
		assert(
			not view.Update(from, frame:PointToWorldSpace(Vector3.new(0, 0, 10)), camera) and not view.Gui.Enabled,
			"Behind-camera arrow shown"
		)
		assert(not view.Update(from, from, camera) and not view.Gui.Enabled, "Coincident arrow shown")
		assert(view.Update(from, target, camera), "Arrow did not recover")
		view.Hide()
		assert(not view.Gui.Enabled, "Hide failed")
		return nil
	end, debug.traceback)
	view.Destroy()
	assert(view.Gui.Parent == nil, "Arrow cleanup left GUI")
	parent:Destroy()
	assert(ok, reason)
	print("All tutorial arrow view checks passed")
end
return Tests
