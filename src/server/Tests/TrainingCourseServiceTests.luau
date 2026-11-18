--!strict
-- Runs against the opted-in hands-on fixture after SprintTraining has been granted.
local Tests = {}
function Tests.Run(): ()
	local Players = game:GetService("Players")
	local Plots = require(script.Parent.Parent.Services.PlotService)
	local Data = require(script.Parent.Parent.Services.DataService)
	assert(Data.GetStorageMode() == "Mock", "Mock only")
	local deadline = os.clock() + 40
	local owner: Player?
	local course: Model?
	repeat
		owner = Players:GetPlayers()[1]
		local kingdom = if owner then Plots.GetKingdom(owner) else nil
		local unlocks = if kingdom then kingdom:FindFirstChild("PurchaseUnlocks") else nil
		course = if unlocks then unlocks:FindFirstChild("SprintTraining") :: Model? else nil
		if course then
			break
		end
		task.wait(0.1)
	until os.clock() > deadline
	assert(owner and owner.Character and course, "Use the course hands-on fixture")
	local p = owner :: Player
	local character = p.Character :: Model
	local m = course :: Model
	local zones = m:FindFirstChild("CourseZones") :: Folder
	local function move(name: string): ()
		local part = zones:FindFirstChild(name) :: BasePart
		character:PivotTo(part.CFrame)
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
		root.AssemblyLinearVelocity = Vector3.zero
		task.wait(0.25)
	end
	move("Start")
	assert(p:GetAttribute("CourseActive") == true, "Start failed")
	move("Finish")
	assert(p:GetAttribute("CourseActive") == true, "Early finish accepted")
	move("Checkpoint1")
	assert(p:GetAttribute("CourseCheckpoint") == 1, "Checkpoint failed")
	local started = p:GetAttribute("CourseStarted")
	character:PivotTo(m:GetPivot() * CFrame.new(0, 3, 0))
	task.wait(1)
	assert(p:GetAttribute("CourseStarted") == started, "Fall restarted timer")
	local checkpoint = zones:FindFirstChild("Checkpoint1") :: BasePart
	assert((character:GetPivot().Position - checkpoint.Position).Magnitude < 8, "Fall did not recover to checkpoint")
	move("Checkpoint2")
	move("Checkpoint3")
	move("Finish")
	assert(
		p:GetAttribute("CourseActive") == false and typeof(p:GetAttribute("CourseBest")) == "number",
		"Finish failed"
	)
	local best = p:GetAttribute("CourseBest")
	move("Start")
	assert(p:GetAttribute("CourseActive") == true, "Retry failed")
	p:SetAttribute("CourseMenuOpen", true)
	task.wait(0.2)
	assert(p:GetAttribute("CourseActive") == false and p:GetAttribute("CourseBest") == best, "Menu cancel lost best")
	p:SetAttribute("CourseMenuOpen", false)
	character:PivotTo(m:GetPivot() * CFrame.new(0, 3, 28))
	print("All medieval course service checks passed")
end
return Tests
