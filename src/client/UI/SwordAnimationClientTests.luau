--!strict
local Tests = {}
function Tests.Run(): ()
	local player = game:GetService("Players").LocalPlayer
	local Shared = game:GetService("ReplicatedStorage").Shared
	local config = require(Shared.EquipmentConfig)
	local character = player.Character :: Model
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local found = character:FindFirstChild(config.TEMPLATE_NAME) or player.Backpack:FindFirstChild(config.TEMPLATE_NAME)
	assert(found and found:IsA("Tool"), "Use owned sword in Mock preview")
	local tool = found :: Tool
	local health = humanoid.Health
	local animator = humanoid:FindFirstChildOfClass("Animator") :: Animator
	humanoid:EquipTool(tool)
	task.wait(config.SWING_COOLDOWN + 0.2)
	local serial = tool:GetAttribute("SwingSerial")
	local previous = if typeof(serial) == "number" then serial else 0
	tool:Activate()
	task.wait(0.15)
	assert(tool:GetAttribute("SwingSerial") == previous + 1, "Client swing was not accepted")
	local selected: AnimationTrack? = nil
	local matches = 0
	for _, track in animator:GetPlayingAnimationTracks() do
		if track.Animation.AnimationId == config.SWING_ANIMATION_ID then
			matches += 1
			selected = track
		end
	end
	assert(matches == 1 and selected and selected.Length > 0, "Expected one loaded sword animation")
	assert((selected :: AnimationTrack).Priority == Enum.AnimationPriority.Action, "Wrong animation priority")
	assert(not (selected :: AnimationTrack).Looped, "Sword animation loops")
	assert(tool.Grip == config.REST_GRIP, "Swing rotated the resting grip")
	tool:Activate()
	task.wait(0.08)
	assert(tool:GetAttribute("SwingSerial") == previous + 1, "Swing cooldown was bypassed")
	humanoid:UnequipTools()
	task.wait(config.ANIMATION_FADE + 0.1)
	assert(not (selected :: AnimationTrack).IsPlaying, "Unequipped sword animation kept playing")
	assert(humanoid.Health == health, "Sword caused damage")
	task.wait(config.SWING_COOLDOWN)
	humanoid:EquipTool(tool)
	tool:Activate()
	task.wait(0.15)
	local restarts = 0
	for _, track in animator:GetPlayingAnimationTracks() do
		if track.Animation.AnimationId == config.SWING_ANIMATION_ID then
			restarts += 1
		end
	end
	assert(restarts == 1, "Reequip stacked animation tracks")
	task.wait(0.6)
	assert(tool.Grip == config.REST_GRIP, "Upright grip not restored")
	print("All free sword animation checks passed")
end
return Tests
