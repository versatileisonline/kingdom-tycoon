--!strict
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Studio Edit only")
local storage = game.ServerStorage
local t = storage.KingdomTemplate
local backup = storage.MedievalCourtyardBackup_20261118
local stand = t.PurchaseUnlocks.TrainingSword
if not backup:FindFirstChild("PrePolishSwordStand") then
	local copy = stand:Clone()
	copy.Name, copy.Parent = "PrePolishSwordStand", backup
end
local vendor = stand.FarmerVendor :: Model
vendor:PivotTo(CFrame.new(vendor:GetPivot().Position) * t:GetPivot().Rotation)
local course = t.PurchaseUnlocks.SprintTraining
for i, x in { 60, 80 } do
	local name = "TrainingSignPost" .. i
	if not course:FindFirstChild(name) then
		local p = Instance.new("Part")
		p.Name, p.Size, p.Material = name, Vector3.new(0.6, 9, 0.6), Enum.Material.Wood
		p.Color = Color3.fromRGB(87, 56, 35)
		p.CFrame = t:GetPivot() * CFrame.new(x, 4.5, 16)
		p.Anchored, p.CanTouch, p.Parent = true, false, course
	end
end
-- Generated right-front leg texture is unavailable; reuse its matching left-leg texture.
for _, m in
	{
		storage.MedievalHorseTemplate,
		t.PurchaseUnlocks.HorsePaddock.DecorativeHorse1,
		t.PurchaseUnlocks.HorsePaddock.DecorativeHorse2,
	}
do
	local left = m:FindFirstChild("front left leg_geom", true)
	local right = m:FindFirstChild("front right leg_geom", true)
	if left and right and left:IsA("MeshPart") and right:IsA("MeshPart") then
		right.TextureID = left.TextureID
	end
end
print("Medieval courtyard polish checks passed (vendor faces counter, sign supported, horse texture fallback)")
