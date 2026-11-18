--!strict
-- Approved additive Edit recipe. Never replaces the shared template/vegetation.
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "Stop Play before installing")
local storage = game:GetService("ServerStorage")
local template = storage:FindFirstChild("KingdomTemplate") :: Model
assert(template ~= nil, "Missing KingdomTemplate")
local plates = template:FindFirstChild("PurchasePlates") :: Folder
local unlocks = template:FindFirstChild("PurchaseUnlocks") :: Folder
local backupName = "OptionalAdditionsBackup_20261118"
assert(not storage:FindFirstChild(backupName), "Already installed; preserve the existing backup")
local ids = { "RoyalBanners", "RoyalLanterns", "TrainingSword", "SprintTraining", "HorsePaddock", "RoyalFountain" }
for _, id in ids do
	assert(not plates:FindFirstChild(id) and not unlocks:FindFirstChild(id), "Existing asset: " .. id)
end
assert(not storage:FindFirstChild("KingdomTrainingSword"), "Sword template already exists")
local pivot = template:GetPivot()
local staged = Instance.new("Folder")
staged.Name = "OptionalAdditionsStaging"
local stone = Color3.fromRGB(106, 104, 96)
local wood = Color3.fromRGB(91, 57, 32)
local gold = Color3.fromRGB(206, 163, 63)
local blue = Color3.fromRGB(32, 65, 116)
local cream = Color3.fromRGB(224, 211, 175)
local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material?,
	rotation: CFrame?
): Part
	local p = Instance.new("Part")
	p.Name, p.Size, p.Color = name, size, color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored, p.CanTouch = true, false
	p.CFrame = pivot * CFrame.new(position) * (rotation or CFrame.identity)
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function model(id: string): Model
	local m = Instance.new("Model")
	m.Name, m.Parent = id, staged
	return m
end
local function base(m: Model, x: number, z: number, sx: number, sz: number): ()
	part(m, "Paving", Vector3.new(sx, 0.3, sz), Vector3.new(x, 0.15, z), stone, Enum.Material.Cobblestone)
end
local function lamp(m: Model, x: number, z: number): ()
	part(m, "LanternPost", Vector3.new(0.6, 7, 0.6), Vector3.new(x, 3.5, z), wood, Enum.Material.Wood)
	local glass = part(m, "Lantern", Vector3.new(1.3, 1.8, 1.3), Vector3.new(x, 7.5, z), gold, Enum.Material.Neon)
	glass.CanCollide, glass.CanQuery = false, false
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = gold, 0.7, 12, false
	light.Parent = glass
	part(m, "LanternCap", Vector3.new(1.8, 0.3, 1.8), Vector3.new(x, 8.6, z), wood)
end
local banners = model(ids[1])
base(banners, 27, -30, 14, 14)
for _, x in { 23, 31 } do
	part(banners, "BannerPole", Vector3.new(0.5, 12, 0.5), Vector3.new(x, 6, -30), wood, Enum.Material.Wood)
	part(banners, "RoyalBanner", Vector3.new(3, 5, 0.2), Vector3.new(x + 1.5, 8, -30), blue, Enum.Material.Fabric)
	part(banners, "GoldStripe", Vector3.new(0.4, 5, 0.25), Vector3.new(x + 1.5, 8, -30), gold)
end
local lanterns = model(ids[2])
base(lanterns, 27, -65, 14, 14)
lamp(lanterns, 23, -65)
lamp(lanterns, 31, -65)
local armory = model(ids[3])
base(armory, 30, 35, 20, 18)
for _, x in { 23, 37 } do
	part(armory, "RackPost", Vector3.new(1, 7, 1), Vector3.new(x, 3.8, 32), wood, Enum.Material.Wood)
end
part(armory, "RackBeam", Vector3.new(16, 1, 1), Vector3.new(30, 6.5, 32), wood, Enum.Material.Wood)
for _, x in { 26, 30, 34 } do
	part(armory, "DisplayBlade", Vector3.new(0.5, 4, 0.2), Vector3.new(x, 4.5, 31.3), cream, Enum.Material.Metal)
	part(armory, "DisplayGuard", Vector3.new(2, 0.3, 0.4), Vector3.new(x, 2.5, 31.3), gold, Enum.Material.Metal)
	part(armory, "DisplayHilt", Vector3.new(0.4, 1, 0.4), Vector3.new(x, 1.9, 31.3), wood)
