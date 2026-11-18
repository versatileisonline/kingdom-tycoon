--!strict
-- Approved one-time Edit revision. Replace only task-owned models/plates; archive originals.
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Studio Edit only")
local storage = game:GetService("ServerStorage")
local template = storage.KingdomTemplate
local unlocks = template.PurchaseUnlocks
local plates = template.PurchasePlates
local backupName = "MedievalCourtyardBackup_20261118"
assert(not storage:FindFirstChild(backupName), "Already installed; preserve backup")
local horseSource = storage:FindFirstChild("MedievalHorseTemplate") :: Model
assert(horseSource and horseSource:IsA("Model"), "Prepare approved MedievalHorseTemplate first")
local origin = template:GetPivot()
local staged = Instance.new("Folder")
local backup = Instance.new("Folder")
backup.Name = backupName
local wood = Color3.fromRGB(87, 56, 35)
local spruce = Color3.fromRGB(75, 57, 36)
local gold = Color3.fromRGB(215, 171, 69)
local hay = Color3.fromRGB(191, 154, 65)
local stone = Color3.fromRGB(115, 110, 101)
local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	x: number,
	y: number,
	z: number,
	color: Color3,
	material: Enum.Material?,
	rotation: CFrame?
): Part
	local p = Instance.new("Part")
	p.Name, p.Size, p.Color = name, size, color
	p.Material = material or Enum.Material.Wood
	p.Anchored, p.CanTouch = true, false
	p.CFrame = origin * CFrame.new(x, y, z) * (rotation or CFrame.identity)
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function model(name: string, x: number, z: number): Model
	local m = Instance.new("Model")
	m.Name, m.Parent = name, staged
	local root = part(m, "Origin", Vector3.one, x, 0, z, wood)
	root.Transparency, root.CanCollide, root.CanQuery = 1, false, false
	m.PrimaryPart = root
	return m
end
local function sign(m: Model, name: string, text: string, x: number, y: number, z: number, width: number): ()
	local board = part(m, name, Vector3.new(width, 1.8, 0.45), x, y, z, wood)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.CanvasSize, gui.Parent = Enum.NormalId.Back, Vector2.new(600, 90), board
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Text, label.Font, label.TextColor3, label.TextScaled = text, Enum.Font.GothamBold, gold, true
	label.Parent = gui
end
local function bale(m: Model, x: number, y: number, z: number): ()
	part(m, "HayBale", Vector3.new(4.5, 2.4, 3.4), x, y, z, hay, Enum.Material.Grass)
	for _, dx in { -1.2, 1.2 } do
		part(m, "BaleBinding", Vector3.new(0.16, 2.5, 3.5), x + dx, y, z, wood, Enum.Material.Fabric)
	end
end
local stand = model("TrainingSword", 30, 35)
part(stand, "StoneFooting", Vector3.new(24, 0.3, 18), 30, 0.15, 35, stone, Enum.Material.Cobblestone)
part(stand, "CounterFront", Vector3.new(19, 3.3, 1), 30, 1.95, 37, wood, Enum.Material.WoodPlanks)
part(stand, "CounterTop", Vector3.new(21, 0.6, 5), 30, 3.9, 36, wood, Enum.Material.WoodPlanks)
for _, x in { 20, 40 } do
	part(stand, "SidePost", Vector3.new(1, 12, 1), x, 6.3, 34, wood)
	part(stand, "PostCap", Vector3.new(1.5, 0.5, 1.5), x, 12.5, 34, gold, Enum.Material.Metal)
end
sign(stand, "SwordStandSign", "Sword Stand", 30, 10.5, 34, 21)
for _, x in { 25, 30, 35 } do
	part(
		stand,
		"DisplayBlade",
		Vector3.new(0.45, 3.6, 0.18),
		x,
		4.3,
		35.5,
		Color3.fromRGB(186, 194, 196),
		Enum.Material.Metal,
		CFrame.Angles(math.pi / 2, 0, 0)
	)
	part(stand, "DisplayGuard", Vector3.new(1.6, 0.2, 0.4), x, 4.3, 37.3, gold, Enum.Material.Metal)
	part(stand, "DisplayHilt", Vector3.new(0.35, 0.35, 1.2), x, 4.3, 38, wood)
end
local vendor = template.StarterFarm.Scenery.Farmer:Clone()
vendor.Name = "FarmerVendor"
vendor:PivotTo(origin * CFrame.new(30, 3, 30) * CFrame.Angles(0, math.pi, 0))
local box, vendorSize = vendor:GetBoundingBox()
vendor:PivotTo(vendor:GetPivot() + Vector3.new(0, origin.Position.Y + 0.3 - (box.Position.Y - vendorSize.Y / 2), 0))
for _, v in vendor:GetDescendants() do
	if v:IsA("LuaSourceContainer") then
		v:Destroy()
	elseif v:IsA("BasePart") then
		v.Anchored, v.CanCollide, v.CanTouch, v.CanQuery = true, false, false, false
	end
end
vendor.Parent = stand

