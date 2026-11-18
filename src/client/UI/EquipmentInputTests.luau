--!strict
local Tests = {}
function Tests.Run(): ()
	local player = game:GetService("Players").LocalPlayer
	local deadline = os.clock() + 45
	local tool: Tool? = nil
	repeat
		local character = player.Character
		local found = if character then character:FindFirstChild("KingdomTrainingSword") else nil
		if found and found:IsA("Tool") and found:GetAttribute("VerifyClientActivation") == true then
			tool = found
			break
		end
		task.wait(0.05)
	until os.clock() >= deadline
	assert(tool, "Server sword activation fixture missing")
	local equipped = tool :: Tool
	local serial = equipped:GetAttribute("SwingSerial")
	equipped:Activate()
	local responseDeadline = os.clock() + 10
	repeat
		task.wait(0.05)
	until equipped:GetAttribute("SwingSerial") ~= serial or os.clock() >= responseDeadline
	assert(equipped:GetAttribute("SwingSerial") ~= serial, "Client activation bridge failed")
	print("All sword input bridge checks passed")
end
return Tests
