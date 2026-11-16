--!strict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Presentation = require(Shared.PlatePresentation)
local Tests = {}

function Tests.Run(): ()
	local plate = Instance.new("Part")
	local gui = Instance.new("BillboardGui")
	gui.Name = "PlateLabel"
	gui.StudsOffsetWorldSpace = Vector3.new(3, 4, 5)
	gui.ExtentsOffset = Vector3.one
	gui.SizeOffset = Vector2.one
	gui.Parent = plate
	local label = Instance.new("TextLabel")
	label.Name = "PurchaseLabel"
	label.Parent = gui
	local ok, reason = xpcall(function(): string?
		Presentation.Style(plate)
		assert(gui.Adornee == plate, "Label does not explicitly adorn plate center")
		assert(
			gui.StudsOffsetWorldSpace == Vector3.zero
				and gui.ExtentsOffset == Vector3.zero
				and gui.SizeOffset == Vector2.zero,
			"Inherited offsets displace label"
		)
		assert(
			gui.StudsOffset.X == 0 and gui.StudsOffset.Y > 0 and gui.StudsOffset.Z == 0,
			"Label does not hover vertically above screen center"
		)
		assert(
			label.AnchorPoint == Vector2.new(0.5, 0.5) and label.Position == UDim2.fromScale(0.5, 0.5),
			"Label rectangle not centered"
		)
		Presentation.SetAmount(label, "Dropper 4", 24)
		assert(
			label.RichText and tostring(label.Text) == 'Dropper 4\n24 <font color="#E7B84B">●</font>',
			"Price/icon presentation incorrect"
		)
		Presentation.SetAmount(label, "Collect:", 0)
		assert(
			tostring(label.Text) == 'Collect:\n0 <font color="#E7B84B">●</font>',
			"Zero collection presentation incorrect"
		)
		Presentation.SetAmount(label, "A & <B>", 40)
		assert(string.find(label.Text, "A &amp; &lt;B&gt;", 1, true) ~= nil, "Title interpreted as markup")
		Presentation.Style(plate)
		assert(#plate:GetChildren() == 1 and gui.Parent == plate, "Restyling duplicates billboard")
		return nil
	end, debug.traceback)
	plate:Destroy()
	assert(ok, reason)
	print("All centered plate presentation checks passed")
end
return Tests
