--!strict
-- Approved repeat-safe Edit repair: clone the exact authored dropper plate.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Studio Edit only")
local storage = game:GetService("ServerStorage")
local template = storage:FindFirstChild("KingdomTemplate") :: Model
assert(template, "Missing KingdomTemplate")
local plates = template:FindFirstChild("PurchasePlates") :: Folder
assert(plates, "Missing PurchasePlates")
local reference = plates:FindFirstChild("RoyalMintDropper02") :: BasePart
assert(reference and reference:FindFirstChild("Outline"), "Missing standard dropper plate")
local ids = { "RoyalBanners", "RoyalLanterns", "TrainingSword", "SprintTraining", "HorsePaddock", "RoyalFountain" }
local backupName = "OptionalPlateStyleBackup_20261118"
local originals: { BasePart } = {}
local replacements: { BasePart } = {}
for _, id in ids do
	local existing = plates:FindFirstChild(id) :: BasePart
	assert(existing and existing:IsA("BasePart"), "Missing optional plate " .. id)
	if existing:GetAttribute("UsesDropperPlateTemplate") == true then
		continue
	end
	local copy = reference:Clone()
	local original = copy.CFrame
	local destination = CFrame.new(existing.Position) * reference.CFrame.Rotation
	for _, item in copy:GetDescendants() do
		if item:IsA("BasePart") then
			item.CFrame = destination * original:ToObjectSpace(item.CFrame)
		end
	end
	copy.CFrame, copy.Name = destination, id
	copy:SetAttribute("UsesDropperPlateTemplate", true)
	local label = copy:FindFirstChild("PurchaseLabel", true) :: TextLabel
	local oldLabel = existing:FindFirstChild("PurchaseLabel", true) :: TextLabel
	assert(label and oldLabel, "Missing purchase label")
	label.Text = oldLabel.Text
	assert(copy.Size == reference.Size and copy.Material == reference.Material, "Face style mismatch")
	local rim = copy:FindFirstChild("Outline") :: BasePart
	local sourceRim = reference:FindFirstChild("Outline") :: BasePart
	assert(rim.Size == sourceRim.Size and rim.Color == sourceRim.Color, "Rim style mismatch")
	assert(not rim.CanCollide and not rim.CanTouch and not rim.CanQuery, "Interactive rim")
	assert(
		(copy.CFrame:ToObjectSpace(rim.CFrame).Position - reference.CFrame:ToObjectSpace(sourceRim.CFrame).Position).Magnitude
			< 0.001,
		"Rim offset mismatch"
	)
	table.insert(originals, existing)
	table.insert(replacements, copy)
end
if #originals == 0 then
	print("Optional purchase plates already match dropper template (6 checked)")
	return
end
assert(not storage:FindFirstChild(backupName), "Backup exists; inspect partial repair before continuing")
local backup = Instance.new("Folder")
backup.Name = backupName
backup.Parent = storage
for _, p in originals do
	p.Parent = backup
end
for _, p in replacements do
	p.Parent = plates
end
print(string.format("Optional purchase plate style checks passed (%d repaired; exact dropper template)", #replacements))
print("Previous optional plates retained in ServerStorage." .. backupName)
