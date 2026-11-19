--!strict
-- Studio authoring check; not Rojo-mapped. Run after the build recipe.
local clip = game:GetService("ServerStorage"):FindFirstChild("KingdomEvadeSprintR15")
assert(clip and clip:IsA("KeyframeSequence"), "Build the R15 sprint clip first")
assert(clip.Loop and clip.Priority == Enum.AnimationPriority.Movement, "Incorrect playback contract")
local frames = clip:GetKeyframes()
table.sort(frames, function(a, b)
	return a.Time < b.Time
end)
assert(#frames == 25 and math.abs(frames[#frames].Time - 0.65) < 0.001, "Source timing changed")
local first: { [string]: CFrame } = {}
for _, p in frames[1]:GetDescendants() do
	if p:IsA("Pose") then
		first[p.Name] = p.CFrame
	end
end
local minRoll, maxRoll = math.huge, -math.huge
for _, f in frames do
	local count = 0
	for _, p in f:GetDescendants() do
		if p:IsA("Pose") then
			count += 1
			assert(not string.find(p.Name, " "), "R6 joint leaked into R15 clip")
			if f == frames[#frames] then
				assert(p.CFrame == first[p.Name], "Loop seam mismatch: " .. p.Name)
			end
		end
	end
	assert(count == 16, "Incomplete R15 pose hierarchy")
	local lower, upper = f:FindFirstChild("LowerTorso", true), f:FindFirstChild("UpperTorso", true)
	assert(lower and lower:IsA("Pose") and upper and upper:IsA("Pose"), "Missing body poses")
	local _, _, roll = (lower.CFrame * upper.CFrame):ToOrientation()
	minRoll, maxRoll = math.min(minRoll, roll), math.max(maxRoll, roll)
end
assert(math.deg(maxRoll - minRoll) > 11, "Sway fell back to the stiff run")
print("All Evade R15 sprint asset checks passed")
