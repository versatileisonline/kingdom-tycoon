--!strict
-- Repeat-safe Edit recipe for existing two-lane templates. No runtime mutations.
local run = game:GetService("RunService")
assert(run:IsStudio() and not run:IsRunning(), "Studio Edit only")
assert(#workspace.ActiveKingdoms:GetChildren() == 0, "Release kingdoms before replacing the template")
local storage = game:GetService("ServerStorage")
local source = storage:FindFirstChild("KingdomTemplate") :: Model
assert(source and source:IsA("Model"), "Missing KingdomTemplate")
local pivot = source:GetPivot()
local plates = source:FindFirstChild("PurchasePlates")
assert(plates, "Missing PurchasePlates")
local targets: { [string]: number } = {}
local changes = 0
for _, row in { { Prefix = "RoyalMint", OldX = -64, X = -68 }, { Prefix = "RoyalMint02", OldX = -16, X = -20 } } do
	for index = 1, 8 do
		local ids = { string.format("%sUpgrader%02d", row.Prefix, index) }
		if index > 1 then
			table.insert(ids, string.format("%sDropper%02d", row.Prefix, index))
		end
		for _, id in ids do
			local plate = plates:FindFirstChild(id)
			assert(plate and plate:IsA("BasePart") and plate.Anchored, "Missing anchored plate " .. id)
			local x = pivot:PointToObjectSpace(plate.Position).X
			assert(math.abs(x - row.OldX) < 0.01 or math.abs(x - row.X) < 0.01, "Unexpected plate position: " .. id)
			targets[id] = row.X
			if math.abs(x - row.X) > 0.01 then
				changes += 1
			end
		end
	end
end
if changes == 0 then
	print("Mint purchase plates already clear lamps (30 checked, no changes)")
	return
end
local backupName = "MintPlateClearanceBackup_20261117"
assert(not storage:FindFirstChild(backupName), "Backup exists but positions differ; inspect before changing")
local copy = source:Clone()
local ok, reason = xpcall(function(): ()
	local copyPlates = copy.PurchasePlates
	for id, x in targets do
		local plate = copyPlates[id] :: BasePart
		local position = pivot:PointToObjectSpace(plate.Position)
		local delta = pivot:VectorToWorldSpace(Vector3.new(x - position.X, 0, 0))
		plate.CFrame += delta
		for _, child in plate:GetDescendants() do
			if child:IsA("BasePart") then
				child.CFrame += delta
			end
		end
		local after = pivot:PointToObjectSpace(plate.Position)
		assert(
			math.abs(after.X - x) < 0.01
				and math.abs(after.Y - position.Y) < 0.01
				and math.abs(after.Z - position.Z) < 0.01,
			"Plate translation failed"
		)
	end
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
print(string.format("Mint purchase plate clearance checks passed (30 checked, %d moved)", changes))
print("Original template retained in ServerStorage." .. backupName)
