--!strict
local Tests = {}
function Tests.Run(): ()
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local holder = Instance.new("Folder")
	holder.Name, holder.Parent = "StaminaTestFixture", playerGui
	local view = require(script.Parent.StaminaView).Create(holder)
	local bar = (holder:FindFirstChild("KingdomStaminaHUD") :: ScreenGui):FindFirstChild("StaminaBar") :: CanvasGroup
	assert(not bar.Visible, "Unowned stamina shown")
	view.Set(true, 0.5)
	assert(bar.Visible and bar.GroupTransparency == 0, "Depleted bar not visible")
	assert((bar:FindFirstChild("Fill") :: Frame).Size.X.Scale == 0.5, "Incorrect stamina fill")
	view.Set(true, 1)
	local deadline = os.clock() + 5
	repeat
		task.wait(0.05)
	until bar.GroupTransparency >= 0.999 or os.clock() >= deadline
	assert(bar.GroupTransparency >= 0.999, "Full bar did not fade")
	view.Set(true, 0.9)
	assert(bar.GroupTransparency == 0, "Used stamina did not reappear")
	view.Set(false, 1)
	assert(not bar.Visible, "Revoked stamina remained visible")
	view.Destroy()
	holder:Destroy()
	print("All stamina HUD checks passed")
end
return Tests
