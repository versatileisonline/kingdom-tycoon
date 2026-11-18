--!strict
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.LeaderboardConfig)
local Logger = require(Shared.Logger).new("LeaderboardController")
local Settings = require(script.Parent.SettingsController)
local State = require(script.Parent.Parent.UI.LeaderboardState)
local View = require(script.Parent.Parent.UI.LeaderboardView)
local Controller = {}
local connections: { RBXScriptConnection } = {}
local playerConnections: { [Player]: { RBXScriptConnection } } = {}
local portraits: { [number]: string } = {}
local started = false
local generation = 0
local view: any
local previousCore: boolean? = nil
local function render(): ()
	if not view then
		return
	end
	local entries: { State.Entry } = {}
	for player in playerConnections do
		local gold, rebirths = player:GetAttribute("LifetimeGold"), player:GetAttribute("Rebirths")
		local ready = player:GetAttribute("GoldReady") == true
		table.insert(entries, {
			UserId = player.UserId,
			Name = player.DisplayName,
			LifetimeGold = if ready and typeof(gold) == "number" then gold else nil,
			Rebirths = if ready and typeof(rebirths) == "number" then rebirths else nil,
		})
	end
	view.Render(State.Sort(entries), portraits)
end
local function refresh(): ()
	if not view then
		return
	end
	local available = Settings.Get("MainMenuOpen") ~= true
	if not available then
		Settings.Set("LeaderboardOpen", false)
	end
	view.SetAvailable(available)
	view.SetOpen(available and Settings.Get("LeaderboardOpen") == true)
end
local function observe(player: Player): ()
	if playerConnections[player] then
		return
	end
	local list: { RBXScriptConnection } = {}
	playerConnections[player] = list
	for _, name in { "LifetimeGold", "Rebirths", "GoldReady" } do
		table.insert(list, player:GetAttributeChangedSignal(name):Connect(render))
	end
	table.insert(
		list,
		player:GetPropertyChangedSignal("DisplayName"):Connect(function()
			-- Names normally stay constant within a session; a rebuild updates all metadata.
			render()
		end)
	)
	render()
	local token = generation
	task.spawn(function()
		for _ = 1, Config.THUMBNAIL_ATTEMPTS do
			local ok, content, ready = pcall(function()
				return Players:GetUserThumbnailAsync(
					player.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size100x100
				)
			end)
			if not started or token ~= generation or playerConnections[player] ~= list then
				return
			end
			if ok and ready then
				portraits[player.UserId] = content
				render()
				return
			end
			task.wait(Config.THUMBNAIL_RETRY_SECONDS)
		end
	end)
end
local function toggle(): ()
	if Settings.Get("MainMenuOpen") == true or UIS:GetFocusedTextBox() or GuiService.MenuIsOpen then
		return
	end
	Settings.Set("LeaderboardOpen", Settings.Get("LeaderboardOpen") ~= true)
end
function Controller.Init(): () end
function Controller.Start(): ()
	if started then
		return
	end
	started = true
	generation += 1
	view = View.new(Players.LocalPlayer:WaitForChild("PlayerGui"), Players.LocalPlayer.UserId)
	table.insert(connections, view.Launcher.Activated:Connect(toggle))
	table.insert(
		connections,
		view.Close.Activated:Connect(function()
			Settings.Set("LeaderboardOpen", false)
		end)
	)
	table.insert(connections, view.Screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(view.Fit))
	table.insert(connections, Settings.Observe(refresh))
	table.insert(
		connections,
		UIS.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.Tab then
				toggle()
			end
		end)
	)
	table.insert(
		connections,
		GuiService.MenuOpened:Connect(function()
			Settings.Set("LeaderboardOpen", false)
		end)
	)
	table.insert(connections, Players.PlayerAdded:Connect(observe))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			local list = playerConnections[player]
			if list then
				for _, c in list do
					c:Disconnect()
				end
			end
			playerConnections[player] = nil
			portraits[player.UserId] = nil
			render()
		end)
	)
	table.insert(connections, script.Destroying:Connect(Controller.Shutdown))
	for _, player in Players:GetPlayers() do
		observe(player)
	end
	view.Fit()
	refresh()
	local token = generation
	task.spawn(function()
		for _ = 1, Config.CORE_GUI_ATTEMPTS do
			if not started or token ~= generation then
				return
			end
			local ok = pcall(function()
				if previousCore == nil then
					previousCore = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
				end
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			end)
			if ok then
				Logger.Info("Ready (Tab toggles server leaderboard)")
				return
			end
			task.wait(Config.CORE_GUI_RETRY_SECONDS)
		end
		Logger.Warn("Could not disable native player list")
	end)
end
function Controller.Shutdown(): ()
	started = false
	generation += 1
	Settings.Set("LeaderboardOpen", false)
	for _, c in connections do
		c:Disconnect()
	end
	table.clear(connections)
	for _, list in playerConnections do
		for _, c in list do
			c:Disconnect()
		end
	end
	table.clear(playerConnections)
	table.clear(portraits)
	if view then
		view.Screen:Destroy()
		view = nil
	end
	if previousCore ~= nil then
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, previousCore :: boolean)
		end)
		previousCore = nil
	end
end
return Controller
