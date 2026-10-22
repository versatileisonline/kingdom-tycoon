--!strict
-- Approved one-time Edit-mode refinement. Not mapped by Rojo or run in-game.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local BACKUP_NAME = "PlateRefinementBackup_20261021"
local FARMER_FRONT_CLEARANCE = 4
assert(RunService:IsStudio() and not RunService:IsRunning(), "Studio Edit mode only")
assert(ServerStorage:FindFirstChild(BACKUP_NAME) == nil, "Plate refinement already applied; refusing a second run")
local kingdom = ServerStorage:FindFirstChild("KingdomTemplate") or workspace:FindFirstChild("KingdomTemplate")
assert(kingdom ~= nil and kingdom:IsA("Model"), "KingdomTemplate required")
local farm = kingdom:FindFirstChild("StarterFarm")
assert(farm ~= nil and farm:IsA("Model"), "StarterFarm required")
local scenery = farm:FindFirstChild("Scenery")
local farmer = if scenery ~= nil then scenery:FindFirstChild("Farmer") else nil
local foundation = farm:FindFirstChild("FarmFoundation")
local drop = farm:FindFirstChild("DropPoint")
assert(farmer ~= nil and farmer:IsA("Model"), "Farmer Model required")
assert(foundation ~= nil and foundation:IsA("BasePart"), "FarmFoundation required")
assert(drop ~= nil and drop:IsA("BasePart"), "DropPoint required")
local plots = workspace:FindFirstChild("Plots")
local plot = if plots ~= nil then plots:FindFirstChild("Plot01") else nil
local claim = if plot ~= nil then plot:FindFirstChild("ClaimMarker") else nil
local start = kingdom:FindFirstChild("FarmStartPlate")
local collect = farm:FindFirstChild("CollectPlate")
assert(claim ~= nil and claim:IsA("Part"), "ClaimMarker Part required")
assert(start ~= nil and start:IsA("Part"), "FarmStartPlate Part required")
assert(collect ~= nil and collect:IsA("Part"), "CollectPlate Part required")
local active = workspace:FindFirstChild("ActiveKingdoms")
assert(active ~= nil and #active:GetChildren() == 0, "Stop Play and clear runtime kingdoms first")
for _, plate in { claim, start, collect } do
	assert(plate:FindFirstChild("Outline") == nil, "Existing plate outline; refusing replacement")
end

-- A fresh clone reads the current on-disk config after Rojo sync, avoiding an
-- earlier Edit-mode require cache. Its Source is never edited in Studio.
local configSource = Shared:FindFirstChild("Config")
assert(configSource ~= nil and configSource:IsA("ModuleScript"), "Shared.Config required")
local freshConfig = configSource:Clone()
freshConfig.Name = "__PlateRefinementConfig"
freshConfig.Parent = Shared
local ok, config = pcall(require, freshConfig)
freshConfig:Destroy()
assert(ok and config.PLATES ~= nil, "Sync the updated Config.PLATES before running")
local settings = config.PLATES

local backup = Instance.new("Folder")
backup.Name = BACKUP_NAME
backup:SetAttribute("OriginalTemplateParent", kingdom.Parent and kingdom.Parent:GetFullName() or "")
kingdom:Clone().Parent = backup
claim:Clone().Parent = backup
backup.Parent = ServerStorage

local function circularPlate(plate: Part, available: boolean): ()
	local topY = plate.Position.Y + plate.Size.Y / 2
	local center = Vector3.new(plate.Position.X, topY - settings.THICKNESS / 2, plate.Position.Z)
	-- Roblox cylinders run along local X; turn that axis upright for a floor disc.
	local upright = CFrame.Angles(0, 0, math.pi / 2)
	plate.Shape = Enum.PartType.Cylinder
	plate.Size = Vector3.new(settings.THICKNESS, settings.DIAMETER, settings.DIAMETER)
	plate.CFrame = CFrame.new(center) * upright
	plate.Material = Enum.Material.SmoothPlastic
	plate.Reflectance = 0
	plate.Color = if available then settings.AVAILABLE_COLOR else settings.UNAVAILABLE_COLOR
	plate.Anchored = true
	local outline = Instance.new("Part")
	outline.Name = "Outline"
	outline.Shape = Enum.PartType.Cylinder
	local outerDiameter = settings.DIAMETER + 2 * settings.RIM_WIDTH
	outline.Size = Vector3.new(settings.THICKNESS, outerDiameter, outerDiameter)
	outline.CFrame = CFrame.new(center - Vector3.new(0, settings.RIM_DROP, 0)) * upright
	outline.Color = settings.OUTLINE_COLOR
	outline.Material = Enum.Material.SmoothPlastic
	outline.Anchored = true
	outline.CanCollide = false
	outline.CanTouch = false
	outline.CanQuery = false
	outline.CastShadow = false
	outline.Parent = plate
end

circularPlate(claim, true)
circularPlate(start, true)
circularPlate(collect, false)
local pivot = kingdom:GetPivot()
local farmerPosition = pivot:PointToObjectSpace(farmer:GetPivot().Position)
local dropPosition = pivot:PointToObjectSpace(drop.Position)
local foundationPosition = pivot:PointToObjectSpace(foundation.Position)
local target = pivot:PointToWorldSpace(
	Vector3.new(dropPosition.X, farmerPosition.Y, foundationPosition.Z + foundation.Size.Z / 2 + FARMER_FRONT_CLEARANCE)
)
farmer:PivotTo(CFrame.new(target) * farmer:GetPivot().Rotation)
-- Return the edited source to its required runtime location before Play.
kingdom.Parent = ServerStorage
print("Circular green/red plates and front farmer installed. Originals preserved in " .. BACKUP_NAME)
print("Save the Studio place to retain these asset changes.")
