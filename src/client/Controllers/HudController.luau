--!strict
local Players = game:GetService("Players")
local Settings = require(script.Parent.SettingsController)
local View = require(script.Parent.Parent.UI.HudView)
local State = require(script.Parent.Parent.UI.HudState)
local Config = require(game.ReplicatedStorage.Shared.HudConfig)
local Controller = {}
local view: any = nil
local connections: { RBXScriptConnection } = {}
function Controller.Init(): () end
function Controller.SetHint(message: string): ()
	if view then
		view.Hint.Text = message
	end
end
function Controller.GetGoldButton(): TextButton
	assert(view, "HUD must start before shop controls")
	return view.GoldButton
end
function Controller.SetCollectState(owned: boolean, enabled: boolean, busy: boolean): ()
	if not view then
		return
	end
	local extra = if owned then Config.UI.BadgeCollectExtraWidth else 0
	view.GoldButton.Size = UDim2.fromOffset(Config.UI.BadgeWidth + extra, Config.UI.BadgeHeight)
	view.GoldButton.Active = owned and enabled
	view.GoldButton.Selectable = owned and enabled
	view.GoldButton.AutoButtonColor = owned and enabled
	view.CollectLabel.Visible = owned
	view.CollectLabel.Text = if busy then "Collect…" else "Collect"
	view.RowLayout.HorizontalAlignment = if owned
		then Enum.HorizontalAlignment.Center
		else Enum.HorizontalAlignment.Left
	view.RowLayout.Padding = UDim.new(0, if owned then Config.UI.CoinGap else 2 * Config.UI.CoinGap)
end
function Controller.Start(): ()
	if view then
		return
	end
	local player = Players.LocalPlayer
	view = View.new(player:WaitForChild("PlayerGui"), Settings)
	local function render(): ()
		local gold = player:GetAttribute("Gold")
		local pending = player:GetAttribute("UncollectedGold")
		local value = State.DisplayGold(
			player:GetAttribute("GoldReady") == true,
			player:GetAttribute("ShopCollectNow") == "Owned",
			if typeof(gold) == "number" then gold else nil,
			if typeof(pending) == "number" then pending else nil
		)
		local formatted = State.FormatGold(value)
		view.Gold.Text = formatted
		view.Gold.TextSize = math.clamp(math.floor(128 / math.max(1, #formatted * 0.6)) + 2, 12, 22)
	end
	table.insert(connections, player:GetAttributeChangedSignal("Gold"):Connect(render))
	table.insert(connections, player:GetAttributeChangedSignal("GoldReady"):Connect(render))
	table.insert(connections, player:GetAttributeChangedSignal("UncollectedGold"):Connect(render))
	table.insert(connections, player:GetAttributeChangedSignal("ShopCollectNow"):Connect(render))
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
