--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Config = require(ReplicatedStorage.Shared.MainMenuConfig)
local Settings = require(script.Parent.SettingsController)
local View = require(script.Parent.Parent.UI.MainMenuView)
local Controller = {}
local started = false
function Controller.Init(): ()
	Settings.Set("MainMenuOpen", true)
end
function Controller.Start(): ()
	if started then
		return
	end
	started = true
	local player = Players.LocalPlayer
	local parent = player:WaitForChild("PlayerGui")
	local view = View.new(parent)
	local connections: { RBXScriptConnection } = {}
	local hidden: { [ScreenGui]: boolean } = {}
	local cameras: { [Camera]: { Type: Enum.CameraType, Subject: Instance?, Frame: CFrame } } = {}
	local request: RemoteEvent? = nil
	local busy, active, errorMessage = false, true, ""
	local generation = 0
	local settingsWasOpen = false
	local function ready(): boolean
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		return request ~= nil and player:GetAttribute("GoldReady") == true and humanoid ~= nil and humanoid.Health > 0
	end
	local function render(): ()
		if not active then
			return
		end
		local enabled = ready() and not busy
		view.Play.Active, view.Play.Selectable = enabled, enabled
		view.Play.Text = if busy then "ENTERING…" else "PLAY"
		view.Play.TextTransparency = if enabled then 0 else 0.45
		view.Status.Text = if busy
			then "Preparing your arrival…"
			elseif errorMessage ~= "" then errorMessage
			elseif not ready() then "Loading your kingdom…"
			else ""
		local settingsOpen = Settings.Get("MenuOpen") == true
		view.Panel.Visible = not settingsOpen
		if settingsOpen ~= settingsWasOpen and Input.GamepadEnabled then
			if settingsOpen then
				local hud = parent:FindFirstChild("KingdomHUD")
				local shade = if hud then hud:FindFirstChild("SettingsShade") else nil
				local panel = if shade then shade:FindFirstChild("SettingsPanel") else nil
				local close = if panel then panel:FindFirstChild("Close") else nil
				if close and close:IsA("GuiButton") then
					GuiService.SelectedObject = close
				end
			else
				GuiService.SelectedObject = if enabled then view.Play else view.Settings
			end
		end
		settingsWasOpen = settingsOpen
	end
	local function hideScreen(child: Instance): ()
		if
			child:IsA("ScreenGui")
			and table.find({ "KingdomShopHUD", "KingdomRebirthHUD", "KingdomStaminaHUD" }, child.Name)
		then
			hidden[child] = child.Enabled
			child.Enabled = false
		end
	end
	for _, child in parent:GetChildren() do
		hideScreen(child)
	end
	table.insert(connections, parent.ChildAdded:Connect(hideScreen))
	local function finish(): ()
		if not active or player:GetAttribute("KingdomEntered") ~= true then
			return
		end
		active = false
		generation += 1
		Settings.Set("MenuOpen", false)
		Settings.Set("MainMenuOpen", false)
		for screen, enabled in hidden do
			if screen.Parent then
				screen.Enabled = enabled
			end
		end
		for camera, original in cameras do
			if camera.Parent then
				camera.CameraType, camera.CameraSubject, camera.CFrame = original.Type, original.Subject, original.Frame
			end
		end
		local camera = workspace.CurrentCamera
		local humanoid = if player.Character then player.Character:FindFirstChildOfClass("Humanoid") else nil
		if camera and humanoid then
			camera.CameraType, camera.CameraSubject = Enum.CameraType.Custom, humanoid
		end
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(view.Screen) then
			GuiService.SelectedObject = nil
		end
		for _, connection in connections do
			connection:Disconnect()
		end
		view.Screen:Destroy()
		print("[KingdomTycoon][MainMenuController] Entered game")
	end
	table.insert(connections, player:GetAttributeChangedSignal("KingdomEntered"):Connect(finish))
	table.insert(connections, player:GetAttributeChangedSignal("GoldReady"):Connect(render))
	table.insert(connections, Settings.Observe(render))
	table.insert(
		connections,
		view.Settings.Activated:Connect(function()
			Settings.Set("MenuOpen", true)
		end)
	)
	table.insert(
		connections,
		RunService.RenderStepped:Connect(function()
			local camera = workspace.CurrentCamera
			if camera then
				if not cameras[camera] then
					cameras[camera] =
						{ Type = camera.CameraType, Subject = camera.CameraSubject, Frame = camera.CFrame }
				end
				camera.CameraType = Enum.CameraType.Scriptable
			end
			render()
		end)
	)
	table.insert(
		connections,
		view.Play.Activated:Connect(function()
			if busy or not ready() or not request then
				return
			end
			busy, errorMessage = true, ""
			generation += 1
			local current = generation
			request:FireServer("Play")
			render()
			task.delay(Config.REQUEST_TIMEOUT, function()
				if active and current == generation then
					busy, errorMessage = false, "Entry took too long. Please retry."
					render()
				end
			end)
		end)
	)
	table.insert(
		connections,
		script.Destroying:Connect(function()
			-- Restore presentation even when the controller is removed during the menu.
			Settings.Set("MainMenuOpen", false)
			for screen, enabled in hidden do
				if screen.Parent then
					screen.Enabled = enabled
				end
			end
			for camera, original in cameras do
				if camera.Parent then
					camera.CameraType, camera.CameraSubject = original.Type, original.Subject
				end
			end
			active = false
			for _, connection in connections do
				connection:Disconnect()
			end
			view.Screen:Destroy()
		end)
	)
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild(Config.REMOTE_FOLDER, Config.REQUEST_TIMEOUT)
		local req = if folder then folder:WaitForChild("Request", Config.REQUEST_TIMEOUT) else nil
		local result = if folder then folder:WaitForChild("Result", Config.REQUEST_TIMEOUT) else nil
		if not active then
			return
		end
		if not req or not req:IsA("RemoteEvent") or not result or not result:IsA("RemoteEvent") then
			errorMessage = "Entry service is unavailable. Please rejoin."
			render()
			return
		end
		request = req
		table.insert(
			connections,
			result.OnClientEvent:Connect(function(success: unknown, message: unknown)
				if typeof(success) ~= "boolean" or typeof(message) ~= "string" then
					return
				end
				if success then
					finish()
				else
					busy, errorMessage = false, message
					generation += 1
					render()
				end
			end)
		)
		render()
	end)
	render()
	if Input.GamepadEnabled then
		GuiService.SelectedObject = view.Settings
	end
	finish()
	print("[KingdomTycoon][MainMenuController] Menu ready")
end
return Controller
