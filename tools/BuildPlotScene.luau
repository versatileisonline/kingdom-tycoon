--!strict
-- ONE-TIME STUDIO EDIT COMMAND, not a gameplay script and not mapped by Rojo.
-- Run the contents in Edit mode. Refuses existing named assets; never replaces them.
-- Approved exception to AGENTS.md section 7 for milestone 1.3 (2026-10-20).
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Run only in Studio Edit mode")
assert(not workspace:FindFirstChild("KingdomMap"), "KingdomMap already exists; refusing to overwrite")
assert(not workspace:FindFirstChild("Plots"), "Plots already exists; refusing to overwrite")
assert(not workspace:FindFirstChild("ActiveKingdoms"), "ActiveKingdoms already exists; refusing to overwrite")
assert(not ServerStorage:FindFirstChild("KingdomTemplate"), "KingdomTemplate already exists; refusing to overwrite")

local CENTER = Vector3.new(1400, 40, 0) -- Deliberately outside the existing castle/terrain.
local colors = {
	Grass = Color3.fromRGB(111, 133, 77),
	Earth = Color3.fromRGB(91, 83, 66),
	Stone = Color3.fromRGB(156, 154, 133),
	Path = Color3.fromRGB(184, 170, 137),
	Wood = Color3.fromRGB(91, 63, 43),
	LightWood = Color3.fromRGB(142, 107, 65),
	Gold = Color3.fromRGB(219, 179, 85),
	Green = Color3.fromRGB(44, 81, 67),
	Cream = Color3.fromRGB(242, 230, 194),
}

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function marker(parent: Instance, name: string, cf: CFrame): Part
	local p = part(parent, name, Vector3.one, cf.Position, colors.Grass)
	p.CFrame = cf
	p.Transparency = 1
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	return p
end

local function billboard(parent: BasePart, name: string, text: string, width: number, offset: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = name .. "Gui"
	gui.Size = UDim2.fromOffset(width, 58)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offset, 0)
	gui.MaxDistance = 130
	gui.AlwaysOnTop = false
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = colors.Green
	label.BackgroundTransparency = 0.12
	label.TextColor3 = colors.Cream
	label.Text = text
	label.TextSize = 19
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label
	local stroke = Instance.new("UIStroke")
	stroke.Color = colors.Gold
	stroke.Thickness = 1.5
	stroke.Parent = label
	return label
end

local function banner(parent: Instance, x: number, z: number, height: number): ()
	part(
		parent,
		"BannerPole",
		Vector3.new(0.5, height, 0.5),
		Vector3.new(x, height / 2, z),
		colors.Wood,
		Enum.Material.Wood
	)
	part(
		parent,
		"BannerCrossbar",
		Vector3.new(5, 0.4, 0.5),
		Vector3.new(x, height - 0.5, z),
		colors.Gold,
		Enum.Material.Metal
	)
	part(
		parent,
		"BannerCloth",
		Vector3.new(4, 6, 0.18),
		Vector3.new(x, height - 4, z),
		colors.Green,
		Enum.Material.Fabric
	)
	part(
		parent,
		"BannerEmblem",
		Vector3.new(1, 2.8, 0.2),
		Vector3.new(x, height - 3.8, z + 0.12),
		colors.Gold,
		Enum.Material.Metal
	)
end

-- Small independent chunks keep Studio responsive. No terrain or existing objects are edited.
local map = Instance.new("Model")
map.Name = "KingdomMap"
map:SetAttribute("Milestone", "1.3")
part(map, "PlateauRock", Vector3.new(330, 12, 330), CENTER - Vector3.new(0, 7, 0), colors.Earth, Enum.Material.Rock)
part(map, "Meadow", Vector3.new(320, 2, 320), CENTER - Vector3.new(0, 1, 0), colors.Grass, Enum.Material.Grass)
part(map, "MainRoad", Vector3.new(292, 0.2, 18), CENTER + Vector3.new(0, 0.1, 0), colors.Path, Enum.Material.Pebble)
part(
	map,
	"Plaza",
	Vector3.new(48, 0.35, 44),
	CENTER + Vector3.new(0, 0.175, 0),
	colors.Stone,
	Enum.Material.Cobblestone
)
local arrival = Instance.new("SpawnLocation")
arrival.Name = "ArrivalSpawn"
arrival.Size = Vector3.new(10, 0.4, 10)
arrival.Position = CENTER + Vector3.new(0, 0.4, 10)
arrival.Anchored = true
arrival.Transparency = 1
arrival.CanCollide = false
arrival.Neutral = true
arrival.Duration = 0
arrival.Parent = map
local monument =
	part(map, "Waystone", Vector3.new(4, 7, 3), CENTER + Vector3.new(0, 3.5, -8), colors.Stone, Enum.Material.Slate)
