--!strict
-- One-time Edit recipe: clone the accepted lane, never regenerate its artwork.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Studio Edit only")
local storage = game:GetService("ServerStorage")
local backupName = "SecondRoyalMintBackup_20261117"
assert(not storage:FindFirstChild(backupName), "Second lane already installed; preserve backup")
assert(#workspace.ActiveKingdoms:GetChildren() == 0, "Release all kingdoms first")
local source = storage:FindFirstChild("KingdomTemplate") :: Model
assert(source and source:IsA("Model"), "Missing source template")
assert(not source.PurchaseUnlocks:FindFirstChild("RoyalMint02"), "Second lane already exists")
local copy = source:Clone()
local ok, reason = xpcall(function(): ()
	local pivot = copy:GetPivot()
	local unlocks = copy.PurchaseUnlocks
	local plates = copy.PurchasePlates
	local original = unlocks.RoyalMint :: Model
	local lane = original:Clone()
	lane.Name = "RoyalMint02"
	-- Share the existing paving, edging, lamps and sign. Clone only belt machinery.
	local keep = {
		ConveyorFrame = true,
		BeltRail = true,
		BeltLeg = true,
		FrameBolt = true,
		TroughSide = true,
		TroughTrim = true,
		TroughFloor = true,
		TroughFront = true,
		TroughFrontTrim = true,
	}
	for _, item in lane.Scenery:GetChildren() do
		if not keep[item.Name] then
			item:Destroy()
		end
	end
	local function translate(item: Instance): ()
		local delta = pivot:VectorToWorldSpace(Vector3.new(48, 0, 0))
		for _, child in item:GetDescendants() do
			assert(not child:IsA("LuaSourceContainer"), "Templates must remain script-free")
			if child:IsA("BasePart") then
				child.CFrame += delta
			end
		end
		if item:IsA("BasePart") then
			item.CFrame += delta
		end
	end
	translate(lane)
	lane.Parent = unlocks
	local function clonePlate(oldId: string, newId: string): ()
		assert(not plates:FindFirstChild(newId), "Conflicting plate " .. newId)
		local plate = plates[oldId]:Clone()
		plate.Name = newId
		translate(plate)
		plate.Parent = plates
	end
	clonePlate("RoyalMint", "RoyalMint02")
	-- The first-lane entry plate sits outside its machinery footprint. Put the
	-- second entry beside the second belt instead of translating it into the gate.
	local entry = plates.RoyalMint02 :: BasePart
	local destination = pivot:PointToWorldSpace(Vector3.new(-16, 0.8, 60))
	local entryDelta = destination - entry.Position
	entry.CFrame += entryDelta
	for _, child in entry:GetDescendants() do
		if child:IsA("BasePart") then
			child.CFrame += entryDelta
		end
	end
	for index = 1, 8 do
		if index > 1 then
			clonePlate(string.format("RoyalMintDropper%02d", index), string.format("RoyalMint02Dropper%02d", index))
		end
		local oldId = string.format("RoyalMintUpgrader%02d", index)
		local newId = string.format("RoyalMint02Upgrader%02d", index)
		assert(not unlocks:FindFirstChild(newId), "Conflicting arch")
		local arch = unlocks[oldId]:Clone()
		arch.Name = newId
		arch:SetAttribute("UpgraderId", newId)
		translate(arch)
		arch.Parent = unlocks
		clonePlate(oldId, newId)
	end
	-- Normalize row plates to their accepted lamp-clearance positions. Absolute
	-- local X avoids a second shift when the source lane was already corrected.
	for _, row in { { Prefix = "RoyalMint", X = -68 }, { Prefix = "RoyalMint02", X = -20 } } do
		for index = 1, 8 do
			local ids = { string.format("%sUpgrader%02d", row.Prefix, index) }
			if index > 1 then
				table.insert(ids, string.format("%sDropper%02d", row.Prefix, index))
			end
			for _, id in ids do
				local plate = plates[id] :: BasePart
				local localPosition = pivot:PointToObjectSpace(plate.Position)
				local delta = pivot:VectorToWorldSpace(Vector3.new(row.X - localPosition.X, 0, 0))
				plate.CFrame += delta
				for _, child in plate:GetDescendants() do
					if child:IsA("BasePart") then
						child.CFrame += delta
					end
				end
			end
		end
	end
	-- Every rotated corner must remain in the existing yard; entry plate is outside
	-- the yard at the approach, matching the original lane's purchase convention.
	for _, item in lane:GetDescendants() do
		if item:IsA("BasePart") then
			assert(item.Anchored, "Unanchored cloned asset")
			for _, x in { -1, 1 } do
				for _, y in { -1, 1 } do
					for _, z in { -1, 1 } do
						local point = pivot:PointToObjectSpace(
							item.CFrame:PointToWorldSpace(item.Size * Vector3.new(x, y, z) / 2)
						)
						assert(
							point.X >= -100.1 and point.X <= -11.9 and point.Z >= -76.1 and point.Z <= 52.1,
							"Clone outside yard: " .. item.Name
						)
					end
				end
			end
		end
	end
	assert(math.abs(pivot:PointToObjectSpace(lane.Conveyor.Position).X + 32) < 0.01, "Wrong lane center")
	assert(lane.Conveyor.Size == original.Conveyor.Size, "Belt size changed")
end, debug.traceback)
if not ok then
	copy:Destroy()
	error(reason)
end
local backup = Instance.new("Folder")
backup.Name = backupName
backup.Parent = storage
source.Parent = backup
copy.Parent = storage
print("Second Royal Mint asset checks passed (cloned belt, eight presses, eight arches)")
print("Installed RoyalMint02; original retained in ServerStorage." .. backupName)
