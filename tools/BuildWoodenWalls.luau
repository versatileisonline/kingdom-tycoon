--!strict
-- One-time Edit-mode installation; never Rojo-mapped or run during gameplay.
-- Execute this file verbatim through Studio MCP. Original template is archived intact.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
assert(not RunService:IsRunning(), "Stop Play before installing walls")
assert(game.PlaceId == 77311816657817, "Wrong Kingdom Tycoon place")
local backupName = "WoodenWallsBackup_20261116"
assert(ServerStorage:FindFirstChild(backupName) == nil, "Walls already installed; use documented rollback")
local original = ServerStorage:FindFirstChild("KingdomTemplate")
assert(original ~= nil and original:IsA("Model") and original.Archivable, "Missing archivable template")
local plates = original:FindFirstChild("PurchasePlates")
assert(plates ~= nil and plates:IsA("Folder"), "Missing purchase plates")
assert(plates:FindFirstChild("WoodenWalls") == nil, "Wall plate already exists")
local sourcePlate = plates:FindFirstChild("FarmDropper04")
assert(sourcePlate ~= nil and sourcePlate:IsA("BasePart"), "Missing styled source plate")
local existingUnlocks = original:FindFirstChild("PurchaseUnlocks")
assert(existingUnlocks == nil or existingUnlocks:IsA("Folder"), "Invalid unlock folder")
assert(existingUnlocks == nil or existingUnlocks:FindFirstChild("WoodenWalls") == nil, "Walls already exist")
for _, item in original:GetDescendants() do
	assert(not item:IsA("LuaSourceContainer"), "Template must be script-free")
end

local replacement = original:Clone()
local ok, reason = xpcall(function()
	local pivot = replacement:GetPivot()
	local unlocks = replacement:FindFirstChild("PurchaseUnlocks")
	if unlocks == nil then
		unlocks = Instance.new("Folder")
		unlocks.Name = "PurchaseUnlocks"
		unlocks.Parent = replacement
	end
	local walls = Instance.new("Model")
	walls.Name = "WoodenWalls"
	walls.Parent = unlocks
	local wood = Color3.fromRGB(108, 72, 43)
	local dark = Color3.fromRGB(75, 49, 30)
	local count = 0
	local function part(className: string, name: string, size: Vector3, frame: CFrame, color: Color3): BasePart
		local item = Instance.new(className) :: BasePart
		item.Name = name
		item.Size = size
		item.CFrame = pivot * frame
		item.Anchored = true
		item.CanTouch = false
		item.Material = Enum.Material.Wood
		item.Color = color
		item.TopSurface = Enum.SurfaceType.Smooth
		item.BottomSurface = Enum.SurfaceType.Smooth
		item.Parent = walls
		count += 1
		return item
	end
	-- Five runs leave the centered 24-stud entrance entirely clear.
	local function run(name: string, center: Vector3, length: number, angle: number): ()
		local frame = CFrame.new(center) * CFrame.Angles(0, angle, 0)
		local stakes = math.floor(length / 4)
		local spacing = length / stakes
		for index = 1, stakes do
			local x = -length / 2 + (index - 0.5) * spacing
			local color = if index % 3 == 0 then Color3.fromRGB(121, 82, 48) else wood
			part("Part", name .. "Stake", Vector3.new(spacing, 14, 3), frame * CFrame.new(x, 7, 0), color)
			-- Paired wedges form a peaked wooden top without meshes or external assets.
			part(
				"WedgePart",
				name .. "Tip",
				Vector3.new(3, 2, spacing / 2),
				frame * CFrame.new(x - spacing / 4, 15, 0) * CFrame.Angles(0, math.pi / 2, 0),
				color
			)
			part(
				"WedgePart",
				name .. "Tip",
				Vector3.new(3, 2, spacing / 2),
				frame * CFrame.new(x + spacing / 4, 15, 0) * CFrame.Angles(0, -math.pi / 2, 0),
				color
			)
		end
		for _, height in { 4, 10 } do
			part("Part", name .. "Beam", Vector3.new(length, 1, 1), frame * CFrame.new(0, height, 1.5), dark)
		end
		task.wait()
	end
	run("FrontLeft", Vector3.new(-60, 0, 74), 96, 0)
	run("FrontRight", Vector3.new(60, 0, 74), 96, 0)
	run("Back", Vector3.new(0, 0, -138), 216, math.pi)
	run("Left", Vector3.new(-106, 0, -32), 208, math.pi / 2)
	run("Right", Vector3.new(106, 0, -32), 208, -math.pi / 2)
	for _, x in { -14, 14 } do
		part("Part", "EntrancePost", Vector3.new(4, 16, 4), CFrame.new(x, 8, 74), dark)
	end
	assert(count <= 650, "Unexpected wall part count")
	for _, item in walls:GetDescendants() do
		if item:IsA("BasePart") then
			-- Rotation-aware bounds: all corners must remain in the reservation.
			for _, x in { -0.5, 0.5 } do
				for _, z in { -0.5, 0.5 } do
					local point = pivot:PointToObjectSpace(
						item.CFrame:PointToWorldSpace(Vector3.new(x * item.Size.X, 0, z * item.Size.Z))
					)
					assert(
						point.X >= -108.01 and point.X <= 108.01 and point.Z >= -140.01 and point.Z <= 76.01,
						"Walls exceed reservation"
					)
				end
			end
		end
	end
	local plate = sourcePlate:Clone()
	plate.Name = "WoodenWalls"
	local delta = pivot:PointToWorldSpace(Vector3.new(0, 0.4, 92)) - plate.Position
	plate.CFrame += delta
	for _, child in plate:GetDescendants() do
		if child:IsA("BasePart") then
			child.CFrame += delta
		end
	end
	local label = plate:FindFirstChild("PurchaseLabel", true)
	assert(label ~= nil and label:IsA("TextLabel"), "Missing source purchase label")
	label.Text = "Wooden Walls"
	plate.Parent = replacement.PurchasePlates
	require(game.ReplicatedStorage.Shared.PlatePresentation).Style(plate)
	print(string.format("Wooden wall asset checks passed (%d anchored parts)", count))
end, debug.traceback)
if not ok then
	replacement:Destroy()
	error(reason)
end
-- Only swap after successful construction/preflight. Preserve the original intact.
local backup = Instance.new("Folder")
backup.Name = backupName
backup.Parent = ServerStorage
original.Parent = backup
replacement.Parent = ServerStorage
print("Installed WoodenWalls; original retained in ServerStorage." .. backupName)
