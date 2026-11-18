--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.MainMenuConfig)
local Data = require(script.Parent.DataService)
local Plots = require(script.Parent.PlotService)
local Session = require(script.Parent.Parent.Entry.EntrySession)
local Service = {}
local connections: { RBXScriptConnection } = {}
local records: { [Player]: any } = {}
local started = false
local function freeze(player: Player, character: Model): ()
	local record = records[player]
	if not record or record.Session.Entered() then
		return
	end
	local function attach(item: Instance): ()
		if item.Name == "HumanoidRootPart" and item:IsA("BasePart") then
			record.Root = item
			record.Anchored = item.Anchored
			item.Anchored = true
		end
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		attach(root)
	end
	if record.Child then
		record.Child:Disconnect()
	end
	record.Child = character.ChildAdded:Connect(attach)
end
local function add(player: Player): ()
	if records[player] then
		return
	end
	player:SetAttribute("KingdomEntered", false)
	local record: any = {}
	record.Session = Session.new(Config.REQUEST_COOLDOWN, function()
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		return Data.GetSnapshot(player) ~= nil and humanoid ~= nil and humanoid.Health > 0
	end, function()
		return Plots.TryEnter(player)
	end)
	records[player] = record
	record.Character = player.CharacterAdded:Connect(function(character)
		freeze(player, character)
	end)
	if player.Character then
		freeze(player, player.Character)
	end
end
local function remove(player: Player): ()
	local record = records[player]
	if record then
		record.Character:Disconnect()
		if record.Child then
			record.Child:Disconnect()
		end
		records[player] = nil
	end
end
function Service.Init(): () end
function Service.Start(): ()
	if started then
		return
	end
	started = true
	local folder = Instance.new("Folder")
	folder.Name = Config.REMOTE_FOLDER
	local request = Instance.new("RemoteEvent")
	request.Name, request.Parent = "Request", folder
	local result = Instance.new("RemoteEvent")
	result.Name, result.Parent = "Result", folder
	table.insert(connections, Players.PlayerAdded:Connect(add))
	table.insert(connections, Players.PlayerRemoving:Connect(remove))
	for _, player in Players:GetPlayers() do
		add(player)
	end
	table.insert(
		connections,
		request.OnServerEvent:Connect(function(player: Player, action: unknown, ...: unknown)
			local record = records[player]
			if not record or select("#", ...) ~= 0 then
				return
			end
			-- Throttle responses too, including malformed requests and duplicate success.
			local now = os.clock()
			if record.LastReply and now - record.LastReply < Config.REQUEST_COOLDOWN then
				return
			end
			record.LastReply = now
			local called, success, message = pcall(record.Session.Request, action, now)
			if not called then
				warn("[KingdomTycoon][EntryService] Entry failed: " .. tostring(success))
				result:FireClient(player, false, "Entry failed. Please retry.")
				return
			end
			if success then
				if record.Root and record.Root.Parent then
					record.Root.Anchored = record.Anchored
				end
				if record.Child then
					record.Child:Disconnect()
					record.Child = nil
				end
				player:SetAttribute("KingdomEntered", true)
			end
			result:FireClient(player, success, message)
		end)
	)
	folder.Parent = ReplicatedStorage
	table.insert(
		connections,
		script.Destroying:Connect(function()
			for _, player in Players:GetPlayers() do
				local record = records[player]
				if record and record.Root and record.Root.Parent then
					record.Root.Anchored = record.Anchored
				end
				remove(player)
			end
			for _, connection in connections do
				connection:Disconnect()
			end
			folder:Destroy()
		end)
	)
	print("[KingdomTycoon][EntryService] Ready")
end
return Service
