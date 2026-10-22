--!strict
-- One-time Studio Edit command, explicitly approved for milestone 1.4.
-- Not mapped by Rojo. Refuses populated farms/templates rather than replacing art.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
assert(not RunService:IsRunning(), "Run only in Studio Edit mode")
local kingdom = ServerStorage:FindFirstChild("KingdomTemplate")
assert(kingdom ~= nil and kingdom:IsA("Model"), "Return KingdomTemplate to ServerStorage first")
assert(ServerStorage:FindFirstChild("WheatBundle") == nil, "WheatBundle already exists; refusing replacement")
local footprint = kingdom:FindFirstChild("FarmFootprint")
assert(footprint ~= nil and footprint:IsA("BasePart"), "Existing FarmFootprint required")
local existing = kingdom:FindFirstChild("StarterFarm")
assert(
	existing == nil or (existing:IsA("Model") and #existing:GetChildren() == 0),
	"StarterFarm contains assets; refusing replacement"
)
local history = game:GetService("ChangeHistoryService")
history:SetWaypoint("Before starter farm assets")
local farm = if existing ~= nil then existing :: Model else Instance.new("Model")
farm.Name = "StarterFarm"
local unit = footprint.Size.X / 16
local origin = footprint.CFrame * CFrame.new(0, footprint.Size.Y / 2, 0)
local wood = Color3.fromRGB(101, 69, 43)
local stone = Color3.fromRGB(79, 83, 83)

local function part(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size * unit
	item.CFrame = origin * CFrame.new(position * unit)
	item.Anchored = true
	item.Color = color
	item.Material = material
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = farm
	return item
end

part("FarmFoundation", Vector3.new(16, 0.5, 24), Vector3.new(0, 0.25, 0), wood, Enum.Material.WoodPlanks)
part("Conveyor", Vector3.new(5, 0.6, 14), Vector3.new(-2.5, 2.4, 1), Color3.fromRGB(54, 61, 55), Enum.Material.Fabric)
for _, x in { -5.3, 0.3 } do
	part("BeltRail", Vector3.new(0.5, 1.1, 14), Vector3.new(x, 2.9, 1), wood, Enum.Material.Wood)
	for _, z in { -5, 7 } do
		part("BeltLeg", Vector3.new(0.6, 2, 0.8), Vector3.new(x, 1.5, z), wood, Enum.Material.Wood)
	end
end
local drop = part("DropPoint", Vector3.one, Vector3.new(-2.5, 5.2, 6), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
drop.Transparency = 1
drop.CanCollide = false
drop.CanTouch = false
drop.CanQuery = false
for _, x in { -5.5, 0.5 } do
	part("HopperPost", Vector3.new(0.7, 6, 0.7), Vector3.new(x, 3.5, 7), wood, Enum.Material.Wood)
end
part("HopperBeam", Vector3.new(7, 0.8, 3), Vector3.new(-2.5, 6.8, 6.5), wood, Enum.Material.WoodPlanks)
local pit = part("CollectionPit", Vector3.new(5, 2.8, 4), Vector3.new(-2.5, 1.7, -8), stone, Enum.Material.Slate)
pit.Transparency = 1
pit.CanCollide = false
part(
	"PitTray",
	Vector3.new(5.5, 0.3, 4.5),
	Vector3.new(-2.5, 0.65, -8),
	Color3.fromRGB(40, 35, 27),
	Enum.Material.Slate
)
for _, x in { -5.5, 0.5 } do
	part("PitRim", Vector3.new(0.5, 2, 4.5), Vector3.new(x, 1.5, -8), stone, Enum.Material.Cobblestone)
end
part("PitBack", Vector3.new(6.5, 2, 0.5), Vector3.new(-2.5, 1.5, -10.5), stone, Enum.Material.Cobblestone)
local plate = part(
	"CollectPlate",
	Vector3.new(5, 0.5, 6),
	Vector3.new(4.5, 0.75, -7),
	Color3.fromRGB(207, 161, 57),
	Enum.Material.Metal
)
local gui = Instance.new("BillboardGui")
gui.Name = "EarningsGui"
gui.Size = UDim2.fromOffset(260, 64)
gui.StudsOffsetWorldSpace = Vector3.new(0, 4 * unit, 0)
gui.AlwaysOnTop = true
gui.MaxDistance = 150
gui.Parent = plate
local label = Instance.new("TextLabel")
label.Name = "EarningsLabel"
label.Size = UDim2.fromScale(1, 1)
label.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
label.BackgroundTransparency = 0.15
label.TextColor3 = Color3.fromRGB(255, 225, 145)
label.Font = Enum.Font.GothamBold
label.TextSize = 22
label.TextWrapped = true
label.Text = "Collect Gold — 0"
label.Parent = gui
farm.Parent = kingdom

local bundle = Instance.new("Part")
bundle.Name = "WheatBundle"
bundle.Size = Vector3.new(2, 1, 1.5) * unit
bundle.Color = Color3.fromRGB(225, 184, 79)
bundle.Material = Enum.Material.Grass
bundle.Anchored = false
bundle.CanCollide = true
bundle.TopSurface = Enum.SurfaceType.Smooth
bundle.BottomSurface = Enum.SurfaceType.Smooth
bundle.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.7, 0, 100, 100)
bundle.Parent = ServerStorage
local spawn = kingdom:FindFirstChild("SpawnPoint")
local map = workspace:FindFirstChild("KingdomMap")
local arrival = if map ~= nil then map:FindFirstChild("ArrivalSpawn") else nil
assert(spawn ~= nil and spawn:IsA("SpawnLocation"), "Missing kingdom spawn")
assert(arrival ~= nil and arrival:IsA("SpawnLocation"), "Missing arrival spawn")
spawn.Duration = 5
arrival.Duration = 5
history:SetWaypoint("Build starter farm assets")
print("StarterFarm and WheatBundle created; kingdom scale preserved. Save the Studio place.")
