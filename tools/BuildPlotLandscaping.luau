--!strict
-- One-time Studio authoring recipe. Not Rojo mapped; never runs in published servers.
-- Set APPLY=true only after reviewing the dry-run result.
local APPLY = false
local REVISE_TREES_ONLY = false
local TREE_BACKUP = "PlotTreePlacementBackup_20261118"
local SEED = 18112026
local CLEARANCE = 6
local run = game:GetService("RunService")
assert(run:IsStudio() and not run:IsRunning(), "Landscaping requires Studio Edit mode")
local assets = game:GetService("ServerStorage"):FindFirstChild("PlotLandscapeAssets")
assert(assets, "Missing ServerStorage.PlotLandscapeAssets")
local template = game:GetService("ServerStorage"):FindFirstChild("KingdomTemplate") :: Model
assert(template and template:IsA("Model"), "Missing KingdomTemplate")
if REVISE_TREES_ONLY and APPLY then
	assert(not game.ServerStorage:FindFirstChild(TREE_BACKUP), "Tree backup already exists; inspect before revising")
end
local plots = workspace:FindFirstChild("Plots")
assert(plots, "Missing Plots")
type Rect = { x: number, z: number, hx: number, hz: number }
local function bounds(model: Model, frame: CFrame): Rect
	local cf, size = model:GetBoundingBox()
	local loX, loZ, hiX, hiZ = math.huge, math.huge, -math.huge, -math.huge
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				local p = frame:PointToObjectSpace(cf:PointToWorldSpace(size * Vector3.new(x, y, z) / 2))
				loX, loZ = math.min(loX, p.X), math.min(loZ, p.Z)
				hiX, hiZ = math.max(hiX, p.X), math.max(hiZ, p.Z)
			end
		end
	end
	return { x = (loX + hiX) / 2, z = (loZ + hiZ) / 2, hx = (hiX - loX) / 2, hz = (hiZ - loZ) / 2 }
end
local function overlaps(a: Rect, b: Rect, gap: number): boolean
	return math.abs(a.x - b.x) < a.hx + b.hx + gap and math.abs(a.z - b.z) < a.hz + b.hz + gap
end
-- Reserve the entire interior even before any walls or machinery are purchased.
local reservations = template:FindFirstChild("LayoutReservations")
assert(reservations, "Missing LayoutReservations")
assert(
	reservations:GetAttribute("WallCenter") == Vector3.new(0, 0, -32)
		and reservations:GetAttribute("WallFootprint") == Vector3.new(216, 0, 216),
	"Wall reservation changed; review landscaping masks"
)
local masks: { Rect } = { { x = 0, z = -32, hx = 108, hz = 108 } }
local templateFrame = template:GetPivot()
for _, name in { "StarterFarm", "Paths" } do
	local model = template:FindFirstChild(name) :: Model
	assert(model and model:IsA("Model"), "Missing reservation " .. name)
	table.insert(masks, bounds(model, templateFrame))
end
-- Include all configured plates and future models, not just currently visible ones.
for _, name in { "PurchasePlates", "PurchaseUnlocks" } do
	local folder = template:FindFirstChild(name)
	assert(folder, "Missing " .. name)
	for _, item in folder:GetChildren() do
		if item:IsA("Model") then
			table.insert(masks, bounds(item, templateFrame))
		elseif item:IsA("BasePart") then
			local p = templateFrame:PointToObjectSpace(item.Position)
			local radius = item.Size.Magnitude / 2
			table.insert(masks, { x = p.X, z = p.Z, hx = radius, hz = radius })
		end
	end
end
-- Wide clear entrance corridor includes claim/start guidance, owner sign and spawn.
table.insert(masks, { x = 0, z = 125, hx = 28, hz = 49 })
local specs = {
	{ name = "Grass", count = 250, min = 0.7, max = 1.3 },
	{ name = "Fern", count = 40, min = 0.7, max = 1.25 },
	{ name = "Rock", count = 20, min = 0.6, max = 1.4 },
}
for _, name in { "Grass", "Fern", "Rock", "Tree" } do
	local source = assets:FindFirstChild(name)
	assert(source and source:IsA("Model"), "Missing prepared asset " .. name)
	local parts = 0
	for _, d in source:GetDescendants() do
		assert(not d:IsA("LuaSourceContainer"), "Script in asset " .. name)
		if d:IsA("BasePart") then
			parts += 1
			assert(d.Anchored and not d.CanCollide and not d.CanTouch and not d.CanQuery, "Unsafe asset " .. name)
		end
	end
	assert(parts > 0 and parts <= 4, "Asset must contain 1-4 parts: " .. name)
