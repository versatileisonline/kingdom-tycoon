--!strict
local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.ShopConfig)
local GameConfig = require(Shared.Config)
local Registry = require(script.Parent.Parent.Shop.EntitlementRegistry)
local Service = {}
local states: { [Player]: Registry.Registry } = {}
local refreshing: { [Player]: { [string]: boolean } } = {}
local changed = Instance.new("BindableEvent")
local connections: { RBXScriptConnection } = {}
local started = false
function Service.IsPreview(): boolean
	return RunService:IsStudio()
		and GameConfig.DATA.STUDIO_MODE == "Mock"
		and script.Parent.Parent:GetAttribute("StudioShopPreview") == true
end
local function publish(player: Player, key: string): ()
	local state = states[player]
	if state then
		player:SetAttribute("Shop" .. key, state.Get(key))
		changed:Fire(player, key)
	end
end
function Service.Owns(player: Player, key: string): boolean
	local state = states[player]
	return state ~= nil and state.Owns(key)
end
function Service.Observe(callback: (Player, string) -> ()): RBXScriptConnection
	return changed.Event:Connect(callback)
end
function Service.Refresh(player: Player, onlyKey: string?): ()
	local state = states[player]
	local pending = refreshing[player]
	if not state or not pending then
		return
	end
	for _, offer in Config.OFFERS do
		if (onlyKey == nil or offer.Key == onlyKey) and not pending[offer.Key] then
			if Service.IsPreview() then
				publish(player, offer.Key)
				continue
			end
			local generation = state.Begin(offer.Key)
			publish(player, offer.Key)
			if offer.PassId <= 0 then
				state.Complete(offer.Key, generation, nil)
				publish(player, offer.Key)
				continue
			end
			pending[offer.Key] = true
			task.spawn(function(): ()
				local owned: boolean? = nil
				for attempt = 1, Config.LOOKUP_ATTEMPTS do
					local ok, result = pcall(function()
						return Marketplace:UserOwnsGamePassAsync(player.UserId, offer.PassId)
					end)
					if states[player] ~= state then
						return
					end
					if ok then
						owned = result
						break
					end
					if attempt < Config.LOOKUP_ATTEMPTS then
						task.wait(Config.LOOKUP_RETRY_SECONDS * attempt)
					end
				end
				pending[offer.Key] = nil
				if state.Complete(offer.Key, generation, owned) then
					publish(player, offer.Key)
				end
			end)
		end
	end
end
function Service.SetPreview(player: Player, key: string, owned: boolean): boolean
	if not Service.IsPreview() or not Config.BY_KEY[key] or not states[player] then
		return false
	end
	states[player].SetPreview(key, owned)
	publish(player, key)
	return true
end
local function added(player: Player): ()
	if states[player] then
		return
	end
	states[player] = Registry.new()
	refreshing[player] = {}
	player:SetAttribute("ShopPreview", Service.IsPreview())
	if Service.IsPreview() then
		for _, offer in Config.OFFERS do
			Service.SetPreview(player, offer.Key, false)
		end
	else
		Service.Refresh(player)
	end
end
function Service.Init(): () end
function Service.Start(): ()
	if started then
		return
	end
	started = true
	table.insert(connections, Players.PlayerAdded:Connect(added))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			local state = states[player]
			if state then
				state.Destroy()
			end
			states[player] = nil
			refreshing[player] = nil
		end)
	)
	table.insert(
		connections,
		Marketplace.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
			if not purchased then
				return
			end
			for _, offer in Config.OFFERS do
				if offer.PassId == passId and states[player] then
					-- This event is received on the server from Roblox, never from a client remote.
					local state = states[player]
					state.Complete(offer.Key, state.Begin(offer.Key), true)
					publish(player, offer.Key)
				end
			end
		end)
	)
	for _, player in Players:GetPlayers() do
		added(player)
	end
	game:BindToClose(function()
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		for _, state in states do
			state.Destroy()
		end
		table.clear(states)
		table.clear(refreshing)
	end)
end
return Service