end
local training = model(ids[4])
base(training, 70, 35, 20, 18)
for _, x in { 64, 76 } do
	part(training, "TrainingPost", Vector3.new(1, 5, 1), Vector3.new(x, 2.8, 33), wood, Enum.Material.Wood)
end
part(training, "TrainingRail", Vector3.new(13, 0.7, 0.7), Vector3.new(70, 3, 33), wood, Enum.Material.Wood)
part(training, "TrainingBanner", Vector3.new(3, 4, 0.2), Vector3.new(70, 5.5, 33), blue, Enum.Material.Fabric)
local paddock = model(ids[5])
base(paddock, 64, -88, 64, 40)
local function fence(x: number, z: number, alongX: boolean, length: number): ()
	local segments = math.floor(length / 8)
	for i = 0, segments do
		part(
			paddock,
			"FencePost",
			Vector3.new(0.7, 4, 0.7),
			Vector3.new(x + (if alongX then i * 8 else 0), 2.3, z + (if alongX then 0 else i * 8)),
			wood,
			Enum.Material.Wood
		)
	end
	for _, y in { 1.6, 3.3 } do
		part(
			paddock,
			"FenceRail",
			Vector3.new(if alongX then length else 0.4, 0.5, if alongX then 0.4 else length),
			Vector3.new(x + (if alongX then length / 2 else 0), y, z + (if alongX then 0 else length / 2)),
			wood,
			Enum.Material.Wood
		)
	end
end
fence(32, -108, true, 64)
fence(32, -108, false, 40)
fence(96, -108, false, 40)
fence(32, -68, true, 24)
fence(72, -68, true, 24)
-- Open shelter at rear; horses are static scenery, never Humanoids.
for _, x in { 38, 62 } do
	for _, z in { -104, -90 } do
		part(paddock, "ShelterPost", Vector3.new(1, 10, 1), Vector3.new(x, 5.3, z), wood, Enum.Material.Wood)
	end
end
part(
	paddock,
	"ShelterRoof",
	Vector3.new(29, 1, 19),
	Vector3.new(50, 11, -97),
	wood,
	Enum.Material.WoodPlanks,
	CFrame.Angles(0, 0, math.rad(-5))
)
local function horse(x: number, z: number, color: Color3): ()
	local h = Instance.new("Model")
	h.Name, h.Parent = "DecorativeHorse", paddock
	local function body(name: string, size: Vector3, offset: Vector3, tint: Color3, rotation: CFrame?): Part
		local p = part(h, name, size, Vector3.new(x, 0.3, z) + offset, tint, nil, rotation)
		p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
		return p
	end
	body("Body", Vector3.new(2.6, 2.8, 5), Vector3.new(0, 4.4, 0), color).Shape = Enum.PartType.Ball
	for _, lx in { -0.85, 0.85 } do
		for _, lz in { -1.5, 1.5 } do
			body("Leg", Vector3.new(0.6, 3.1, 0.65), Vector3.new(lx, 1.9, lz), color)
			body("Hoof", Vector3.new(0.7, 0.45, 0.85), Vector3.new(lx, 0.5, lz - 0.1), wood)
		end
	end
	body("Neck", Vector3.new(1.3, 3, 1.6), Vector3.new(0, 6, -2), color, CFrame.Angles(math.rad(-22), 0, 0))
	body("Head", Vector3.new(1.4, 1.4, 2.6), Vector3.new(0, 7.1, -3), color)
	for _, lx in { -0.45, 0.45 } do
		body("Ear", Vector3.new(0.35, 1.1, 0.5), Vector3.new(lx, 8.1, -2.4), color)
		body("Eye", Vector3.new(0.12, 0.2, 0.2), Vector3.new(lx * 1.6, 7.4, -3), Color3.new(0, 0, 0))
	end
	body("Mane", Vector3.new(0.8, 2.7, 0.4), Vector3.new(0, 6.4, -1.2), wood)
	body("Tail", Vector3.new(0.5, 3, 0.5), Vector3.new(0, 3.7, 2.6), wood, CFrame.Angles(math.rad(-15), 0, 0))
	body("Saddle", Vector3.new(2.8, 0.5, 2), Vector3.new(0, 5.8, 0), blue)
