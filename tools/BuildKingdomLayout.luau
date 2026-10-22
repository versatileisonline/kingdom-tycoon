--!strict
-- Approved one-time Edit-mode layout revision. Not Rojo-mapped or run in-game.
-- Original map, plots, kingdom, and bundle are archived without deleting assets.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Studio Edit mode only")
local BACKUP_NAME = "KingdomLayoutBackup_20261021"
assert(ServerStorage:FindFirstChild(BACKUP_NAME) == nil, "Layout backup exists; refusing a second run")
local oldMap = workspace:FindFirstChild("KingdomMap")
local oldPlots = workspace:FindFirstChild("Plots")
local active = workspace:FindFirstChild("ActiveKingdoms")
local source = workspace:FindFirstChild("KingdomTemplate") or ServerStorage:FindFirstChild("KingdomTemplate")
local oldBundle = ServerStorage:FindFirstChild("WheatBundle")
assert(oldMap ~= nil and oldPlots ~= nil, "Existing map and plots required")
assert(active ~= nil and #active:GetChildren() == 0, "ActiveKingdoms must be empty")
assert(source ~= nil and source:IsA("Model"), "Existing KingdomTemplate required")
assert(oldBundle ~= nil and oldBundle:IsA("BasePart"), "Existing WheatBundle required")
local meadow = oldMap:FindFirstChild("Meadow")
local rock = oldMap:FindFirstChild("PlateauRock")
local oldFarm = source:FindFirstChild("StarterFarm")
assert(meadow ~= nil and meadow:IsA("BasePart"), "Existing Meadow required")
assert(rock ~= nil and rock:IsA("BasePart"), "Existing PlateauRock required")
assert(oldFarm ~= nil and oldFarm:IsA("Model"), "Existing StarterFarm required")
assert(math.abs(meadow.Size.X - 320) < 0.01 and math.abs(meadow.Size.Z - 320) < 0.01, "Expected 320-stud meadow")
local center = CFrame.new(meadow.Position + Vector3.new(0, meadow.Size.Y / 2, 0))
local wood = Color3.fromRGB(101, 69, 43)
local pathColor = Color3.fromRGB(173, 157, 119)
local grass = Color3.fromRGB(109, 135, 75)

local function model(name: string, parent: Instance?): Model
	local result = Instance.new("Model")
	result.Name = name
	result.Parent = parent
	return result
end

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material
): Part
	local result = Instance.new("Part")
	result.Name = name
	result.Size = size
	result.CFrame = CFrame.new(position)
	result.Anchored = true
	result.Color = color
	result.Material = material
	result.TopSurface = Enum.SurfaceType.Smooth
	result.BottomSurface = Enum.SurfaceType.Smooth
	result.Parent = parent
	return result
end

local function label(parent: BasePart, name: string, text: string, offset: number): ()
	local gui = Instance.new("BillboardGui")
	gui.Name = name .. "Gui"
	gui.Size = UDim2.fromOffset(290, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offset, 0)
	gui.MaxDistance = 110
	gui.AlwaysOnTop = true
	gui.Parent = parent
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = name
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundColor3 = Color3.fromRGB(30, 37, 28)
	textLabel.BackgroundTransparency = 0.15
	textLabel.TextColor3 = Color3.fromRGB(255, 230, 161)
	textLabel.TextSize = 20
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextWrapped = true
	textLabel.Text = text
	textLabel.Parent = gui
end

local function spawn(parent: Instance, name: string, position: Vector3): SpawnLocation
	local result = Instance.new("SpawnLocation")
	result.Name = name
	result.Size = Vector3.new(8, 0.3, 8)
	result.CFrame = center * CFrame.new(position) -- Faces -Z, toward the future gate.
	result.Anchored = true
	result.Transparency = 1
	result.CanCollide = false
	result.CanTouch = false
	result.Enabled = true
	result.Neutral = true
	result.AllowTeamChangeOnTouch = false
	result.Duration = 5
	result.Parent = parent
	return result
end

-- Build replacement assets off the DataModel before archiving the originals.
local newMap = model("KingdomMap", nil)
local bridge = part(
	newMap,
	"ArrivalApproach",
	Vector3.new(28, 2, 40),
	Vector3.new(0, -1, 180),
	pathColor,
	Enum.Material.Cobblestone
)
bridge.CFrame = center * bridge.CFrame
spawn(newMap, "ArrivalSpawn", Vector3.new(0, 0.3, 184))
local newPlots = Instance.new("Folder")
newPlots.Name = "Plots"
local plot = model("Plot01", newPlots)
plot:SetAttribute("PlotId", "Plot01")
plot:SetAttribute("PlotSize", Vector3.new(320, 0, 320))
local ground = meadow:Clone()
ground.Name = "Ground"
ground.Parent = plot
rock:Clone().Parent = plot
for _, child in oldMap:GetChildren() do
	if child.Name == "TreeTrunk" or child.Name == "TreeCrown" then
		child:Clone().Parent = plot
	end
