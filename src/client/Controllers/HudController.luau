--!strict
local Players = game:GetService("Players")
local Settings = require(script.Parent.SettingsController)
local View = require(script.Parent.Parent.UI.HudView)
local State = require(script.Parent.Parent.UI.HudState)
local Controller = {}
local view: any = nil
local connections: { RBXScriptConnection } = {}
function Controller.Init(): () end
function Controller.SetHint(message: string): ()
	if view then
		view.Hint.Text = message
	end
end
function Controller.Start(): ()
	if view then
		return
	end
	local player = Players.LocalPlayer
	view = View.new(player:WaitForChild("PlayerGui"), Settings)
	local function render(): ()
		local gold = player:GetAttribute("Gold")
		local value = if player:GetAttribute("GoldReady") == true and typeof(gold) == "number" then gold else nil
		local formatted = State.FormatGold(value)
		view.Gold.Text = formatted
		view.Gold.TextSize = math.clamp(math.floor(128 / math.max(1, #formatted * 0.6)), 10, 20)
	end
	table.insert(connections, player:GetAttributeChangedSignal("Gold"):Connect(render))
	table.insert(connections, player:GetAttributeChangedSignal("GoldReady"):Connect(render))
	table.insert(
		connections,
		script.Destroying:Connect(function(): ()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			if view then
				view.Screen:Destroy()
				view = nil
			end
		end)
	)
	render()
	print("[KingdomTycoon][HudController] HUD ready")
end
return Controller
