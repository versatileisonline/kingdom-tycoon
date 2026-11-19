--!strict
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.StrongholdConfig)
local Plots = require(script.Parent.PlotService)
local Data = require(script.Parent.DataService)
local Policy = require(script.Parent.Parent.Stronghold.ProtectionDoorPolicy)
local Service = {}
type Record =
	{ Kingdom: Model, Door: Model?, Enabled: boolean, LastToggle: number, Connections: { RBXScriptConnection } }
local records: { [Player]: Record } = {}
local started = false
local function clear(record: Record): ()
	for _, c in record.Connections do
		c:Disconnect()
	end
	table.clear(record.Connections)
	record.Door = nil
end
local function valid(owner: Player, r: Record): boolean
	local data = Data.GetSnapshot(owner)
	return owner.Parent == Players
		and Plots.GetKingdom(owner) == r.Kingdom
		and not Plots.IsResetting(owner)
		and data ~= nil
		and data.PurchasedBuildings.ProtectionDoor == true
		and r.Door ~= nil
		and r.Door:IsDescendantOf(r.Kingdom)
end
local function publish(r: Record): ()
	local door = r.Door
	if not door then
		return
	end
	door:SetAttribute("WardEnabled", r.Enabled)
	local barrier = door:FindFirstChild("Barrier") :: BasePart
	barrier.Transparency = if r.Enabled then 0.45 else 1
	local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.ActionText = if r.Enabled then "Disable Ward" else "Enable Ward"
	end
	local label = door:FindFirstChild("StateLabel", true)
	if label and label:IsA("TextLabel") then
		label.Text = if r.Enabled then "WARD ON • LETHAL" else "WARD OFF • OPEN"
	end
end
function Service.TryToggle(actor: Player, owner: Player): boolean
	local r = records[owner]
	local character = actor.Character
	local h = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local control = if r and r.Door then r.Door:FindFirstChild("ToggleControl") else nil
	if
		actor ~= owner
		or not r
		or not valid(owner, r)
		or not h
		or h.Health <= 0
		or not h.RootPart
		or not control
		or not control:IsA("BasePart")
		or (h.RootPart.Position - control.Position).Magnitude > Config.TOGGLE_DISTANCE
		or os.clock() - r.LastToggle < Config.TOGGLE_COOLDOWN
	then
		return false
	end
	r.LastToggle = os.clock()
	r.Enabled = not r.Enabled
	publish(r)
	return true
end
local function scan(owner: Player, r: Record): ()
	if not r.Enabled or not valid(owner, r) then
		return
	end
	local zone = r.Door and r.Door:FindFirstChild("DetectionZone")
	if not zone or not zone:IsA("BasePart") then
		return
	end
	-- Server character-root intersection prevents accessories or forged touch reports killing a distant character.
	for _, visitor in Players:GetPlayers() do
		local character = visitor.Character
		local h = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if
			h
			and h.Health > 0
			and h.RootPart
			and Policy.MayDamage(
				owner.UserId,
				visitor.UserId,
				r.Enabled,
				character:FindFirstChildOfClass("ForceField") ~= nil
			)
		then
			local p = zone.CFrame:PointToObjectSpace(h.RootPart.Position)
			local half = zone.Size / 2 + Vector3.new(1, 2, 1)
			if math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z then
				h:TakeDamage(h.Health + h.MaxHealth)
			end
		end
	end
end
local function refresh(owner: Player): ()
	local r = records[owner]
	if not r then
		return
	end
	local unlocks = r.Kingdom:FindFirstChild("PurchaseUnlocks")
	local door = if unlocks then unlocks:FindFirstChild("ProtectionDoor") else nil
	local data = Data.GetSnapshot(owner)
	if not data or data.PurchasedBuildings.ProtectionDoor ~= true or not door or not door:IsA("Model") then
		clear(r)
		return
	end
	if r.Door == door then
		return
	end
	clear(r)
	r.Door = door
	r.Enabled = true
	r.LastToggle = -math.huge
	local barrier = door:FindFirstChild("Barrier")
	local zone = door:FindFirstChild("DetectionZone")
	local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not barrier or not barrier:IsA("BasePart") or not zone or not zone:IsA("BasePart") or not prompt then
		warn("[KingdomTycoon][ProtectionDoorService] Invalid door asset")
		clear(r)
		return
	end
	table.insert(
		r.Connections,
		prompt.Triggered:Connect(function(actor)
			Service.TryToggle(actor, owner)
		end)
	)
	table.insert(
		r.Connections,
		barrier.Touched:Connect(function()
			scan(owner, r)
		end)
	)
	publish(r)
end
function Service.Init(): () end
function Service.Start(): ()
	if started then
		return
	end
	started = true
	local unsubscribe = Plots.ObserveKingdoms(function(owner, kingdom)
		records[owner] = { Kingdom = kingdom, Door = nil, Enabled = true, LastToggle = -math.huge, Connections = {} }
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
	task.spawn(function()
		while started do
			task.wait(Config.DOOR_TICK)
			for owner, r in records do
				scan(owner, r)
			end
		end
	end)
	game:BindToClose(function()
		started = false
		unsubscribe()
		updated:Disconnect()
		for _, r in records do
			clear(r)
		end
		table.clear(records)
	end)
	print("[KingdomTycoon][ProtectionDoorService] Ready")
end
return Service
