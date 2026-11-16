--!strict
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Hud = require(script.Parent.HudController)
local Controller = {}
local connections: { RBXScriptConnection } = {}
local started = false
function Controller.Init(): () end
function Controller.Start(): ()
	if started then
		return
	end
	started = true
	local player = Players.LocalPlayer
	local plots = workspace:WaitForChild("Plots", Config.PLOTS.CHARACTER_TIMEOUT_SECONDS)
	if not plots then
		return
	end
	local generation = 0
	local collected = false
	local initialGold = player:GetAttribute("Gold")
	local previousGold: number? = if player:GetAttribute("GoldReady") == true
			and typeof(initialGold) == "number"
		then initialGold
		else nil
	local function render(): ()
		generation += 1
		if player:GetAttribute("KingdomPlotId") ~= nil then
			Hud.SetHint(
				if player:GetAttribute("StarterFarmStarted") ~= true
					then "Start your farm"
					elseif not collected then "Collect your wheat"
					else ""
			)
		else
			collected = false
			local available = plots:GetAttribute("AvailablePlotCount")
			Hud.SetHint(
				if typeof(available) == "number" and available == 0 then "Waiting for land" else "Claim your kingdom"
			)
		end
	end
	for _, attribute in { "KingdomPlotId", "StarterFarmStarted" } do
		table.insert(connections, player:GetAttributeChangedSignal(attribute):Connect(render))
	end
	table.insert(connections, plots:GetAttributeChangedSignal("AvailablePlotCount"):Connect(render))
	table.insert(
		connections,
		player:GetAttributeChangedSignal("Gold"):Connect(function(): ()
			local gold = player:GetAttribute("Gold")
			if typeof(gold) == "number" then
				if previousGold and gold > previousGold then
					collected = true
				end
				previousGold = gold
			else
				previousGold = nil
			end
			render()
		end)
	)
	table.insert(
		connections,
		player:GetAttributeChangedSignal("PlotMessageSerial"):Connect(function(): ()
			generation += 1
			local current = generation
			local message = player:GetAttribute("PlotMessage")
			if typeof(message) == "string" then
				Hud.SetHint(message)
			end
			task.delay(Config.PLOTS.FEEDBACK_SECONDS, function(): ()
				if started and current == generation then
					render()
				end
			end)
		end)
	)
	table.insert(
		connections,
		script.Destroying:Connect(function(): ()
			started = false
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
		end)
	)
	render()
end
return Controller
