--!strict
local Tests = {}
function Tests.Config(config: any): ()
	assert(config.SWING_ANIMATION_ID == "rbxassetid://567479941", "Free SideSwipe animation not configured")
	assert(config.SWING_COOLDOWN == 0.65, "Existing cooldown changed")
	assert(config.REST_GRIP == CFrame.identity, "Upright resting grip changed")
	assert(config.ANIMATION_PRIORITY == Enum.AnimationPriority.Action, "Swing must blend over normal movement")
	assert(config.ANIMATION_FADE > 0, "Missing blend time")
	print("All sword animation config checks passed")
end
function Tests.Playing(humanoid: Humanoid): AnimationTrack
	local animator = humanoid:FindFirstChildOfClass("Animator")
	assert(animator, "Missing server Animator")
	for _, track in animator:GetPlayingAnimationTracks() do
		if track.Animation and track.Animation.AnimationId == "rbxassetid://567479941" then
			assert(track.Priority == Enum.AnimationPriority.Action and not track.Looped, "Invalid swing playback")
			assert(track.Length > 0, "Animation content did not load")
			return track
		end
	end
	error("Free SideSwipe track did not play")
end
return Tests
