--!strict
local Tests = {}
function Tests.RunMath(View: any): ()
	local layout = View.CalculateLayout(100, 200, 500, 200, 800, 600)
	assert(layout ~= nil and layout.TipX > layout.StartX, "Forward arrow missing")
	assert(
		math.abs(layout.TipY - 200) < 0.001 and layout.TipX < 500 and layout.StartX > 100,
		"Arrow covered character/plate endpoints"
	)
	local reversed = View.CalculateLayout(500, 200, 100, 200, 800, 600)
	assert(reversed ~= nil and reversed.TipX < reversed.StartX, "Reverse screen direction failed")
	local clipped = View.CalculateLayout(400, 300, 2000, 300, 800, 600)
	assert(clipped ~= nil and clipped.TipX <= 776 and clipped.TipX > 400, "Offscreen target was not clipped")
	local diagonal = View.CalculateLayout(400, 300, 2000, -2000, 800, 600)
	assert(
		diagonal ~= nil
			and diagonal.TipX >= 24
			and diagonal.TipX <= 776
			and diagonal.TipY >= 24
			and diagonal.TipY <= 576,
		"Diagonal clipping escaped viewport"
	)
	assert(View.CalculateLayout(100, 200, 101, 200, 800, 600) == nil, "Short arrow shown")
	assert(View.CalculateLayout(-1, 200, 500, 200, 800, 600) == nil, "Offscreen character arrow shown")
	assert(View.CalculateLayout(100, 200, 500, 200, 0, 600) == nil, "Empty viewport arrow shown")
	assert(View.CalculateLayout(0 / 0, 200, 500, 200, 800, 600) == nil, "NaN geometry accepted")
	assert(View.CalculateLayout(100, 200, 1e308, 200, 800, 600) == nil, "Overflowing projection accepted")
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
