--!strict
-- Approved one-time Studio Edit recipe for milestone 1.6; never Rojo-mapped.
-- Clones the existing machinery/style and archives the original template intact.
local ServerStorage = game:GetService("ServerStorage")
local BACKUP_NAME = "FarmProgressionBackup_20261115"
local SLOT_Z = { 137, 129, 121, 113 }
local PLATE_Z = { 134, 124, 114 }
local PRICES = { 6, 12, 24 }
assert(not game:GetService("RunService"):IsRunning(), "Studio Edit mode only")
assert(game.PlaceId == 77311816657817, "Wrong Kingdom Tycoon place")
assert(ServerStorage:FindFirstChild(BACKUP_NAME) == nil, "Already applied; refusing replacement")
assert(#workspace.ActiveKingdoms:GetChildren() == 0, "Stop gameplay first")
local original = ServerStorage:FindFirstChild("KingdomTemplate")
assert(original ~= nil and original:IsA("Model"), "Stored KingdomTemplate required")
local sourceFarm = original:FindFirstChild("StarterFarm")
assert(sourceFarm ~= nil and sourceFarm:FindFirstChild("Producers") == nil, "Existing producer layout; inspect first")
assert(original:FindFirstChild("PurchasePlates") == nil, "Existing purchase plates; inspect before merging")

local kingdom = original:Clone()
local farm = kingdom:FindFirstChild("StarterFarm") :: Model
local pivot = kingdom:GetPivot()
local function part(name: string): BasePart
	local found = farm:FindFirstChild(name)
	assert(found ~= nil and found:IsA("BasePart"), "Missing machinery " .. name)
	return found
end
local function localPosition(item: BasePart): Vector3
	return pivot:PointToObjectSpace(item.Position)
end
local function moveTo(item: BasePart, x: number, z: number): ()
	local position = localPosition(item)
	item.CFrame = CFrame.new(pivot:PointToWorldSpace(Vector3.new(x, position.Y, z))) * item.CFrame.Rotation
end

local conveyor = part("Conveyor")
local drop = part("DropPoint")
local machineX = localPosition(drop).X
local oldDropZ = localPosition(drop).Z
local hopperParts: { BasePart } = {}
for _, child in farm:GetChildren() do
	if child:IsA("BasePart") and (child.Name == "HopperPost" or child.Name == "HopperBeam") then
		table.insert(hopperParts, child)
	end
end
assert(#hopperParts == 3, "Expected two existing hopper posts and one beam")

-- Extend the single fixed belt inside the existing 112 x 48 farm reservation.
conveyor.Size = Vector3.new(conveyor.Size.X, conveyor.Size.Y, 32)
moveTo(conveyor, machineX, 124)
conveyor.AssemblyLinearVelocity = Vector3.zero
local foundation = part("FarmFoundation")
foundation.Size = Vector3.new(foundation.Size.X, foundation.Size.Y, 40)
moveTo(foundation, machineX, 124)
local pitDelta = 106.2 - localPosition(part("CollectionPit")).Z
for _, child in farm:GetChildren() do
	if not child:IsA("BasePart") then
		continue
	end
	local position = localPosition(child)
	if child.Name == "BeltRail" then
		child.Size = Vector3.new(child.Size.X, child.Size.Y, 32)
		moveTo(child, position.X, 124)
	elseif child.Name == "BeltLeg" then
		moveTo(child, position.X, if position.Z < 124 then 108.8 else 139.2)
	elseif child.Name == "CollectionPit" or string.sub(child.Name, 1, 3) == "Pit" then
		moveTo(child, position.X, position.Z + pitDelta)
	end
end
local collect = part("CollectPlate")
local collectShift =
	pivot:VectorToWorldSpace(Vector3.new(-30 - localPosition(collect).X, 0, 104 - localPosition(collect).Z))
collect.CFrame += collectShift
for _, child in collect:GetDescendants() do
	if child:IsA("BasePart") then
		child.CFrame += collectShift
	end
end

local producers = Instance.new("Folder")
producers.Name = "Producers"
producers.Parent = farm
for index = 2, 4 do
	local model = Instance.new("Model")
	model.Name = string.format("Dropper%02d", index)
	local shift = pivot:VectorToWorldSpace(Vector3.new(0, 0, SLOT_Z[index] - oldDropZ))
	for _, source in hopperParts do
		local copy = source:Clone()
		copy.CFrame += shift
		copy.Parent = model
	end
	local marker = drop:Clone()
	marker.CFrame += shift
	marker.Parent = model
	model.PrimaryPart = marker
	model.Parent = producers
end
local starterShift = pivot:VectorToWorldSpace(Vector3.new(0, 0, SLOT_Z[1] - oldDropZ))
drop.CFrame += starterShift
for _, item in hopperParts do
	item.CFrame += starterShift
end

local farmer = farm.Scenery:FindFirstChild("Farmer")
assert(farmer ~= nil and farmer:IsA("Model"), "Existing decorative farmer required")
local farmerPosition = pivot:PointToObjectSpace(farmer:GetPivot().Position)
farmer:PivotTo(
	CFrame.new(pivot:PointToWorldSpace(Vector3.new(machineX, farmerPosition.Y, 145))) * farmer:GetPivot().Rotation
)

local start = kingdom:FindFirstChild("FarmStartPlate")
assert(start ~= nil and start:IsA("BasePart"), "Existing styled Start Farm plate required")
local plates = Instance.new("Folder")
plates.Name = "PurchasePlates"
plates.Parent = kingdom
for index = 1, 3 do
	local plate = start:Clone()
	plate.Name = string.format("FarmDropper%02d", index + 1)
	local shift =
		pivot:VectorToWorldSpace(Vector3.new(-30 - localPosition(plate).X, 0, PLATE_Z[index] - localPosition(plate).Z))
	plate.CFrame += shift
	plate.Color = Color3.fromRGB(255, 45, 45)
	for _, descendant in plate:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CFrame += shift
		end
	end
	local label = plate:FindFirstChild("StartLabel", true)
	assert(label ~= nil and label:IsA("TextLabel"), "Start plate label required")
	label.Name = "PurchaseLabel"
	label.Text = string.format("Farm Dropper %d • %d Gold\nStart your farm first", index + 1, PRICES[index])
	local gui = label:FindFirstAncestorWhichIsA("BillboardGui")
	if gui ~= nil then
		gui.Size = UDim2.fromOffset(250, 66)
	end
	plate.Parent = plates
end

for _, item in kingdom:GetDescendants() do
	assert(not item:IsA("LuaSourceContainer"), "Template must be script-free")
	if item:IsA("BasePart") then
		assert(item.Anchored, "Template parts must be anchored")
	end
end
assert(#producers:GetChildren() == 3 and #plates:GetChildren() == 3, "Incomplete progression assets")
assert(kingdom:GetPivot() == original:GetPivot(), "Template pivot changed")
local backup = Instance.new("Folder")
backup.Name = BACKUP_NAME
backup.Parent = ServerStorage
original.Parent = backup
kingdom.Parent = ServerStorage
print("Four-dropper farm installed; original archived in " .. BACKUP_NAME)
print("Fixed 32-stud belt, four slots, one farmer, shared collector, three purchase plates. Save the Studio place.")
