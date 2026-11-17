--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local RuntimeConfig = require(Shared.Config)
local Config = require(Shared.TutorialConfig)
local Settings = require(script.Parent.SettingsController)
local State = require(script.Parent.Parent.UI.TutorialState)
local ArrowView = require(script.Parent.Parent.UI.TutorialArrowView)
local Controller = {}
local connections: { RBXScriptConnection } = {}
local characterConnections: { RBXScriptConnection } = {}
local ownerConnections: { [Instance]: RBXScriptConnection } = {}
local balanceConnections: { [Instance]: RBXScriptConnection } = {}
local healthConnection: RBXScriptConnection? = nil
local frameConnection: RBXScriptConnection? = nil
local view: ArrowView.Arrow? = nil
local target: BasePart? = nil
local root: BasePart? = nil
local humanoid: Humanoid? = nil
local running = false
local queued = false

local function disconnect(list: { RBXScriptConnection }): ()
	for _, connection in list do
		connection:Disconnect()
	end
	table.clear(list)
end
local function numberAttribute(item: Instance, name: string): number
	local value = item:GetAttribute(name)
	return if typeof(value) == "number" and value == value and math.abs(value) ~= math.huge then value else 0
end
local function findPath(parent: Instance, path: { string }): Instance?
	local found: Instance? = parent
	for _, name in path do
		if found == nil then
			return nil
		end
		found = found:FindFirstChild(name)
	end
	return found
end
local function stopFrame(): ()
	if frameConnection then
		frameConnection:Disconnect()
		frameConnection = nil
	end
	if view then
		view.Hide()
	end
