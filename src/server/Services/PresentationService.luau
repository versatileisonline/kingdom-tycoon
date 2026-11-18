--!strict
local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local TutorialProgress = require(script.Parent.Parent.Presentation.TutorialProgress)
local Service = {}
local connections: { RBXScriptConnection } = {}
local started = false
local function refresh(player: Player): ()
	local data = DataService.GetSnapshot(player)
	TutorialProgress.Publish(player, data)
	if data == nil then
		player:SetAttribute("GoldReady", false)
		player:SetAttribute("Rebirths", nil)
		player:SetAttribute("Gold", nil)
		player:SetAttribute("LifetimeGold", nil)
	else
		player:SetAttribute("Rebirths", data.Rebirths)
		player:SetAttribute("Gold", data.Gold)
		player:SetAttribute("LifetimeGold", data.LifetimeGold)
		player:SetAttribute("GoldReady", true)
	end
end
function Service.Init(): () end
function Service.Start(): ()
	if started then
		return
	end
	started = true
	table.insert(connections, DataService.ObserveAvailability(refresh))
	table.insert(connections, DataService.ObserveUpdates(refresh))
	table.insert(connections, Players.PlayerAdded:Connect(refresh))
	for _, player in Players:GetPlayers() do
		refresh(player)
	end
	game:BindToClose(function(): ()
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, player in Players:GetPlayers() do
			TutorialProgress.Publish(player, nil)
			player:SetAttribute("GoldReady", false)
			player:SetAttribute("Rebirths", nil)
			player:SetAttribute("Gold", nil)
			player:SetAttribute("LifetimeGold", nil)
		end
	end)
end
return Service
