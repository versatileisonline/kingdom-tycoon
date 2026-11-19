--!strict
-- One-time Studio asset recipe; never Rojo-mapped or run during gameplay.
-- Inspect free Creator Store model74987847468722 in ServerStorage under the name
-- SprintAnimationCandidate_Evade first. Only its Run keyframes and bind joints
-- are read. The imported rig is never executed or installed as player controls.
local TORSO_SWAY_GAIN = 2.6
local storage = game:GetService("ServerStorage")
local source = storage:FindFirstChild("SprintAnimationCandidate_Evade")
assert(source, "Insert the inspected Evade animation source first")
assert(not storage:FindFirstChild("KingdomEvadeSprintR15"), "R15 sprint already built; preserve existing work")
local rig = source:FindFirstChild("EvadeAnimations")
assert(rig and rig:IsA("Model"), "Missing EvadeAnimations rig")
local run = rig:FindFirstChild("Run", true)
assert(run and run:IsA("KeyframeSequence"), "Missing source Run sequence")
local joints: { [string]: Motor6D } = {}
for _, part in rig:GetChildren() do
	if part:IsA("BasePart") then
		for _, joint in part:GetChildren() do
			if joint:IsA("Motor6D") and joint.Part1 then
				joints[joint.Part1.Name] = joint
			end
		end
	end
end
local frames = run:GetKeyframes()
table.sort(frames, function(a, b)
	return a.Time < b.Time
end)
assert(#frames > 1 and frames[1].Time == 0, "Source must begin at zero")
local clip = Instance.new("KeyframeSequence")
clip.Name, clip.Loop, clip.Priority = "KingdomEvadeSprintR15", true, Enum.AnimationPriority.Movement
clip:SetAttribute("SourceAssetId", "74987847468722")
clip:SetAttribute("SourceCreator", "wifonn3")
clip:SetAttribute("Adaptation", "R6 joint bases to R15; split torso sway, connected limbs, closed loop")

local function pose(parent: Instance, name: string, cf: CFrame, weight: number?): Pose
	local p = Instance.new("Pose")
	p.Name, p.CFrame, p.Weight = name, cf, weight or 1
	p.EasingStyle, p.EasingDirection = Enum.PoseEasingStyle.Linear, Enum.PoseEasingDirection.InOut
	p.Parent = parent
	return p
end

local function rotation(poses: { [string]: Pose }, name: string): CFrame
	local joint, p = joints[name], poses[name]
	assert(joint and p, "Missing source joint/pose: " .. name)
	-- R6 joint axes differ from R15. Convert the keyed rotation into the body's
	-- local axes instead of copying CFrames (which twists R15 shoulders/hips).
	return joint.C0.Rotation * p.CFrame.Rotation * joint.C1.Rotation:Inverse()
end

local minRoll, maxRoll = math.huge, -math.huge
for _, frame in frames do
	local poses: { [string]: Pose } = {}
	for _, p in frame:GetDescendants() do
		if p:IsA("Pose") then
			poses[p.Name] = p
		end
	end
	local _, _, roll = rotation(poses, "Torso"):ToOrientation()
	minRoll, maxRoll = math.min(minRoll, roll), math.max(maxRoll, roll)
end
local rollCenter = (minRoll + maxRoll) / 2

for index, frame in frames do
	-- The final key repeats the first pose exactly, avoiding a snap at wraparound.
	local keyed = if index == #frames then frames[1] else frame
	local poses: { [string]: Pose } = {}
	for _, p in keyed:GetDescendants() do
		if p:IsA("Pose") then
			poses[p.Name] = p
		end
	end
	local rootJoint, torso = joints.Torso, poses.Torso
	assert(rootJoint and torso, "Missing root joint")
	local authored = rotation(poses, "Torso")
	local pitch, yaw, roll = authored:ToOrientation()
	-- Amplify the source's alternating roll around its center, retaining the
	-- authored lean and timing rather than introducing a permanent side tilt.
	local body = CFrame.fromOrientation(pitch, yaw, rollCenter + (roll - rollCenter) * TORSO_SWAY_GAIN)
	local pelvisRotation = CFrame.new():Lerp(body, 0.45)
	local rootOffset = rootJoint.C0.Rotation:VectorToWorldSpace(torso.CFrame.Position)
	-- Keep the authored rhythmic lean/sway; bound the root offset so it stays a
	-- visual motion and does not put the avatar's feet far below its collider.
	local offset = Vector3.new(rootOffset.X * 1.3, rootOffset.Y * 0.35, rootOffset.Z * 0.35)
	local key = Instance.new("Keyframe")
	key.Time, key.Name, key.Parent = frame.Time, frame.Name, clip
	local root = pose(key, "HumanoidRootPart", CFrame.identity, 0)
	local pelvis = pose(root, "LowerTorso", CFrame.new(offset) * pelvisRotation)
	local upper = pose(pelvis, "UpperTorso", pelvisRotation:Inverse() * body)
	pose(upper, "Head", rotation(poses, "Head"))
	for _, side in { "Left", "Right" } do
		local arm = pose(upper, side .. "UpperArm", rotation(poses, side .. " Arm"))
		local forearm = pose(arm, side .. "LowerArm", CFrame.Angles(math.rad(-18), 0, 0))
		pose(forearm, side .. "Hand", CFrame.identity)
		local legRotation = rotation(poses, side .. " Leg")
		local leg = pose(pelvis, side .. "UpperLeg", pelvisRotation:Inverse() * body * legRotation)
		-- R6 has no knees; add a small bend on the recovering stride for R15.
		local legPitch = select(1, legRotation:ToOrientation())
		local knee = math.rad(8) + math.max(0, -legPitch) * 0.45
		local shin = pose(leg, side .. "LowerLeg", CFrame.Angles(knee, 0, 0))
		pose(shin, side .. "Foot", CFrame.Angles(-knee * 0.35, 0, 0))
	end
end
clip.Parent = storage
print("Evade R15 sprint prepared: " .. #frames .. " keys, " .. frames[#frames].Time .. "s; source preserved")
return clip