end
horse(46, -95, Color3.fromRGB(135, 86, 49))
horse(78, -89, Color3.fromRGB(190, 178, 151))
part(
	paddock,
	"HayBale",
	Vector3.new(5, 3, 4),
	Vector3.new(38, 1.8, -76),
	Color3.fromRGB(188, 158, 66),
	Enum.Material.Grass
)
part(paddock, "Trough", Vector3.new(7, 2, 3), Vector3.new(87, 1.3, -75), wood, Enum.Material.Wood)
part(
	paddock,
	"Water",
	Vector3.new(6.5, 0.2, 2.5),
	Vector3.new(87, 2.4, -75),
	Color3.fromRGB(62, 141, 174),
	Enum.Material.Glass
)
local fountain = model(ids[6])
base(fountain, 64, -20, 26, 26)
for _, spec in { { 20, 1, 0.8 }, { 15, 1.2, 1.8 }, { 5, 5, 4 }, { 11, 0.7, 6.7 }, { 2, 3, 8.5 }, { 5, 0.5, 10 } } do
	local p = part(
		fountain,
		"StoneBasin",
		Vector3.new(spec[2], spec[1], spec[1]),
		Vector3.new(64, spec[3], -20),
		stone,
		Enum.Material.Marble,
		CFrame.Angles(0, 0, math.pi / 2)
	)
	p.Shape = Enum.PartType.Cylinder
end
local water = part(
	fountain,
	"WaterSurface",
	Vector3.new(0.15, 13, 13),
	Vector3.new(64, 2.5, -20),
	Color3.fromRGB(73, 152, 183),
	Enum.Material.Glass,
	CFrame.Angles(0, 0, math.pi / 2)
)
water.Shape, water.CanCollide, water.Transparency = Enum.PartType.Cylinder, false, 0.25
-- Plates occupy the approach to each addition, never the Mint lanes.
local positions = {
	Vector3.new(15, 0.6, -30),
	Vector3.new(15, 0.6, -65),
	Vector3.new(30, 0.6, 49),
	Vector3.new(70, 0.6, 49),
	Vector3.new(64, 0.6, -60),
	Vector3.new(64, 0.6, 0),
}
local stagedPlates = Instance.new("Folder")
for i, id in ids do
	local p = part(
		stagedPlates,
		id,
		Vector3.new(0.4, 4, 4),
		positions[i],
		Color3.fromRGB(255, 45, 45),
		nil,
		CFrame.Angles(0, 0, math.pi / 2)
	)
	p.Shape, p.CanCollide, p.CanTouch = Enum.PartType.Cylinder, false, true
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Size, gui.Adornee = "PurchaseBillboard", UDim2.fromOffset(128, 40), p
	gui.StudsOffsetWorldSpace, gui.AlwaysOnTop = Vector3.new(0, 2, 0), true
	gui.Parent = p
	local label = Instance.new("TextLabel")
	label.Name, label.Size, label.BackgroundTransparency = "PurchaseLabel", UDim2.fromScale(1, 1), 1
	label.Text, label.TextColor3, label.Font, label.TextSize = id, cream, Enum.Font.GothamBold, 14
	label.Parent = gui
end
local tool = Instance.new("Tool")
tool.Name, tool.CanBeDropped, tool.RequiresHandle = "KingdomTrainingSword", false, true
tool.ToolTip = "Training sword — equip and swing"
tool.Grip = CFrame.Angles(math.pi / 2, 0, 0)
local handle = part(tool, "Handle", Vector3.new(0.35, 1.3, 0.35), Vector3.zero, wood)
local blade = part(tool, "Blade", Vector3.new(0.5, 3.6, 0.18), Vector3.new(0, 2.4, 0), cream, Enum.Material.Metal)
local guard = part(tool, "Guard", Vector3.new(1.7, 0.25, 0.4), Vector3.new(0, 0.7, 0), gold, Enum.Material.Metal)
for _, p in { handle, blade, guard } do
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.Massless = false, false, false, false, true
	if p ~= handle then
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = handle, p, handle
	end
end
-- Validate fully before additive installation. Backup is a snapshot, never swapped in.
for _, descendant in staged:GetDescendants() do
	assert(not descendant:IsA("LuaSourceContainer"), "Script in scenery")
end
local backup = Instance.new("Folder")
backup.Name = backupName
template:Clone().Parent = backup
backup.Parent = storage
for _, m in staged:GetChildren() do
	m.Parent = unlocks
end
for _, p in stagedPlates:GetChildren() do
	p.Parent = plates
end
tool.Parent = storage
staged:Destroy()
stagedPlates:Destroy()
local reservations = template:FindFirstChild("LayoutReservations")
if reservations then
	reservations:SetAttribute("OptionalAdditionsMin", Vector3.new(8, 0, -110))
	reservations:SetAttribute("OptionalAdditionsMax", Vector3.new(100, 12, 60))
end
print("Installed six optional additions; original snapshot retained in " .. backupName)