end
local origin = part(plot, "Origin", Vector3.one, Vector3.zero, grass, Enum.Material.SmoothPlastic)
origin.CFrame = center
origin.Transparency = 1
origin.CanCollide = false
origin.CanTouch = false
origin.CanQuery = false
plot.PrimaryPart = origin
local claim =
	part(plot, "ClaimMarker", Vector3.new(12, 0.6, 10), Vector3.zero, Color3.fromRGB(213, 173, 63), Enum.Material.Metal)
claim.CFrame = center * CFrame.new(0, 0.4, 148)
label(claim, "ClaimLabel", "CLAIM KINGDOM — FREE", 5)

local kingdom = model("KingdomTemplate", nil)
kingdom:SetAttribute("AssetVersion", 2)
local root = part(kingdom, "TemplateRoot", Vector3.one, Vector3.zero, grass, Enum.Material.SmoothPlastic)
root.Transparency = 1
root.CanCollide = false
root.CanTouch = false
root.CanQuery = false
kingdom.PrimaryPart = root
local paths = model("Paths", kingdom)
part(paths, "EntrancePath", Vector3.new(16, 0.2, 84), Vector3.new(0, 0.12, 118), pathColor, Enum.Material.Pebble)
part(paths, "FarmBranch", Vector3.new(24, 0.2, 10), Vector3.new(-12, 0.12, 118), pathColor, Enum.Material.Pebble)
local start = part(
	kingdom,
	"FarmStartPlate",
	Vector3.new(10, 0.6, 10),
	Vector3.new(-16, 0.4, 118),
	Color3.fromRGB(92, 158, 74),
	Enum.Material.SmoothPlastic
)
label(start, "StartLabel", "START FARM — FREE", 5)
local sign = part(kingdom, "OwnerSign", Vector3.new(8, 5, 0.6), Vector3.new(15, 5, 146), wood, Enum.Material.WoodPlanks)
part(kingdom, "SignPost", Vector3.new(0.7, 6, 0.7), Vector3.new(15, 3, 146), wood, Enum.Material.Wood)
label(sign, "OwnerLabel", "YOUR KINGDOM", 4)

-- Metadata reserves the full future wall footprint, with no walls/interior built.
local layout = Instance.new("Folder")
layout.Name = "LayoutReservations"
layout:SetAttribute("WallCenter", Vector3.new(0, 0, -32))
layout:SetAttribute("WallFootprint", Vector3.new(216, 0, 216))
layout:SetAttribute("GateCenter", Vector3.new(0, 0, 76))
layout:SetAttribute("GateWidth", 24)
layout:SetAttribute("FarmCenter", Vector3.new(-80, 0, 124))
layout:SetAttribute("FarmFootprint", Vector3.new(112, 0, 48))
layout.Parent = kingdom

local farm = oldFarm:Clone()
local foundation = farm:FindFirstChild("FarmFoundation")
local belt = farm:FindFirstChild("Conveyor")
local collect = farm:FindFirstChild("CollectPlate")
assert(foundation ~= nil and foundation:IsA("BasePart"), "FarmFoundation required")
assert(belt ~= nil and belt:IsA("BasePart"), "Conveyor required")
assert(collect ~= nil and collect:IsA("BasePart"), "CollectPlate required")
local target = CFrame.new(-40, foundation.Size.Y / 2 + 0.15, 124)
farm:PivotTo(target * foundation.CFrame:Inverse() * farm:GetPivot())
collect.Size = Vector3.new(8, collect.Size.Y, 8)
farm.Parent = kingdom
local scenery = model("Scenery", farm)
part(
	scenery,
	"FarmGround",
	Vector3.new(112, 0.12, 48),
	Vector3.new(-80, 0.07, 124),
	Color3.fromRGB(128, 138, 77),
	Enum.Material.Ground
)

for _, fieldX in { -116, -84 } do
	local field = model("CropField", scenery)
	part(
		field,
		"Soil",
		Vector3.new(24, 0.3, 20),
		Vector3.new(fieldX, 0.25, 112),
		Color3.fromRGB(85, 65, 39),
		Enum.Material.Ground
	)
	for row = 1, 5 do
		for column = 1, 6 do
			local pos = Vector3.new(fieldX - 10 + (column - 1) * 4, 1.6, 104 + (row - 1) * 4)
			local stalk = part(
				field,
				"WheatStalk",
				Vector3.new(0.18, 2.5, 0.18),
				pos,
				Color3.fromRGB(176, 153, 67),
				Enum.Material.Grass
			)
			stalk.CanCollide = false
			local ear = part(
				field,
				"WheatHead",
				Vector3.new(0.55, 1.1, 0.45),
				pos + Vector3.new(0, 1.1, 0),
				Color3.fromRGB(225, 190, 88),
				Enum.Material.Grass
			)
			ear.CanCollide = false
		end
	end
end

local shed = model("Shed", scenery)
part(shed, "Floor", Vector3.new(20, 0.3, 16), Vector3.new(-116, 0.3, 136), wood, Enum.Material.WoodPlanks)
for _, x in { -125, -107 } do
	for _, z in { 129, 143 } do
		part(shed, "Post", Vector3.new(0.8, 8, 0.8), Vector3.new(x, 4.4, z), wood, Enum.Material.Wood)
	end