billboard(monument, "WelcomeLabel", "THE KINGDOM GROUNDS\nChoose land. Raise your banner.", 330, 6)
part(map, "WaystoneCrest", Vector3.new(2, 3, 0.15), CENTER + Vector3.new(0, 5, -6.4), colors.Gold, Enum.Material.Metal)
for _, x in { -70, 70 } do
	for _, z in { -1, 1 } do
		part(
			map,
			"Approach",
			Vector3.new(12, 0.25, 30),
			CENTER + Vector3.new(x, 0.125, z * 23),
			colors.Path,
			Enum.Material.Pebble
		)
	end
end
for _, x in { -150, 150 } do
	for _, z in { -135, -60, 60, 135 } do
		local base = CENTER + Vector3.new(x, 0, z)
		part(map, "TreeTrunk", Vector3.new(3, 12, 3), base + Vector3.new(0, 6, 0), colors.Wood, Enum.Material.Wood)
		local crown = part(
			map,
			"TreeCrown",
			Vector3.new(14, 15, 14),
			base + Vector3.new(0, 17, 0),
			colors.Green,
			Enum.Material.Grass
		)
		crown.Shape = Enum.PartType.Ball
	end
end
map.Parent = workspace
task.wait()

local plots = Instance.new("Folder")
plots.Name = "Plots"
plots.Parent = workspace
for i, offset in { Vector3.new(-70, 0, -85), Vector3.new(70, 0, -85), Vector3.new(-70, 0, 85), Vector3.new(70, 0, 85) } do
	local plot = Instance.new("Model")
	local id = string.format("Plot%02d", i)
	plot.Name = id
	plot:SetAttribute("PlotId", id)
	local cf = CFrame.new(CENTER + offset) * CFrame.Angles(0, if offset.Z > 0 then math.pi else 0, 0)
	marker(plot, "Origin", cf)
	local pad = part(
		plot,
		"PlotGround",
		Vector3.new(112, 0.3, 102),
		CENTER + offset + Vector3.new(0, 0.15, 0),
		colors.Grass,
		Enum.Material.Grass
	)
	pad.Color = Color3.fromRGB(124, 143, 85)
	for _, x in { -55, 55 } do
		for _, z in { -50, 50 } do
			part(
				plot,
				"BoundaryStone",
				Vector3.new(2, 1.5, 2),
				(cf * CFrame.new(x, 0.75, z)).Position,
				colors.Stone,
				Enum.Material.Slate
			)
		end
	end
	local claim = part(
		plot,
		"ClaimMarker",
		Vector3.new(1, 9, 1),
		(cf * CFrame.new(12, 4.5, 48)).Position,
		colors.Wood,
		Enum.Material.Wood
	)
	local cloth = part(
		plot,
		"ClaimBanner",
		Vector3.new(5, 4, 0.25),
		(cf * CFrame.new(10, 6, 48)).Position,
		colors.Gold,
		Enum.Material.Fabric
	)
	cloth.CFrame = cf * CFrame.new(10, 6, 48)
	billboard(claim, "ClaimLabel", "UNCLAIMED LAND", 230, 7)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClaimPrompt"
	prompt.ActionText = "Claim Kingdom"
	prompt.ObjectText = "Unclaimed land"
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.Parent = claim
	plot.Parent = plots
	task.wait()
end

local kingdom = Instance.new("Model")
kingdom.Name = "KingdomTemplate"
kingdom:SetAttribute("AssetVersion", 1)
-- Template coordinates are relative to the plot origin at ground height.
local root = marker(kingdom, "TemplateRoot", CFrame.identity)
kingdom.PrimaryPart = root
part(kingdom, "Courtyard", Vector3.new(68, 0.35, 64), Vector3.new(0, 0.4, 0), colors.Path, Enum.Material.Pebble)
part(
	kingdom,
	"EntrancePath",
	Vector3.new(14, 0.3, 24),
	Vector3.new(0, 0.4, 40),
	colors.Stone,
	Enum.Material.Cobblestone
)
for _, x in { -11, 11 } do
	part(kingdom, "GateFooting", Vector3.new(5, 3, 5), Vector3.new(x, 1.5, 31), colors.Stone, Enum.Material.Cobblestone)
	part(kingdom, "GatePost", Vector3.new(3, 15, 3), Vector3.new(x, 9, 31), colors.Wood, Enum.Material.Wood)
	part(kingdom, "PostCap", Vector3.new(4, 1, 4), Vector3.new(x, 16.5, 31), colors.LightWood, Enum.Material.WoodPlanks)
	banner(kingdom, x * 1.9, 30, 15)
