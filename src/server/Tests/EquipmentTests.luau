--!strict
-- Integration assertion called by OptionalAdditionsTests after sword purchase.
local Tests = {}
function Tests.Run(player: Player, Equipment: any): ()
	local character = player.Character :: Model
	local tool = player.Backpack:FindFirstChild("KingdomTrainingSword") :: Tool
	assert(tool and not tool.CanBeDropped, "Sword not granted")
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid:EquipTool(tool)
	assert(Equipment.TrySwing(player), "Equipped sword did not swing")
	assert(not Equipment.TrySwing(player), "Swing cooldown bypassed")
	local health = humanoid.Health
	task.wait(0.5)
	assert(humanoid.Health == health, "Training sword damaged owner")
	task.wait(0.3)
	local serial = tool:GetAttribute("SwingSerial")
	tool:SetAttribute("VerifyClientActivation", true)
	local deadline = os.clock() + 12
	repeat
		task.wait(0.05)
	until tool:GetAttribute("SwingSerial") ~= serial or os.clock() >= deadline
	assert(tool:GetAttribute("SwingSerial") ~= serial, "Client tool activation did not reach server")
	print("All training sword checks passed")
end
return Tests
