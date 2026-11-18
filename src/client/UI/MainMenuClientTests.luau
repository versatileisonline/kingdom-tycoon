--!strict
local Tests = {}
function Tests.Run(): ()
	local parent = Instance.new("Folder")
	local view = require(script.Parent.MainMenuView).new(parent)
	local ok, reason = pcall(function()
		assert(view.Screen.ResetOnSpawn == false, "Menu must survive pre-entry respawn")
		assert(view.Play.Text == "PLAY" and view.Settings.Text == "SETTINGS", "Missing menu actions")
		assert(view.Panel.Title.Text == require(game.ReplicatedStorage.Shared.MainMenuConfig).TITLE, "Wrong title")
		assert(
			view.Play.NextSelectionDown == view.Settings and view.Settings.NextSelectionUp == view.Play,
			"Broken gamepad navigation"
		)
		assert(not view.Play:FindFirstChildOfClass("UICorner"), "Menu should have square corners")
	end)
	view.Screen:Destroy()
	parent:Destroy()
	assert(ok, tostring(reason))
	print("All main menu client checks passed")
end
return Tests