end
local stages: { { plot: Model, environment: Folder } } = {}
local totals = { Grass = 0, Fern = 0, Rock = 0, Tree = 0 }
local ok, reason = xpcall(function()
	for _, plot in plots:GetChildren() do
		if not plot:IsA("Model") then
			continue
		end
		if REVISE_TREES_ONLY then
			local current = plot:FindFirstChild("Environment")
			assert(current and current:GetAttribute("LandscapeVersion") == 1, "Expected original landscaping")
			for i = 1, 8 do
				assert(current:FindFirstChild(string.format("Tree%02d", i)), "Missing original tree")
			end
		else
			assert(not plot:FindFirstChild("Environment"), "Environment already exists: " .. plot.Name)
		end
		local origin = plot:FindFirstChild("Origin") :: BasePart
		local ground = plot:FindFirstChild("Ground") :: BasePart
		assert(origin and ground, "Missing plot origin/ground")
		assert(math.abs(ground.Size.X - 320) < 0.01 and math.abs(ground.Size.Z - 320) < 0.01, "Expected 320x320 plot")
		local frame = origin.CFrame
		local relative = frame:ToObjectSpace(ground.CFrame)
		assert(
			math.abs(relative.Position.X) < 0.01
				and math.abs(relative.Position.Z) < 0.01
				and (relative.RightVector - Vector3.xAxis).Magnitude < 0.01
				and (relative.UpVector - Vector3.yAxis).Magnitude < 0.01,
			"Ground must be centered and aligned with Origin"
		)
		local environment = Instance.new("Folder")
		environment.Name = "Environment"
		environment:SetAttribute("LandscapeVersion", 2)
		environment:SetAttribute("Seed", SEED)
		table.insert(stages, { plot = plot, environment = environment })
		local rng = Random.new(SEED)
		local function make(name: string, scale: number, p: Vector3): Model
			local model = (assets:FindFirstChild(name) :: Model):Clone()
			if name == "Tree" then
				local part = model:FindFirstChildWhichIsA("BasePart", true) :: BasePart
				local width = 24 * scale / math.max(part.Size.X, part.Size.Z)
				part.Size = Vector3.new(part.Size.X * width, 72 * scale, part.Size.Z * width)
				local cf, size = model:GetBoundingBox()
				model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
			else
				model:ScaleTo(model:GetScale() * scale)
			end
			model:PivotTo(frame * CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0))
			return model
		end
		local top = frame:PointToObjectSpace(ground.Position + ground.CFrame.UpVector * ground.Size.Y / 2).Y
		for _, spec in specs do
			local accepted = 0
			for _ = 1, 12000 do
				if accepted == spec.count then
					break
				end
				local x, z = rng:NextNumber(-154, 154), rng:NextNumber(-154, 154)
				-- Uneven, repeatable patches rather than a uniform lawn.
				if math.noise(x / 24, z / 24, SEED / 1000) < -0.1 then
					continue
				end
				local model = make(spec.name, rng:NextNumber(spec.min, spec.max), Vector3.new(x, top - 0.08, z))
				local rect = bounds(model, frame)
				local safe = math.abs(rect.x) + rect.hx <= 158 and math.abs(rect.z) + rect.hz <= 158
				for _, mask in masks do
					if overlaps(rect, mask, CLEARANCE) then
						safe = false
						break
					end
				end
				if safe then
					accepted += 1
					model.Name = string.format("%s%03d", spec.name, accepted)
					model.Parent = environment
				else
					model:Destroy()
				end
			end
			assert(accepted == spec.count, "Insufficient clear ground for " .. spec.name)
			totals[spec.name] += accepted
		end
		local locations = {
			{ -137, -108 },
			{ -137, -25 },
			{ -137, 25 },
			{ -137, 70 },
			{ 137, -108 },
			{ 137, -25 },
			{ 137, 25 },
			{ 137, 70 },
		}
		for index, location in locations do
			local model = make("Tree", rng:NextNumber(0.95, 1.05), Vector3.new(location[1], top - 0.1, location[2]))
			model.Parent = environment
			local rect = bounds(model, frame)
			assert(math.abs(rect.x) + rect.hx <= 158 and math.abs(rect.z) + rect.hz <= 158, "Tree outside plate")
			for _, mask in masks do
				assert(not overlaps(rect, mask, CLEARANCE), "Tree overlaps gameplay reservation")
			end
			model.Name = string.format("Tree%02d", index)
			totals.Tree += 1
		end
	end
	assert(#stages > 0, "No plots found")
end, debug.traceback)
if not ok or not APPLY then
	for _, stage in stages do
		stage.environment:Destroy()
	end
	if not ok then
		error(reason)
	end
elseif REVISE_TREES_ONLY then
	local backup = Instance.new("Folder")
	backup.Name = TREE_BACKUP
	backup.Parent = game.ServerStorage
	for _, stage in stages do
		local current = stage.plot.Environment
		local saved = Instance.new("Folder")
		saved.Name = stage.plot.Name
		saved.Parent = backup
		for i = 1, 8 do
			local name = string.format("Tree%02d", i)
			current[name].Parent = saved
			stage.environment[name].Parent = current
		end
		current:SetAttribute("LandscapeVersion", 2)
		stage.environment:Destroy()
	end
else
	for _, stage in stages do
		stage.environment.Parent = stage.plot
	end
end
print(
	string.format(
		"Landscaping %s: %d plots; %d grass, %d ferns, %d rocks, %d trees; clearance checks passed",
		if not APPLY then "dry run" elseif REVISE_TREES_ONLY then "trees revised" else "installed",
		#stages,
		totals.Grass,
		totals.Fern,
		totals.Rock,
		totals.Tree
	)
)
