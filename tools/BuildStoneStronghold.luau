--!strict
-- Approved one-time Edit asset recipe. Never mapped by Rojo.
local APPLY = true
local SS = game:GetService("ServerStorage")
assert(not game:GetService("RunService"):IsRunning(), "Stop Play")
assert(game.PlaceId == 77311816657817, "Wrong place")
local backupName = "StoneStrongholdBackup_20261118"
assert(not SS:FindFirstChild(backupName), "Already installed; preserve both versions for rollback")
local source = SS:FindFirstChild("KingdomTemplate") :: Model
assert(source and source:IsA("Model"), "Missing template")
assert(not source.PurchaseUnlocks:FindFirstChild("StoneWalls"), "Already installed")
if not APPLY then
	return "Stronghold preflight passed"
end
local replacement = source:Clone()
local pivot = replacement:GetPivot()
local unlocks = replacement.PurchaseUnlocks
local stone = Instance.new("Model")
stone.Name = "StoneWalls"
stone.Parent = unlocks
local posts = Instance.new("Model")
posts.Name = "ArcherPosts"
posts.Parent = unlocks
local residents = Instance.new("Model")
residents.Name = "KingdomResidents"
residents.Parent = unlocks
local door = Instance.new("Model")
door.Name = "ProtectionDoor"
door.Parent = unlocks
local gray = Color3.fromRGB(143, 145, 137)
local function part(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = pivot * frame
	p.Color = color or gray
	p.Material = Enum.Material.Slate
	p.Anchored = true
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
-- Solid backing gives smooth collision; shallow staggered masonry supplies the reference blockwork.
local function run(frame: CFrame, length: number)
	part(stone, "WallCore", Vector3.new(length, 24, 3), frame * CFrame.new(0, 12, 0))
	for row = 0, 7 do
		local count = math.ceil(length / 6)
		for i = 1, count do
			local left = -length / 2 + (i - 1) * 6
			local width = math.min(5.8, length / 2 - left)
			if width > 0 then
				for _, face in { -1, 1 } do
					part(
						stone,
						"Masonry",
						Vector3.new(width, 2.8, 0.4),
						frame * CFrame.new(left + width / 2, 1.5 + row * 3, face * 1.7),
						if (i + row) % 3 == 0 then Color3.fromRGB(158, 158, 147) else gray
					)
				end
			end
		end
	end
	part(stone, "WallWalk", Vector3.new(length, 1, 8), frame * CFrame.new(0, 23.5, -3))
	for i = 1, math.floor(length / 8) do
		part(stone, "Battlement", Vector3.new(4, 3, 3.5), frame * CFrame.new(-length / 2 + (i - 0.5) * 8, 25.5, 0))
	end
	task.wait()
end
run(CFrame.new(0, 0, -138), 216)
run(CFrame.new(-106, 0, -32) * CFrame.Angles(0, math.pi / 2, 0), 212)
run(CFrame.new(106, 0, -32) * CFrame.Angles(0, -math.pi / 2, 0), 212)
run(CFrame.new(-60, 0, 74) * CFrame.Angles(0, math.pi, 0), 96)
run(CFrame.new(60, 0, 74) * CFrame.Angles(0, math.pi, 0), 96)
-- Front opening is 24 studs clear. Ring voussoirs make an arch, no solid door.
for i = 0, 11 do
	local a = math.pi * (i + 0.5) / 12
	part(
		stone,
		"ArchStone",
		Vector3.new(3.8, 3.2, 5),
		CFrame.new(14 * math.cos(a), 10 + 14 * math.sin(a), 74) * CFrame.Angles(0, 0, a - math.pi / 2)
	)
end
part(stone, "GateBridge", Vector3.new(32, 2, 10), CFrame.new(0, 25, 71))
for _, x in { -17, 17 } do
	part(stone, "GatePier", Vector3.new(6, 26, 8), CFrame.new(x, 13, 74))
	part(stone, "GateCrown", Vector3.new(8, 3, 10), CFrame.new(x, 28, 74))
end
local placements = Instance.new("Folder")
placements.Name = "Placements"
placements.Parent = posts
for i, position in
	{ Vector3.new(-106, 0, -138), Vector3.new(106, 0, -138), Vector3.new(-106, 0, 74), Vector3.new(106, 0, 74) }
do
	-- Open topped round masonry tower with raised deck and crenellated rim.
	for j = 0, 19 do
		local a = j * math.pi / 10
		local frame = CFrame.new(position) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -9)
		part(stone, "TowerMasonry", Vector3.new(3, 28, 3), frame * CFrame.new(0, 14, 0))
		if j % 2 == 0 then
			part(stone, "TowerMerlon", Vector3.new(3.2, 3, 3.4), frame * CFrame.new(0, 29.5, 0))
		end
	end
	local floor = part(stone, "TowerDeck", Vector3.new(18, 1, 18), CFrame.new(position + Vector3.new(0, 23.5, 0)))
	floor.Shape = Enum.PartType.Cylinder
	floor.Size = Vector3.new(1, 18, 18)
	floor.CFrame = pivot * CFrame.new(position + Vector3.new(0, 23.5, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	part(
		posts,
		"ArcherPlatform",
		Vector3.new(10, 0.5, 10),
		CFrame.new(position + Vector3.new(0, 24.25, 0)),
		Color3.fromRGB(103, 73, 44)
	).Material =
		Enum.Material.WoodPlanks
	local marker = part(placements, "Archer" .. i, Vector3.one, CFrame.new(position + Vector3.new(0, 27.5, 0)))
	marker.Transparency = 1
	marker.CanCollide = false
	marker:SetAttribute("Role", "Archer")
	task.wait()
end
-- Clone the central castle's authored ladder section for access; preserve the source.
local castleWalls = workspace:FindFirstChild("Walls")
local ladderSource = castleWalls and castleWalls:FindFirstChild("Wall Segment with Ladder")
for i, z in { -70, 6 } do
	local ladder = Instance.new("TrussPart")
	ladder.Name = "WallAccess" .. i
	ladder.Size = Vector3.new(2, 24, 2)
	ladder.CFrame = pivot * CFrame.new(101, 12, z)
	ladder.Anchored = true
	ladder.Material = Enum.Material.Metal
	ladder.Color = Color3.fromRGB(88, 78, 62)
	ladder.Parent = stone
end
-- Reuse authored heraldry from the castle when available, rather than altering the castle.
if ladderSource then
	stone:SetAttribute("CastleReference", ladderSource:GetFullName())
end
local barrier = part(door, "Barrier", Vector3.new(24, 20, 0.6), CFrame.new(0, 10, 74), Color3.fromRGB(255, 181, 52))
barrier.Material = Enum.Material.ForceField
barrier.Transparency = 0.45
barrier.CanCollide = false
barrier.CanTouch = true
local zone = part(door, "DetectionZone", Vector3.new(24, 20, 2), CFrame.new(0, 10, 74))
zone.Transparency = 1
zone.CanCollide = false
zone.CanTouch = false
local control = part(door, "ToggleControl", Vector3.new(1, 2, 1), CFrame.new(17, 4, 68), Color3.fromRGB(200, 145, 50))
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Disable Ward"
prompt.ObjectText = "Owner Control"
prompt.MaxActivationDistance = 10
prompt.Parent = control
local gui = Instance.new("BillboardGui")
gui.Name = "WardSign"
gui.Size = UDim2.fromOffset(160, 38)
gui.StudsOffset = Vector3.new(0, 3, 0)
gui.Parent = control
local label = Instance.new("TextLabel")
label.Name = "StateLabel"
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Text = "WARD ON • LETHAL"
label.TextSize = 14
label.Font = Enum.Font.Arcade
label.TextColor3 = Color3.fromRGB(255, 196, 64)
label.Parent = gui
local routes = Instance.new("Folder")
routes.Name = "Routes"
routes.Parent = residents
local workers = Instance.new("Folder")
workers.Name = "Placements"
workers.Parent = residents
for i, pos in { Vector3.new(65, 3, 35), Vector3.new(78, 3, -80) } do
	local m = part(workers, "Worker" .. i, Vector3.one, CFrame.new(pos))
	m.Transparency = 1
	m.CanCollide = false
	m:SetAttribute("Role", "Worker")
	part(
		residents,
		"SupplyCrate",
		Vector3.new(3, 3, 3),
		CFrame.new(pos + Vector3.new(4, -1.5, 0)),
		Color3.fromRGB(118, 83, 48)
	).Material =
		Enum.Material.WoodPlanks
end
-- Right side circulation stays away from both Mint belts on the left.
for i = 1, 8 do
	local route = Instance.new("Folder")
	route.Name = string.format("Route%02d", i)
	route.Parent = routes
	local x = 48 + (i % 3) * 11
	local z = -100 + math.floor((i - 1) / 3) * 42
	for j, pos in { Vector3.new(x, 3, z), Vector3.new(x + 7, 3, z + 12), Vector3.new(x, 3, z + 22) } do
		local m = part(route, string.format("%02d", j), Vector3.one, CFrame.new(pos))
		m.Transparency = 1
		m.CanCollide = false
	end
end
-- Palette derived from existing central wall art, copied by value.
local central = castleWalls and castleWalls:FindFirstChild("Wall Segment")
if central then
	stone:SetAttribute("CastleSource", central:GetFullName())
end
local plates = replacement.PurchasePlates
local plateSource = plates.RoyalMintDropper02
for i, id in { "StoneWalls", "ProtectionDoor", "ArcherPosts", "KingdomResidents" } do
	local plate = plateSource:Clone()
	plate.Name = id
	plate.CFrame = pivot * CFrame.new(30 + (i - 1) * 7, 0.4, 60)
	plate.Parent = plates
end
-- Script-free R15 templates. Offline authored appearance; no avatar lookup during play.
local templates = Instance.new("Folder")
templates.Name = "ResidentTemplates"
templates.Parent = replacement
for i, role in { "Archer", "Worker", "Villager" } do
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = Color3.fromRGB(215, 177, 139)
	description.LeftArmColor = description.HeadColor
	description.RightArmColor = description.HeadColor
	description.TorsoColor = if role == "Archer"
		then Color3.fromRGB(40, 65, 108)
		else Color3.fromRGB(108 + i * 15, 89, 64)
	description.LeftLegColor = Color3.fromRGB(58, 48, 40)
	description.RightLegColor = description.LeftLegColor
	local rig = game:GetService("Players")
		:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	rig.Name = role
	for _, v in rig:GetDescendants() do
		if v:IsA("LuaSourceContainer") then
			v:Destroy()
		elseif v:IsA("BasePart") then
			v.Anchored = true
			v.CanCollide = false
		end
	end
	rig:PivotTo(pivot * CFrame.new(0, -100, 0))
	rig.Parent = templates
	task.wait()
end
for _, v in replacement:GetDescendants() do
	assert(not v:IsA("LuaSourceContainer"), "Unexpected template script")
end
local backup = Instance.new("Folder")
backup.Name = backupName
backup.Parent = SS
source.Parent = backup
replacement.Name = "KingdomTemplate"
replacement.Parent = SS
return "Stronghold assets installed; original template preserved in " .. backupName