local paddock = unlocks.HorsePaddock:Clone()
paddock.Parent = staged
for _, child in paddock:GetChildren() do
	if
		child.Name == "DecorativeHorse"
		or child.Name == "HayBale"
		or child.Name == "Trough"
		or child.Name == "Water"
	then
		child:Destroy()
	end
end
for i, pos in { Vector3.new(46, 0, -96), Vector3.new(77, 0, -91) } do
	local h = horseSource:Clone()
	h.Name = "DecorativeHorse" .. i
	local _, s = h:GetBoundingBox()
	h:ScaleTo(h:GetScale() * 7.5 / s.Y)
	h:PivotTo(origin * CFrame.new(pos) * CFrame.Angles(0, if i == 1 then math.rad(25) else math.rad(-35), 0))
	local cf, sz = h:GetBoundingBox()
	h:PivotTo(h:GetPivot() + Vector3.new(0, origin.Position.Y + 0.3 - (cf.Position.Y - sz.Y / 2), 0))
	for _, v in h:GetDescendants() do
		if v:IsA("LuaSourceContainer") then
			v:Destroy()
		elseif v:IsA("BasePart") then
			v.Anchored, v.CanCollide, v.CanTouch, v.CanQuery = true, false, false, false
		end
	end
	h.Parent = paddock
end
for _, pos in
	{
		Vector3.new(37, 1.5, -77),
		Vector3.new(42, 1.5, -77),
		Vector3.new(39.5, 3.9, -77),
		Vector3.new(89, 1.5, -100),
		Vector3.new(89, 1.5, -96),
		Vector3.new(89, 3.9, -98),
	}
do
	bale(paddock, pos.X, pos.Y, pos.Z)
end
part(paddock, "TroughBottom", Vector3.new(8, 0.5, 4), 84, 0.7, -76, wood)
for _, x in { 80, 88 } do
	part(paddock, "TroughEnd", Vector3.new(0.5, 2, 4), x, 1.5, -76, wood)
end
for _, z in { -78, -74 } do
	part(paddock, "TroughSide", Vector3.new(8, 2, 0.4), 84, 1.5, z, wood, Enum.Material.WoodPlanks)
end
local water =
	part(paddock, "Water", Vector3.new(7.5, 0.15, 3.5), 84, 2, -76, Color3.fromRGB(71, 148, 173), Enum.Material.Glass)
water.CanCollide, water.Transparency = false, 0.25
for _, x in { 52, 58 } do
	part(paddock, "FeedBox", Vector3.new(3, 1.3, 3), x, 0.95, -103, wood)
end

local fountain = unlocks.RoyalFountain:Clone()
fountain.Parent = staged
fountain:PivotTo(fountain:GetPivot() + origin:VectorToWorldSpace(Vector3.new(10, -0, -32) - Vector3.new(64, 0, -20)))
-- Preserve the fountain geometry; surround it with a cohesive small plaza.
part(fountain, "Plaza", Vector3.new(36, 0.25, 36), 10, 0.12, -32, stone, Enum.Material.Cobblestone)
for _, x in { -4, 24 } do
	part(fountain, "BenchSeat", Vector3.new(3, 0.5, 10), x, 2, -32, wood, Enum.Material.WoodPlanks)
	for _, z in { -35.5, -28.5 } do
		part(fountain, "BenchLeg", Vector3.new(1, 1.8, 1), x, 1, z, wood)
	end
	part(
		fountain,
		"BenchBack",
		Vector3.new(0.5, 2.5, 10),
		x + (if x < 10 then -1.5 else 1.5),
		3,
		-32,
		wood,
		Enum.Material.WoodPlanks
	)
end
for _, x in { -3, 23 } do
	for _, z in { -45, -19 } do
		part(fountain, "Planter", Vector3.new(3, 1.8, 3), x, 1, z, wood, Enum.Material.WoodPlanks)
		for n = 1, 3 do
			local leaf = part(
				fountain,
				"Flowers",
				Vector3.new(0.8, 0.8, 0.8),
				x + (n - 2) * 0.6,
				2.2,
				z,
				if n == 2 then gold else Color3.fromRGB(98, 128, 65),
				Enum.Material.Grass
			)
			leaf.Shape, leaf.CanCollide = Enum.PartType.Ball, false
		end
	end
end
local banners = unlocks.RoyalBanners:Clone()
banners:PivotTo(banners:GetPivot() + origin:VectorToWorldSpace(Vector3.new(13, 0, 22)))
banners.Parent = staged

local course = model("SprintTraining", 70, 35)
course:SetAttribute("FallRootY", 4.2)
part(course, "PracticeGround", Vector3.new(32, 0.2, 40), 70, 0.1, 35, Color3.fromRGB(113, 92, 62), Enum.Material.Ground)
for _, x in { 54, 86 } do
	part(course, "TimberEdging", Vector3.new(0.6, 0.6, 40), x, 0.4, 35, spruce)
end
for _, z in { 15, 55 } do
	part(course, "TimberEdging", Vector3.new(32, 0.6, 0.6), 70, 0.4, z, spruce)