end
part(
	shed,
	"Roof",
	Vector3.new(22, 0.8, 18),
	Vector3.new(-116, 8.8, 136),
	Color3.fromRGB(76, 86, 68),
	Enum.Material.WoodPlanks
)

-- Static farmer scenery: no Humanoid, pathfinding, or per-frame server work.
local farmer = model("Farmer", scenery)
local farmerOrigin = Vector3.new(-56, 0.2, 124)
for _, legX in { -0.5, 0.5 } do
	part(
		farmer,
		"Leg",
		Vector3.new(0.8, 2, 0.9),
		farmerOrigin + Vector3.new(legX, 1, 0),
		Color3.fromRGB(67, 64, 50),
		Enum.Material.SmoothPlastic
	)
end
part(
	farmer,
	"Torso",
	Vector3.new(2, 2, 1),
	farmerOrigin + Vector3.new(0, 3, 0),
	Color3.fromRGB(111, 130, 72),
	Enum.Material.Fabric
)
for _, armX in { -1.5, 1.5 } do
	part(
		farmer,
		"Arm",
		Vector3.new(0.8, 2, 0.8),
		farmerOrigin + Vector3.new(armX, 3, 0),
		Color3.fromRGB(189, 146, 102),
		Enum.Material.SmoothPlastic
	)
end
part(
	farmer,
	"Head",
	Vector3.new(1.4, 1.4, 1.4),
	farmerOrigin + Vector3.new(0, 4.7, 0),
	Color3.fromRGB(202, 163, 119),
	Enum.Material.SmoothPlastic
)
part(
	farmer,
	"HatBrim",
	Vector3.new(2.4, 0.2, 2),
	farmerOrigin + Vector3.new(0, 5.4, 0),
	Color3.fromRGB(191, 161, 83),
	Enum.Material.Fabric
)
part(
	farmer,
	"HatCrown",
	Vector3.new(1.5, 0.7, 1.4),
	farmerOrigin + Vector3.new(0, 5.8, 0),
	Color3.fromRGB(191, 161, 83),
	Enum.Material.Fabric
)
for _, x in { -0.3, 0.3 } do
	part(
		farmer,
		"Eye",
		Vector3.new(0.12, 0.12, 0.06),
		farmerOrigin + Vector3.new(x, 4.8, 0.72),
		Color3.fromRGB(36, 31, 25),
		Enum.Material.SmoothPlastic
	)
end

local fence = model("Fences", scenery)
local function fenceRun(a: Vector3, b: Vector3): ()
	local length = (b - a).Magnitude
	local midpoint = (a + b) / 2
	for _, height in { 1.5, 3 } do
		local rail = part(
			fence,
			"Rail",
			Vector3.new(0.35, 0.35, length),
			midpoint + Vector3.new(0, height, 0),
			wood,
			Enum.Material.Wood
		)
		rail.CFrame = CFrame.lookAt(midpoint + Vector3.new(0, height, 0), b + Vector3.new(0, height, 0))
	end
	local segments = math.ceil(length / 12)
	for i = 0, segments do
		part(
			fence,
			"Post",
			Vector3.new(0.7, 3.8, 0.7),
			a:Lerp(b, i / segments) + Vector3.new(0, 1.9, 0),
			wood,
			Enum.Material.Wood
		)
	end
end
fenceRun(Vector3.new(-136, 0, 100), Vector3.new(-24, 0, 100))
fenceRun(Vector3.new(-136, 0, 148), Vector3.new(-24, 0, 148))
fenceRun(Vector3.new(-136, 0, 100), Vector3.new(-136, 0, 148))
fenceRun(Vector3.new(-24, 0, 100), Vector3.new(-24, 0, 112))
fenceRun(Vector3.new(-24, 0, 124), Vector3.new(-24, 0, 148))

kingdom:PivotTo(center)
spawn(kingdom, "SpawnPoint", Vector3.new(0, 0.3, 136))
local bundle = oldBundle:Clone()
local unit = belt.Size.X / 5
bundle.Size = Vector3.new(2, 1, 1.5) * unit
for _, descendant in kingdom:GetDescendants() do
	assert(not descendant:IsA("LuaSourceContainer"), "Replacement assets must be script-free")
	if descendant:IsA("BasePart") then
		assert(descendant.Anchored, "Replacement template must be anchored")
	end
end

local backup = Instance.new("Folder")
backup.Name = BACKUP_NAME
backup:SetAttribute("OriginalTemplateParent", source.Parent and source.Parent:GetFullName() or "")
backup:SetAttribute("Description", "Original four-plot scene; restore originals only after moving replacements aside")
backup.Parent = ServerStorage
oldMap.Parent = backup
oldPlots.Parent = backup
source.Parent = backup
oldBundle.Parent = backup
newMap.Parent = workspace
newPlots.Parent = workspace
kingdom.Parent = ServerStorage
bundle.Parent = ServerStorage
game:GetService("Selection"):Set({ plot })
print("Full-platform Plot01 installed. Original scene archived in ServerStorage." .. BACKUP_NAME)
print("Farm starts only after its owner's Start Farm plate. Save the Studio place.")