end
local lintel =
	part(kingdom, "EntranceBeam", Vector3.new(27, 3, 4), Vector3.new(0, 15, 31), colors.LightWood, Enum.Material.Wood)
billboard(lintel, "OwnerLabel", "YOUR KINGDOM", 290, 5)
-- Modest open pavilion: the kingdom begins as a settlement, leaving room for purchases.
part(
	kingdom,
	"PavilionFoundation",
	Vector3.new(27, 1, 20),
	Vector3.new(0, 0.7, -19),
	colors.Stone,
	Enum.Material.Cobblestone
)
for _, x in { -11, 11 } do
	for _, z in { -26, -12 } do
		part(kingdom, "PavilionPost", Vector3.new(1.4, 10, 1.4), Vector3.new(x, 6, z), colors.Wood, Enum.Material.Wood)
	end
end
part(kingdom, "PavilionBeam", Vector3.new(26, 1.2, 18), Vector3.new(0, 11, -19), colors.Wood, Enum.Material.Wood)
for _, side in { -1, 1 } do
	local roof = part(
		kingdom,
		"PavilionRoof",
		Vector3.new(16, 1, 24),
		Vector3.new(side * 6.2, 14, -19),
		colors.Green,
		Enum.Material.WoodPlanks
	)
	roof.CFrame = CFrame.new(roof.Position) * CFrame.Angles(0, 0, math.rad(-side * 25))
end
part(kingdom, "PavilionRidge", Vector3.new(1.2, 1.2, 25), Vector3.new(0, 17, -19), colors.Wood, Enum.Material.Wood)
part(kingdom, "Table", Vector3.new(9, 0.8, 4), Vector3.new(0, 4, -19), colors.LightWood, Enum.Material.WoodPlanks)
for _, x in { -3.5, 3.5 } do
	part(kingdom, "TableLeg", Vector3.new(1, 3, 3), Vector3.new(x, 2, -19), colors.Wood, Enum.Material.Wood)
end
for _, x in { -30, 30 } do
	part(kingdom, "Bench", Vector3.new(3, 1, 12), Vector3.new(x, 2.5, -7), colors.LightWood, Enum.Material.WoodPlanks)
	for _, z in { -11, -3 } do
		part(kingdom, "BenchLeg", Vector3.new(2, 2, 1), Vector3.new(x, 1, z), colors.Wood, Enum.Material.Wood)
	end
end
-- The outside farm is a reserved footprint, with no producer or economy yet.
part(kingdom, "FarmFootprint", Vector3.new(16, 0.25, 24), Vector3.new(46, 0.5, -12), colors.Earth, Enum.Material.Ground)
for _, z in { -23, -1 } do
	for _, x in { 38, 54 } do
		part(
			kingdom,
			"FarmCorner",
			Vector3.new(0.8, 3, 0.8),
			Vector3.new(x, 1.5, z),
			colors.LightWood,
			Enum.Material.Wood
		)
	end
end
for _, x in { -32, 32 } do
	for _, z in { -29, 17 } do
		local barrel = part(
			kingdom,
			"Barrel",
			Vector3.new(3, 4, 3),
			Vector3.new(x, 2.4, z),
			colors.LightWood,
			Enum.Material.WoodPlanks
		)
		barrel.Shape = Enum.PartType.Cylinder
		barrel.CFrame = CFrame.new(barrel.Position) * CFrame.Angles(0, 0, math.pi / 2)
	end
end
local spawn = Instance.new("SpawnLocation")
spawn.Name = "SpawnPoint"
spawn.Size = Vector3.new(6, 0.2, 6)
spawn.CFrame = CFrame.new(0, 0.7, 13) * CFrame.Angles(0, math.pi, 0)
spawn.Anchored = true
spawn.CanCollide = false
spawn.CanTouch = false
spawn.CanQuery = false
spawn.Transparency = 1
spawn.Neutral = true
spawn.Enabled = true
spawn.AllowTeamChangeOnTouch = false
spawn.Duration = 0
spawn.Parent = kingdom
kingdom.Parent = ServerStorage
local active = Instance.new("Folder")
active.Name = "ActiveKingdoms"
active.Parent = workspace
game:GetService("ChangeHistoryService"):SetWaypoint("Milestone 1.3 plot scene created")
print("[KingdomTycoon][SceneBuilder] Created four plots and KingdomTemplate; existing scene preserved")
return { Center = tostring(CENTER), Plots = #plots:GetChildren(), TemplateParts = #kingdom:GetDescendants() }