end
function Controller.Init(): () end
function Controller.Start(): ()
	if running then
		return
	end
	running = true
	local player = Players.LocalPlayer
	local kingdoms = workspace:WaitForChild("ActiveKingdoms", RuntimeConfig.PLOTS.CHARACTER_TIMEOUT_SECONDS)
	if not kingdoms then
		running = false
		return
	end
	local arrow = ArrowView.new(player:WaitForChild("PlayerGui") :: PlayerGui)
	view = arrow
	local refresh: () -> ()
	local function queueRefresh(): ()
		if not running or queued then
			return
		end
		queued = true
		task.defer(function(): ()
			queued = false
			if running then
				refresh()
			end
		end)
	end
	local function permitted(): boolean
		return Settings.Get("HelperArrow") == true
			and Settings.Get("MenuOpen") ~= true
			and UserInputService:GetFocusedTextBox() == nil
			and not GuiService.MenuIsOpen
	end
	local function render(): ()
		local currentTarget, currentRoot, currentHumanoid = target, root, humanoid
		if
			not running
			or not view
			or not permitted()
			or not currentTarget
			or not currentRoot
			or not currentHumanoid
			or currentHumanoid.Health <= 0
			or currentTarget.Parent == nil
			or currentRoot.Parent == nil
		then
			stopFrame()
			return
		end
		local camera = workspace.CurrentCamera
		if not camera then
			arrow.Hide()
			return
		end
		local legHeight = 0
		if currentHumanoid.RigType == Enum.HumanoidRigType.R6 then
			local leg = currentRoot.Parent:FindFirstChild("Left Leg")
			if leg and leg:IsA("BasePart") then
				legHeight = leg.Size.Y
			end
		end
		local from = currentRoot.Position
			- Vector3.new(0, currentHumanoid.HipHeight + currentRoot.Size.Y / 2 + legHeight - Config.WORLD.FootLift, 0)
		local to = currentTarget.Position + Vector3.new(0, Config.WORLD.TargetLift, 0)
		if (to - from).Magnitude <= Config.WORLD.NearDistance then
			arrow.Hide()
			return
		end
		arrow.Update(from, to, camera)
	end
	refresh = function(): ()
		local character = player.Character
		local nextRoot = if character then character:FindFirstChild("HumanoidRootPart") else nil
		root = if nextRoot and nextRoot:IsA("BasePart") then nextRoot else nil
		local nextHumanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if nextHumanoid ~= humanoid then
			if healthConnection then
				healthConnection:Disconnect()
				healthConnection = nil
			end
			humanoid = nextHumanoid
			if humanoid then
				healthConnection = humanoid.HealthChanged:Connect(queueRefresh)
			end
		end
		local kingdom: Model? = nil
		if player:GetAttribute("KingdomPlotId") ~= nil then
			for _, candidate in kingdoms:GetChildren() do
				if candidate:IsA("Model") and candidate:GetAttribute("OwnerUserId") == player.UserId then
					kingdom = candidate
					break
				end
			end
		end
		local desired: { [Instance]: boolean } = {}
		local balance = 0
		if kingdom then
			for _, path in { { "StarterFarm" }, { "PurchaseUnlocks", "RoyalMint" } } do
				local model = findPath(kingdom, path)
				if model then
					desired[model] = true
					balance = math.max(balance, numberAttribute(model, "UncollectedGold"))
					if not balanceConnections[model] then
						balanceConnections[model] =
							model:GetAttributeChangedSignal("UncollectedGold"):Connect(queueRefresh)
					end
				end
			end
		end
		for model, connection in balanceConnections do
			if not desired[model] then
				connection:Disconnect()
				balanceConnections[model] = nil
			end
		end
		local attributes = Config.ATTRIBUTES
		local ready = player:GetAttribute("GoldReady") == true
		for _, name in attributes do
			if typeof(player:GetAttribute(name)) ~= "boolean" then
				ready = false
			end
		end
		local role: State.Target? = nil
		if kingdom then
			role = State.Select({
				Ready = ready,
				Started = player:GetAttribute("StarterFarmStarted") == true,
				Gold = numberAttribute(player, "Gold"),
				Balance = balance,
				FarmCollected = player:GetAttribute(attributes.FarmCollected) == true,
				MintCollected = player:GetAttribute(attributes.MintCollected) == true,
				WallsOwned = player:GetAttribute(attributes.WallsOwned) == true,
				MintOwned = player:GetAttribute(attributes.MintOwned) == true,
				MintDropper02Owned = player:GetAttribute(attributes.MintDropper02Owned) == true,
				Upgrader01Owned = player:GetAttribute(attributes.Upgrader01Owned) == true,
			}, Config.PRICES)
		end
		local found = if kingdom and role then findPath(kingdom, Config.TARGET_PATHS[role]) else nil
		target = if found and found:IsA("BasePart") and found.Transparency < 1 and found.CanTouch then found else nil
		arrow.Gui:SetAttribute("TutorialTarget", if target then role else nil)
		if target and root and humanoid and humanoid.Health > 0 and permitted() then
			if not frameConnection then
				frameConnection = RunService.RenderStepped:Connect(render)
			end
			render()
		else
			stopFrame()
		end
	end
	local function bindCharacter(character: Model?): ()
		disconnect(characterConnections)
		if healthConnection then
			healthConnection:Disconnect()
			healthConnection = nil
		end
		root, humanoid = nil, nil
		if character then
			table.insert(characterConnections, character.ChildAdded:Connect(queueRefresh))
			table.insert(characterConnections, character.ChildRemoved:Connect(queueRefresh))
		end
		queueRefresh()
	end
	local function watchKingdom(item: Instance): ()
		if item:IsA("Model") and not ownerConnections[item] then
			ownerConnections[item] = item:GetAttributeChangedSignal("OwnerUserId"):Connect(queueRefresh)
		end
	end
	local relevant: { [string]: boolean } = {}
	for _, path in Config.TARGET_PATHS do
		for _, name in path do
			relevant[name] = true
		end
	end
	for _, item in kingdoms:GetChildren() do
		watchKingdom(item)
	end
	table.insert(
		connections,
		kingdoms.ChildAdded:Connect(function(item: Instance): ()
			watchKingdom(item)
			queueRefresh()
		end)
	)
	table.insert(
		connections,
		kingdoms.ChildRemoved:Connect(function(item: Instance): ()
			local connection = ownerConnections[item]
			if connection then
				connection:Disconnect()
				ownerConnections[item] = nil
			end
			queueRefresh()
		end)
	)
	table.insert(
		connections,
		kingdoms.DescendantAdded:Connect(function(item: Instance): ()
			if relevant[item.Name] then
				queueRefresh()
			end
		end)
	)
	table.insert(
		connections,
		kingdoms.DescendantRemoving:Connect(function(item: Instance): ()
			if item == target then
				target = nil
				stopFrame()
				arrow.Gui:SetAttribute("TutorialTarget", nil)
			end
			if relevant[item.Name] then
				queueRefresh()
			end
		end)
	)
	for _, name in { "Gold", "GoldReady", "KingdomPlotId", "StarterFarmStarted" } do
		table.insert(connections, player:GetAttributeChangedSignal(name):Connect(queueRefresh))
	end
	for _, name in Config.ATTRIBUTES do
		table.insert(connections, player:GetAttributeChangedSignal(name):Connect(queueRefresh))
	end
	table.insert(
		connections,
		Settings.Observe(function(key: string): ()
			if key == "HelperArrow" or key == "MenuOpen" then
				queueRefresh()
			end
		end)
	)
	table.insert(connections, player.CharacterAdded:Connect(bindCharacter))
	table.insert(
		connections,
		player.CharacterRemoving:Connect(function(): ()
			bindCharacter(nil)
			stopFrame()
		end)
	)
	table.insert(connections, UserInputService.TextBoxFocused:Connect(queueRefresh))
	table.insert(connections, UserInputService.TextBoxFocusReleased:Connect(queueRefresh))
	table.insert(connections, GuiService:GetPropertyChangedSignal("MenuIsOpen"):Connect(queueRefresh))
	table.insert(connections, arrow.Gui.Destroying:Connect(Controller.Shutdown))
	table.insert(connections, script.Destroying:Connect(Controller.Shutdown))
	bindCharacter(player.Character)
	refresh()
end
function Controller.Shutdown(): ()
	if not running then
		return
	end
	running = false
	queued = false
	stopFrame()
	disconnect(connections)
	disconnect(characterConnections)
	if healthConnection then
		healthConnection:Disconnect()
		healthConnection = nil
	end
	for _, c in ownerConnections do
		c:Disconnect()
	end
	for _, c in balanceConnections do
		c:Disconnect()
	end
	table.clear(ownerConnections)
	table.clear(balanceConnections)
	target, root, humanoid = nil, nil, nil
	local previous = view
	view = nil
	if previous then
		previous.Destroy()
	end
end
return Controller
