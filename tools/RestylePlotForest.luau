--!strict
-- One-time Edit recipe: restyle existing tall trees as dark spruce, retaining footprints.
local APPLY = false
local BACKUP = "BroadleafForestBackup_20261118"
local storage = game:GetService("ServerStorage")
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Studio Edit only")
assert(not storage:FindFirstChild(BACKUP), "Forest backup exists; inspect before restyling")
local source = storage.PlotLandscapeAssets:FindFirstChild("Spruce") :: Model
assert(source and source:IsA("Model"), "Missing prepared Spruce Model")
local mesh = source:FindFirstChildWhichIsA("MeshPart", true) :: MeshPart
assert(mesh and #source:GetDescendants() == 1, "Expected a script-free single spruce mesh")
type Stage = { old: Model, new: Model, parent: Instance, plot: string }
local stages: { Stage } = {}
local ok, reason = xpcall(function()
	for _, plot in workspace.Plots:GetChildren() do
		if not plot:IsA("Model") then
			continue
		end
		local environment = plot:FindFirstChild("Environment")
		assert(environment, "Missing Environment")
		local candidates: { Model } = {}
		for _, item in environment:GetDescendants() do
			if item:IsA("Model") and (item.Name:match("^Tree%d+$") or item.Name:match("^TallTree%d+$")) then
				table.insert(candidates, item)
			end
		end
		table.sort(candidates, function(a, b)
			return a:GetFullName() < b:GetFullName()
		end)
		assert(#candidates == 16, "Expected sixteen existing trees")
		for index, old in candidates do
			local original = old:FindFirstChildWhichIsA("BasePart", true) :: BasePart
			assert(original and #old:GetDescendants() == 1, "Expected one-part existing tree")
			local model = Instance.new("Model")
			model.Name = old.Name
			table.insert(stages, { old = old, new = model, parent = old.Parent :: Instance, plot = plot.Name })
			local part = mesh:Clone()
			-- Preserve the original oriented horizontal footprint and bottom height.
			local height = 70 + (index % 5) * 3
			part.Size = Vector3.new(original.Size.X, height, original.Size.Z)
			part.CFrame = original.CFrame * CFrame.new(0, (height - original.Size.Y) / 2, 0)
			part.Color = Color3.fromRGB(61, 88, 72) -- muted green tint multiplies the baked texture
			part.Material = Enum.Material.SmoothPlastic
			part.Reflectance = 0
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.RenderFidelity = Enum.RenderFidelity.Automatic
			part.Parent = model
			model:SetAttribute("ForestStyle", "DarkSpruce")
			assert(part.Size.X == original.Size.X and part.Size.Z == original.Size.Z, "Footprint changed")
			assert(
				(part.Position - original.Position - original.CFrame.UpVector * ((height - original.Size.Y) / 2)).Magnitude
					< 0.01,
				"Base moved"
			)
		end
	end
	assert(#stages > 0, "No trees found")
end, debug.traceback)
if not ok or not APPLY then
	for _, stage in stages do
		stage.new:Destroy()
	end
	if not ok then
		error(reason)
	end
else
	local backup = Instance.new("Folder")
	backup.Name = BACKUP
	backup.Parent = storage
	for _, stage in stages do
		local saved = backup:FindFirstChild(stage.plot)
		if not saved then
			saved = Instance.new("Folder")
			saved.Name = stage.plot
			saved.Parent = backup
		end
		stage.old:SetAttribute("RestoreParent", stage.parent:GetFullName())
		stage.old.Parent = saved
		stage.new.Parent = stage.parent
	end
end
print(
	string.format(
		"Dark spruce forest %s: %d trees; footprints and grounding preserved",
		if APPLY then "installed" else "dry run",
		#stages
	)
)
