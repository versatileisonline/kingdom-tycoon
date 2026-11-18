--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.ShopConfig)
local Entitlements = require(script.Parent.EntitlementService)
local Farms = require(script.Parent.FarmService)
local Service = {}
local connections: { RBXScriptConnection } = {}
local lastRequests: { [Player]: { [string]: number } } = {}
local folder: Folder
local collect: RemoteEvent
local result: RemoteEvent
local refresh: RemoteEvent
local preview: RemoteEvent?
local started = false
local function allowed(player: Player, key: string, cooldown: number): boolean
	if player.Parent ~= Players then
		return false
	end
	local requests = lastRequests[player]
	if not requests then
		requests = {}
		lastRequests[player] = requests
	end
	local now = os.clock()
	if now - (requests[key] or -math.huge) < cooldown then
		return false
	end
	requests[key] = now
	return true
end
local function remote(name: string): RemoteEvent
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = folder
	return event
end
function Service.Init(): ()
	assert(not ReplicatedStorage:FindFirstChild(Config.REMOTE_FOLDER), "Shop remote folder already exists")
	folder = Instance.new("Folder")
	folder.Name = Config.REMOTE_FOLDER
	collect = remote("CollectNow")
	result = remote("CollectResult")
	refresh = remote("RefreshOwnership")
	if Entitlements.IsPreview() then
		preview = remote("PreviewPurchase")
	end
	folder.Parent = ReplicatedStorage
end
function Service.Start(): ()
	if started then
		return
	end
	started = true
	table.insert(
		connections,
		collect.OnServerEvent:Connect(function(player: Player, ...: any)
			if not allowed(player, "collect", Config.COLLECT_COOLDOWN) then
				return
			end
			if select("#", ...) ~= 0 then
				result:FireClient(player, false, 0)
				return
			end
			local ok, amount = Farms.TryCollectAnywhere(player)
			result:FireClient(player, ok, amount)
		end)
	)
	table.insert(
		connections,
		refresh.OnServerEvent:Connect(function(player: Player, ...: any)
			if select("#", ...) == 0 and allowed(player, "refresh", Config.REFRESH_COOLDOWN) then
				Entitlements.Refresh(player)
			end
		end)
	)
	if preview then
		table.insert(
			connections,
			preview.OnServerEvent:Connect(function(player: Player, key: unknown, ...: any)
				if
					not Entitlements.IsPreview()
					or not allowed(player, "preview", Config.COLLECT_COOLDOWN)
					or select("#", ...) ~= 0
					or typeof(key) ~= "string"
				then
					return
				end
				if key == "Reset" then
					for _, offer in Config.OFFERS do
						Entitlements.SetPreview(player, offer.Key, false)
					end
				else
					Entitlements.SetPreview(player, key, true)
				end
			end)
		)
	end
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
