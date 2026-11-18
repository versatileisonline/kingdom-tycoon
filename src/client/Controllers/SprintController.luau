--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.SprintConfig)
local Preferences = require(script.Parent.SettingsController)
local View = require(script.Parent.Parent.UI.StaminaView)
local Input = require(script.Parent.Parent.Movement.SprintInput)
local state = Input.New()
local Controller = {}
local connections: { RBXScriptConnection } = {}
local sent = false
local started = false
local focused = true
local remote: RemoteEvent
local view: any
local function blocked(): boolean
	local character = Players.LocalPlayer.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	return Players.LocalPlayer:GetAttribute("KingdomEntered") == false
		or Preferences.Get("MainMenuOpen") == true
		or not focused
		or UserInputService:GetFocusedTextBox() ~= nil
		or GuiService.MenuIsOpen
		or Preferences.Get("MenuOpen") == true
		or Preferences.Get("ShopOpen") == true
		or Preferences.Get("RebirthOpen") == true
		or humanoid == nil
		or humanoid.Health <= 0
		or humanoid.Sit
end
local function sync(): ()
	if state.Requested ~= sent then
		sent = state.Requested
		remote:FireServer(sent)
	end
end
local function release(): ()
	Input.Cancel(state)
	sync()
end
function Controller.Init(): () end
function Controller.Start(): ()
	if started then
		return
	end
	started = true
	local folder = game:GetService("ReplicatedStorage"):WaitForChild(Config.REMOTE_FOLDER)
	remote = folder:WaitForChild("Input") :: RemoteEvent
	local status = folder:WaitForChild("Status") :: RemoteEvent
	view = View.Create(Players.LocalPlayer:WaitForChild("PlayerGui"))
	table.insert(
		connections,
		status.OnClientEvent:Connect(function(owned: boolean, fraction: number, exhausted: boolean)
			view.Set(owned, fraction)
			if not owned or exhausted then
				release()
			end
		end)
	)
	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input, processed)
			if input.KeyCode == Enum.KeyCode.LeftShift and not processed and not blocked() then
				Input.Press(state, os.clock())
				sync()
			end
		end)
	)
	table.insert(
		connections,
		UserInputService.InputEnded:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.LeftShift then
				Input.Release(state, os.clock())
				sync()
			end
		end)
	)
	table.insert(
		connections,
		UserInputService.WindowFocusReleased:Connect(function()
			focused = false
			release()
		end)
	)
	table.insert(
		connections,
		UserInputService.WindowFocused:Connect(function()
			focused = true
		end)
	)
	table.insert(connections, UserInputService.TextBoxFocused:Connect(release))
	table.insert(connections, GuiService.MenuOpened:Connect(release))
	table.insert(
		connections,
		Preferences.Observe(function()
			if blocked() then
				release()
			end
		end)
	)
	table.insert(connections, Players.LocalPlayer.CharacterRemoving:Connect(release))
	table.insert(
		connections,
		Players.LocalPlayer:GetAttributeChangedSignal("KingdomEntered"):Connect(function()
			if blocked() then
				release()
			end
		end)
	)
	-- Client movement intent keeps wall collisions and jumps from cancelling lock.
	table.insert(
		connections,
		RunService.Heartbeat:Connect(function(dt: number)
			if blocked() then
				release()
			else
				local character = Players.LocalPlayer.Character
				local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
				Input.Step(state, dt, humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0)
				sync()
			end
		end)
	)
	table.insert(connections, script.Destroying:Connect(Controller.Shutdown))
end
function Controller.Shutdown(): ()
	release()
	started = false
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if view then
		view.Destroy()
		view = nil
	end
end
return Controller
