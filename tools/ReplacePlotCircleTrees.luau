--!strict
-- One-time Edit authoring recipe. Archives original round trees; changes no gameplay.
local APPLY = false
local BACKUP = "RoundPlotTreesBackup_20261118"
local HEIGHT = 70
local run = game:GetService("RunService")
assert(run:IsStudio() and not run:IsRunning(), "Studio Edit only")
local storage = game:GetService("ServerStorage")
assert(not storage:FindFirstChild(BACKUP), "Round tree backup already exists")
local assets = storage:FindFirstChild("PlotLandscapeAssets")
local source = if assets then assets:FindFirstChild("Tree") else nil
assert(source and source:IsA("Model"), "Missing prepared Tree asset")
local sourcePart = source:FindFirstChildWhichIsA("BasePart", true)
assert(sourcePart and sourcePart:IsA("MeshPart"), "Expected single tree MeshPart")
assert(#source:GetDescendants() == 1, "Expected one script-free part")
local stages: { { plot: Model, originals: { BasePart }, trees: Folder } } = {}
local total = 0
local ok, reason = xpcall(function()
	for _, plot in workspace.Plots:GetChildren() do
		if not plot:IsA("Model") then
			continue
		end
		local environment = plot:FindFirstChild("Environment")
		assert(environment and not environment:FindFirstChild("ReplacementTrees"), "Expected unreplaced environment")
		local ground = plot:FindFirstChild("Ground") :: BasePart
		assert(ground and ground:IsA("BasePart"), "Missing Ground")
		local crowns: { BasePart } = {}
		local trunks: { BasePart } = {}
		for _, item in plot:GetChildren() do
			if item:IsA("BasePart") and item.Name == "TreeCrown" then
				table.insert(crowns, item)
			end
			if item:IsA("BasePart") and item.Name == "TreeTrunk" then
				table.insert(trunks, item)
			end
		end
		assert(#crowns == 8 and #trunks == 8, "Expected eight original round trees")
		local originals: { BasePart } = {}
		local trees = Instance.new("Folder")
		trees.Name = "ReplacementTrees"
		table.insert(stages, { plot = plot, originals = originals, trees = trees })
		local used: { [BasePart]: boolean } = {}
		for i, crown in crowns do
			assert(crown.Anchored and #crown:GetDescendants() == 0, "Unexpected crown content")
			local trunk: BasePart? = nil
			for _, candidate in trunks do
				if
					(Vector3.new(candidate.Position.X, 0, candidate.Position.Z) - Vector3.new(
						crown.Position.X,
						0,
						crown.Position.Z
					)).Magnitude < 0.01
				then
					assert(not trunk, "Ambiguous trunk pairing")
					trunk = candidate
				end
			end
			assert(trunk and not used[trunk] and trunk.Anchored and #trunk:GetDescendants() == 0, "Invalid trunk pair")
			used[trunk] = true
			table.insert(originals, crown)
			table.insert(originals, trunk)
			local model = Instance.new("Model")
			model.Name = string.format("TallTree%02d", i)
			model.Parent = trees
			local part = sourcePart:Clone()
			-- Keep horizontal bounds within the old 14-stud round canopy.
			local width = math.min(crown.Size.X, crown.Size.Z) * 0.95
			local ratio = width / math.max(part.Size.X, part.Size.Z)
			local height = HEIGHT + (i % 3 - 1) * 3
			part.Size = Vector3.new(part.Size.X * ratio, height, part.Size.Z * ratio)
			local localCrown = ground.CFrame:PointToObjectSpace(crown.Position)
			part.CFrame = ground.CFrame * CFrame.new(localCrown.X, ground.Size.Y / 2 + height / 2 - 0.1, localCrown.Z)
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Parent = model
			assert(math.abs(localCrown.X) + part.Size.X / 2 < ground.Size.X / 2, "Tree outside Ground X")
			assert(math.abs(localCrown.Z) + part.Size.Z / 2 < ground.Size.Z / 2, "Tree outside Ground Z")
			assert(part.Size.X <= crown.Size.X and part.Size.Z <= crown.Size.Z, "Canopy footprint grew")
			total += 1
		end
	end
	assert(total > 0, "No round trees found")
end, debug.traceback)
if not ok or not APPLY then
	for _, stage in stages do
		stage.trees:Destroy()
	end
	if not ok then
		error(reason)
	end
else
	local backup = Instance.new("Folder")
	backup.Name = BACKUP
	backup.Parent = storage
	for _, stage in stages do
		local saved = Instance.new("Folder")
		saved.Name = stage.plot.Name
		saved.Parent = backup
		for _, item in stage.originals do
			item.Parent = saved
		end
		stage.trees.Parent = stage.plot.Environment
	end
end
print(
	string.format(
		"Round tree replacement %s: %d tall trees; original footprints preserved",
		if APPLY then "installed" else "dry run",
		total
	)
)
