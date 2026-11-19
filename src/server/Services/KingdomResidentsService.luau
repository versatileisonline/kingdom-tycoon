--!strict
local SS = game:GetService("ServerStorage")
local Physics = game:GetService("PhysicsService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.StrongholdConfig)
local Data = require(script.Parent.DataService)
local Plots = require(script.Parent.PlotService)
local Service = {}
type Record = { Kingdom: Model, Rigs: { Model }, Added: { [string]: boolean }, Active: boolean }
local records: { [Player]: Record } = {}
local group = "KingdomResidents"
local isolationDirty = false
local isolateResidents: (() -> ())? = nil
local function clear(r: Record): ()
	r.Active = false
	for _, rig in r.Rigs do
		rig:Destroy()
	end
	table.clear(r.Rigs)
end
local function spawnRig(r: Record, role: string, frame: CFrame, walking: boolean): Model?
	if #r.Rigs >= Config.MAX_CHARACTERS then
		return nil
	end
	local templates = SS.KingdomTemplate:FindFirstChild("ResidentTemplates")
	local source = templates and templates:FindFirstChild(role)
	if not source or not source:IsA("Model") then
		warn("[KingdomTycoon][KingdomResidentsService] Missing " .. role)
		return nil
	end
	local rig = source:Clone()
	rig.Name = role .. (#r.Rigs + 1)
	local h = rig:FindFirstChildOfClass("Humanoid")
	local root = rig:FindFirstChild("HumanoidRootPart")
	if not h or not root or not root:IsA("BasePart") then
		rig:Destroy()
		return nil
	end
	h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	h.WalkSpeed = Config.WALK_SPEED
	h.BreakJointsOnDeath = false
	for _, v in rig:GetDescendants() do
		if v:IsA("BasePart") then
			v.CollisionGroup = group
			v.CanTouch = false
			v.CanCollide = walking and v.Name == "HumanoidRootPart"
			v.Anchored = v == root and not walking
		end
	end
	rig:PivotTo(frame)
	rig.Parent = r.Kingdom
	if walking then
		root:SetNetworkOwner(nil)
	end
	local animator = h:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = h
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = if walking then Config.WALK_ANIMATION else Config.IDLE_ANIMATION
	local ok, track = pcall(function()
		return (animator :: Animator):LoadAnimation(animation)
	end)
	animation:Destroy()
	if ok then
		track.Looped = true
		track:Play()
	else
		warn("[KingdomTycoon][KingdomResidentsService] Animation unavailable")
	end
	table.insert(r.Rigs, rig)
	isolationDirty = true
	task.defer(function()
		if isolateResidents then
			isolateResidents()
		end
	end)
	return rig
end
local function walk(r: Record, rig: Model, points: { Vector3 }, offset: number): ()
	task.spawn(function()
		task.wait(offset * 0.35)
		local h = rig:FindFirstChildOfClass("Humanoid")
		local index = 2
		while r.Active and rig.Parent and h and h.Health > 0 do
			local target = points[index]
			local completed = false
			local reached = false
			local connection = h.MoveToFinished:Connect(function(success)
				reached = success
				completed = true
			end)
			h:MoveTo(target)
			local deadline = os.clock() + Config.ROUTE_TIMEOUT
			while r.Active and rig.Parent and not completed and os.clock() < deadline do
				task.wait(0.25)
			end
			connection:Disconnect()
			if not r.Active or not rig.Parent then
				break
			end
			if not reached then
				rig:PivotTo(CFrame.new(points[1]))
				local root = h.RootPart
				if root then
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
				end
				index = 2
			else
				index = index % #points + 1
			end
			task.wait(Config.ROUTE_PAUSE)
		end
	end)
end
local function refresh(owner: Player): ()
	local r = records[owner]
	if not r or not r.Active or Plots.IsResetting(owner) then
		return
	end
	local data = Data.GetSnapshot(owner)
	local unlocks = r.Kingdom:FindFirstChild("PurchaseUnlocks")
	if not data or not unlocks then
		return
	end
	for _, id in { "ArcherPosts", "KingdomResidents" } do
		local model = unlocks:FindFirstChild(id)
		if data.PurchasedBuildings[id] == true and model and not r.Added[id] then
			r.Added[id] = true
			local placements = model:FindFirstChild("Placements")
			if placements then
				local sorted = placements:GetChildren()
				table.sort(sorted, function(a, b)
					return a.Name < b.Name
				end)
				for _, marker in sorted do
					if marker:IsA("BasePart") then
						spawnRig(r, if id == "ArcherPosts" then "Archer" else "Worker", marker.CFrame, false)
					end
				end
			end
			local routes = model:FindFirstChild("Routes")
			if routes then
				local sorted = routes:GetChildren()
				table.sort(sorted, function(a, b)
					return a.Name < b.Name
				end)
				for i, route in sorted do
					local nodes = route:GetChildren()
					table.sort(nodes, function(a, b)
						return a.Name < b.Name
					end)
					local points = {}
					for _, node in nodes do
						if node:IsA("BasePart") then
							table.insert(points, node.Position)
						end
					end
					if #points >= 2 then
						local rig = spawnRig(r, "Villager", CFrame.new(points[1]), true)
						if rig then
							walk(r, rig, points, i)
						end
					end
				end
			end
		end
	end
end
function Service.Init(): ()
	if not Physics:IsCollisionGroupRegistered(group) then
		Physics:RegisterCollisionGroup(group)
	end
	-- NPC roots stand on the world, but never block characters or each other.
	Physics:CollisionGroupSetCollidable(group, group, false)
end
function Service.Start(): ()
	local unsubscribe = Plots.ObserveKingdoms(function(owner, kingdom)
		local copiedTemplates = kingdom:FindFirstChild("ResidentTemplates")
		if copiedTemplates then
			copiedTemplates:Destroy()
		end
		records[owner] = { Kingdom = kingdom, Rigs = {}, Added = {}, Active = true }
		refresh(owner)
	end, function(owner)
		local r = records[owner]
		if r then
			clear(r)
		end
		records[owner] = nil
	end)
	local updated = Data.ObserveUpdates(function(owner)
		task.defer(refresh, owner)
	end)
	local players = game:GetService("Players")
	local playerConnections: { [Player]: { RBXScriptConnection } } = {}
	local characterConnections: { [Player]: RBXScriptConnection } = {}
	local function removePairs(player: Player)
		for _, r in records do
			for _, rig in r.Rigs do
				local root = rig:FindFirstChild("HumanoidRootPart")
				local folder = root and root:FindFirstChild("Player" .. player.UserId)
				if folder then
					folder:Destroy()
				end
			end
		end
	end
	local function pair(player: Player, part: Instance)
		if not part:IsA("BasePart") then
			return
		end
		for _, r in records do
			for _, rig in r.Rigs do
				local root = rig:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local name = "Player" .. player.UserId
					local folder = root:FindFirstChild(name)
					if not folder then
						folder = Instance.new("Folder")
						folder.Name = name
						folder.Parent = root
					end
					local c = Instance.new("NoCollisionConstraint")
					c.Part0 = root
					c.Part1 = part
					c.Parent = folder
				end
			end
		end
	end
	local function bindCharacter(player: Player, character: Model)
		if characterConnections[player] then
			characterConnections[player]:Disconnect()
		end
		removePairs(player)
		characterConnections[player] = character.DescendantAdded:Connect(function(part)
			pair(player, part)
		end)
		for _, part in character:GetDescendants() do
			pair(player, part)
		end
	end
	local function register(player: Player)
		playerConnections[player] = {
			player.CharacterAdded:Connect(function(c)
				bindCharacter(player, c)
			end),
			player.CharacterRemoving:Connect(function()
				if characterConnections[player] then
					characterConnections[player]:Disconnect()
					characterConnections[player] = nil
				end
				removePairs(player)
			end),
		}
		if player.Character then
			bindCharacter(player, player.Character)
		end
	end
	local function unregister(player: Player)
		if characterConnections[player] then
			characterConnections[player]:Disconnect()
			characterConnections[player] = nil
		end
		for _, c in playerConnections[player] or {} do
			c:Disconnect()
		end
		playerConnections[player] = nil
		removePairs(player)
	end
	local added = players.PlayerAdded:Connect(register)
	local removing = players.PlayerRemoving:Connect(unregister)
	for _, player in players:GetPlayers() do
		register(player)
	end
	local function isolate()
		if not isolationDirty then
			return
		end
		isolationDirty = false
		-- Rebuild bounded pairs only when ownership changes; no per-frame constraints.
		for _, player in players:GetPlayers() do
			removePairs(player)
			if player.Character then
				for _, part in player.Character:GetDescendants() do
					pair(player, part)
				end
			end
		end
	end
	isolateResidents = isolate
	isolate()
	game:BindToClose(function()
		unsubscribe()
		updated:Disconnect()
		isolateResidents = nil
		added:Disconnect()
		removing:Disconnect()
		for player in playerConnections do
			unregister(player)
		end
		for _, r in records do
			clear(r)
		end
		table.clear(records)
	end)
	print("[KingdomTycoon][KingdomResidentsService] Ready")
end
return Service
