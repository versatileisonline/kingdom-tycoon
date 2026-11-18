--!strict
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.TrainingCourseConfig)
local State = require(script.Parent.Parent.Training.CourseState)
local Data = require(script.Parent.DataService)
local Plots = require(script.Parent.PlotService)
local Service = {}
type Record = { Kingdom: Model, Course: Model?, Run: State.Run, LastRecovery: number }
local records: { [Player]: Record } = {}
local connections: { RBXScriptConnection } = {}
local unsubscribe: (() -> ())?
local started = false
local function publish(player: Player, record: Record?): ()
	local run = if record then record.Run else nil
	player:SetAttribute("CourseActive", run ~= nil and run.Active)
	player:SetAttribute("CourseStarted", if run then run.Started else nil)
	player:SetAttribute("CourseCheckpoint", if run then run.Checkpoint else nil)
	player:SetAttribute("CourseBest", if run then run.Best else nil)
	player:SetAttribute("CourseResult", if run then run.Result else nil)
end
local function inside(part: BasePart, position: Vector3, tolerance: number): boolean
	local v = part.CFrame:PointToObjectSpace(position)
	local h = part.Size / 2 + Vector3.new(tolerance, tolerance, tolerance)
	return math.abs(v.X) <= h.X and math.abs(v.Y) <= h.Y and math.abs(v.Z) <= h.Z
end
local function zone(course: Model, name: string): BasePart?
	local zones = course:FindFirstChild("CourseZones")
	local found = if zones then zones:FindFirstChild(name) else nil
	return if found and found:IsA("BasePart") then found else nil
end
local function tickPlayer(player: Player, record: Record): ()
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if humanoid then humanoid.RootPart else nil
	local data = Data.GetSnapshot(player)
	local unlocks = record.Kingdom:FindFirstChild("PurchaseUnlocks")
	local course = if unlocks then unlocks:FindFirstChild(Config.PURCHASE_ID) else nil
	local valid = data
		and data.PurchasedBuildings[Config.PURCHASE_ID] == true
		and course
		and course:IsA("Model")
		and humanoid
		and humanoid.Health > 0
		and root
		and not Plots.IsResetting(player)
		and player:GetAttribute("KingdomEntered") ~= false
	local run = record.Run
	if not valid then
		if run.Active then
			State.Cancel(run)
			publish(player, record)
		end
		return
	end
	local model = course :: Model
	local position = (root :: BasePart).Position
	local bounds = zone(model, "Bounds")
	local start = zone(model, "Start")
	local finish = zone(model, "Finish")
	if not bounds or not start or not finish then
		return
	end
	local now = workspace:GetServerTimeNow()
	local menu = player:GetAttribute("CourseMenuOpen") == true
	if
		run.Active
		and (
			menu
			or not inside(bounds, position, 0)
			or now - run.Started > Config.TIMEOUT
			or (humanoid :: Humanoid).Sit
		)
	then
		State.Cancel(run)
		publish(player, record)
		return
	end
	if menu then
		return
	end
	if not run.Active then
		-- Leaving the start area is required before a finished/cancelled retry.
		if not inside(start, position, 0) then
			record.LastRecovery = 0
		end
		if record.LastRecovery ~= 0 or not inside(start, position, 0) then
			return
		end
		State.Start(run, now)
		record.LastRecovery = now
		publish(player, record)
	end
	for index = 1, Config.CHECKPOINTS do
		local checkpoint = zone(model, "Checkpoint" .. index)
		if checkpoint and inside(checkpoint, position, 0) and State.Checkpoint(run, index) then
			publish(player, record)
		end
	end
	if inside(finish, position, 0) and State.Finish(run, now, Config.CHECKPOINTS) then
		record.LastRecovery = now
		publish(player, record)
		return
	end
	-- Only recover after landing on the ground below the elevated route.
	local localPosition = model:GetPivot():PointToObjectSpace(position)
	local ground = model:GetAttribute("FallRootY")
	if
		typeof(ground) == "number"
		and localPosition.Y < ground
		and now - record.LastRecovery >= Config.RECOVERY_COOLDOWN
	then
		local destination = if run.Checkpoint == 0 then start else zone(model, "Checkpoint" .. run.Checkpoint)
		if destination then
			local actualRoot = root :: BasePart
			local actualCharacter = character :: Model
			actualRoot.AssemblyLinearVelocity = Vector3.zero
			actualRoot.AssemblyAngularVelocity = Vector3.zero
			actualCharacter:PivotTo(destination.CFrame + Vector3.new(0, Config.RECOVERY_LIFT, 0))
			record.LastRecovery = now
		end
	end
end
function Service.Init(): () end
function Service.Start(): ()
	if started then
		return
	end
	started = true
	unsubscribe = Plots.ObserveKingdoms(function(player, kingdom)
		records[player] = { Kingdom = kingdom, Course = nil, Run = State.New(), LastRecovery = 0 }
		publish(player, records[player])
	end, function(player)
		records[player] = nil
		publish(player, nil)
	end)
	-- Menu state is cancellation-only: no economy or movement authority is granted.
	local folder = Instance.new("Folder")
	folder.Name = "KingdomTrainingCourse"
	local menu = Instance.new("RemoteEvent")
	menu.Name, menu.Parent = "Menu", folder
	folder.Parent = game:GetService("ReplicatedStorage")
	local last: { [Player]: number } = {}
	table.insert(
		connections,
		menu.OnServerEvent:Connect(function(player: Player, opened: unknown, ...: any)
			if typeof(opened) ~= "boolean" or select("#", ...) ~= 0 then
				return
			end
			local now = os.clock()
			if opened ~= true and now - (last[player] or -math.huge) < 0.1 then
				return
			end
			last[player] = now
			player:SetAttribute("CourseMenuOpen", opened)
		end)
	)
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			last[player] = nil
			records[player] = nil
		end)
	)
	task.spawn(function()
		while started do
			task.wait(Config.TICK)
			for player, record in records do
				tickPlayer(player, record)
			end
		end
	end)
	game:BindToClose(function()
		started = false
		if unsubscribe then
			unsubscribe()
		end
		for _, connection in connections do
			connection:Disconnect()
		end
		for player in records do
			publish(player, nil)
		end
		table.clear(records)
		folder:Destroy()
	end)
	print("[KingdomTycoon][TrainingCourseService] Ready")
end
return Service
