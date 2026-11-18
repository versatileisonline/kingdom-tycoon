--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.RebirthConfig)
local Data = require(script.Parent.DataService)
local Plots = require(script.Parent.PlotService)
local logger = require(Shared.Logger).new("RebirthService")
local Service = {}
local lastRequests: { [Player]: number } = {}
local connections: { RBXScriptConnection } = {}
local folder: Folder
local request: RemoteEvent
local result: RemoteEvent
local started = false
function Service.TryRebirth(player: Player, expected: unknown): (boolean, string)
	if player.Parent ~= Players then
		return false, "Invalid player."
	end
	local now = os.clock()
	if now - (lastRequests[player] or -math.huge) < Config.REQUEST_COOLDOWN then
		return false, "Please wait before trying again."
	end
	lastRequests[player] = now
	if
		typeof(expected) ~= "number"
		or expected ~= expected
		or expected < 0
		or expected % 1 ~= 0
		or expected > 9007199254740991
	then
		return false, "Invalid rebirth request."
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid == nil or humanoid.Health <= 0 or humanoid.RootPart == nil then
		return false, "Your character must be alive to rebirth."
	end
	local data = Data.GetSnapshot(player)
	if data == nil then
		return false, "Your progress is still loading."
	end
	if data.Rebirths ~= expected then
		return false, "Your rebirth count changed. Please try again."
	end
	local target = Config.Target(data.Rebirths)
	if target == nil then
		return false, "The maximum supported rebirth target has been reached."
	end
	if data.Gold < target then
		return false, "You need more banked Gold."
	end
	local success, reason = Plots.ResetKingdom(player, function(): (boolean, string?)
		return Data.Update(player, function(draft)
			assert(draft.Rebirths == expected and draft.Gold >= target, "Rebirth requirements changed")
			draft.Gold = 0
			draft.PurchasedBuildings = {}
			draft.Rebirths += 1
		end)
	end)
	if success then
		logger.Info(string.format("Rebirth %d completed for %d", expected + 1, player.UserId))
		return true, "Rebirth complete! Start your farm to rebuild faster."
	end
	return false, reason or "Rebirth could not be completed."
end
function Service.Init(): ()
	assert(not ReplicatedStorage:FindFirstChild(Config.REMOTE_FOLDER), "Rebirth remotes already exist")
	folder = Instance.new("Folder")
	folder.Name = Config.REMOTE_FOLDER
	request = Instance.new("RemoteEvent")
	request.Name = "Request"
	request.Parent = folder
	result = Instance.new("RemoteEvent")
	result.Name = "Result"
	result.Parent = folder
	folder.Parent = ReplicatedStorage
end
function Service.Start(): ()
	if started then
		return
	end
	started = true
	table.insert(
		connections,
		request.OnServerEvent:Connect(function(player: Player, expected: unknown, requestId: unknown, ...: any)
			if
				typeof(requestId) ~= "number"
				or requestId ~= requestId
				or requestId < 1
				or requestId > 9007199254740991
				or requestId % 1 ~= 0
			then
				return
			end
			if select("#", ...) ~= 0 then
				return
			end
			local ok, message = Service.TryRebirth(player, expected)
			if player.Parent == Players then
				result:FireClient(player, ok, message, expected, requestId)
			end
		end)
	)
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			lastRequests[player] = nil
		end)
	)
	game:BindToClose(function()
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		table.clear(lastRequests)
		folder:Destroy()
	end)
end
return Service