end
local function platform(name: string, x: number, z: number, top: number, sx: number, sz: number): ()
	part(course, name, Vector3.new(sx, 0.5, sz), x, top - 0.25, z, wood, Enum.Material.WoodPlanks)
	for _, dx in { -sx / 2 + 0.4, sx / 2 - 0.4 } do
		part(course, "PlatformSupport", Vector3.new(0.6, top - 0.5, 0.6), x + dx, (top - 0.5) / 2, z, spruce)
	end
end
platform("StartPlatform", 64, 49, 2, 7, 6)
for _, spec in { { 64, 42, 2.7 }, { 64, 35, 3.7 }, { 64, 28, 2.7 } } do
	bale(course, spec[1], spec[3] - 1.2, spec[2])
end
platform("HayCheckpoint", 64, 23, 3, 6, 6)
-- Spruce firewood crossing: rounded logs with visible cut ends.
for _, x in { 68, 72 } do
	local log = part(course, "SpruceLog", Vector3.new(5, 2, 2), x, 2.5, 23, spruce, Enum.Material.Wood)
	log.Shape = Enum.PartType.Cylinder
	for _, dx in { -2.51, 2.51 } do
		local cut = part(course, "CutWood", Vector3.new(0.04, 1.7, 1.7), x + dx, 2.5, 23, Color3.fromRGB(177, 142, 91))
		cut.Shape = Enum.PartType.Cylinder
	end
end
platform("WoodCheckpoint", 76, 23, 3, 6, 6)
platform("BalanceBeam", 76, 31, 3.3, 1.5, 10)
platform("PlankStep", 76, 39, 4, 5, 4)
platform("PlankCheckpoint", 76, 44, 3, 6, 5)
platform("FinishPlatform", 76, 51, 2, 7, 5)
for _, pos in { Vector3.new(81, 1.5, 18), Vector3.new(81, 1.5, 21), Vector3.new(81, 2.8, 19.5) } do
	local log = part(course, "StoredSpruce", Vector3.new(5, 1.3, 1.3), pos.X, pos.Y, pos.Z, spruce)
	log.Shape = Enum.PartType.Cylinder
end
local barrel =
	part(course, "WaterBarrel", Vector3.new(3, 2.5, 2.5), 58, 1.6, 19, wood, nil, CFrame.Angles(0, 0, math.pi / 2))
barrel.Shape = Enum.PartType.Cylinder
sign(course, "TrainingSign", "Medieval Practice", 70, 8, 16, 19)
for _, x in { 60, 80 } do
	part(course, "PennantPost", Vector3.new(0.4, 7, 0.4), x, 3.5, 52, wood)
	part(
		course,
		"Pennant",
		Vector3.new(2, 3, 0.2),
		x + 1,
		5.5,
		52,
		if x == 60 then Color3.fromRGB(40, 91, 143) else gold,
		Enum.Material.Fabric
	)
end
local zones = Instance.new("Folder")
zones.Name, zones.Parent = "CourseZones", course
local function zone(name: string, x: number, y: number, z: number, size: Vector3, turn: boolean?): ()
	local p = part(zones, name, size, x, y, z, wood, nil, if turn then CFrame.Angles(0, math.pi, 0) else nil)
	p.Transparency, p.CanCollide, p.CanTouch, p.CanQuery = 1, false, false, false
end
zone("Bounds", 70, 10, 35, Vector3.new(34, 24, 46))
zone("Start", 64, 4, 49, Vector3.new(6, 4, 5))
zone("Checkpoint1", 64, 5, 23, Vector3.new(6, 4, 6))
zone("Checkpoint2", 76, 5, 23, Vector3.new(6, 4, 6), true)
zone("Checkpoint3", 76, 5, 44, Vector3.new(6, 4, 5), true)
zone("Finish", 76, 4, 51, Vector3.new(6, 4, 4), true)

-- Validate all replacements before touching installed assets.
for _, m in staged:GetChildren() do
	assert(unlocks:FindFirstChild(m.Name), "Missing original " .. m.Name)
	for _, v in m:GetDescendants() do
		assert(not v:IsA("LuaSourceContainer"), "Script in scenery")
		if v:IsA("BasePart") then
			assert(v.Anchored, "Unanchored scenery")
		end
	end
end
backup.Parent = storage
for _, m in staged:GetChildren() do
	unlocks[m.Name].Parent = backup
	m.Parent = unlocks
end
staged:Destroy()
for id, position in
	{
		RoyalFountain = Vector3.new(10, 0.6, -9),
		RoyalBanners = Vector3.new(28, 0.6, -8),
		SprintTraining = Vector3.new(70, 0.6, 61),
	}
do
	local p = plates[id] :: BasePart
	local clone = p:Clone()
	clone.Parent = backup
	local destination = origin:PointToWorldSpace(position)
	local delta = destination - p.Position
	p.CFrame += delta
	for _, v in p:GetDescendants() do
		if v:IsA("BasePart") then
			v.CFrame += delta
		end
	end
end
storage.KingdomTrainingSword:Clone().Parent = backup
storage.KingdomTrainingSword.Grip = CFrame.identity
print("Medieval courtyard asset checks passed (stand, farmer, horses, plaza and obby)")
