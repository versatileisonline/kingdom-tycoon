--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config).CAMERA
local Logger = require(Shared.Logger)
local Preferences = require(script.Parent.SettingsController)
local logger = Logger.new("CameraController")
local CameraController = {}
local BINDING = "KingdomCameraLock"
local connections: { RBXScriptConnection } = {}
local enabled = false
local started = false
local focused = true
local activeHumanoid: Humanoid? = nil
local previousOffset = Vector3.zero
local previousAutoRotate = true
local previousMouse = Enum.MouseBehavior.Default
local previousIcon = true
local cursor: ScreenGui? = nil

local function restore(): ()
	if cursor then
		cursor.Enabled = false
	end
	local humanoid = activeHumanoid
	if humanoid ~= nil then
		humanoid.CameraOffset = previousOffset
		humanoid.AutoRotate = previousAutoRotate
		UserInputService.MouseBehavior = previousMouse
		UserInputService.MouseIconEnabled = previousIcon
		activeHumanoid = nil
	end
end

local function update(): ()
	local character = Players.LocalPlayer.Character
	local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	local camera = workspace.CurrentCamera
	if
		not enabled
		or not focused
		or UserInputService:GetFocusedTextBox() ~= nil
		or GuiService.MenuIsOpen
		or Preferences.Get("MenuOpen") == true
		or humanoid == nil
		or humanoid.Health <= 0
		or humanoid.Sit
		or root == nil
		or not root:IsA("BasePart")
		or camera == nil
		or camera.CameraType ~= Enum.CameraType.Custom
	then
		restore()
		return
	end
	if activeHumanoid ~= humanoid then
		restore()
		activeHumanoid = humanoid
		previousOffset = humanoid.CameraOffset
		previousAutoRotate = humanoid.AutoRotate
		previousMouse = UserInputService.MouseBehavior
		previousIcon = UserInputService.MouseIconEnabled
	end
	humanoid.CameraOffset = previousOffset + Settings.SHOULDER_OFFSET
	humanoid.AutoRotate = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	if cursor then
		cursor.Enabled = true
	end
	local look = camera.CFrame.LookVector
	local horizontal = Vector3.new(look.X, 0, look.Z)
	if horizontal.Magnitude > Settings.MIN_HORIZONTAL_MAGNITUDE then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + horizontal)
	end
end

function CameraController.Init(): ()
	assert(RunService:IsClient(), "CameraController is client-only")
end

function CameraController.Start(): ()
	if started then
		return
	end
	started = true
	local overlay = Instance.new("ScreenGui")
	overlay.Name = "ShiftLockCursor"
	overlay.ResetOnSpawn = false
	overlay.IgnoreGuiInset = true
	overlay.DisplayOrder = 20
	overlay.Enabled = false
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromOffset(10, 10)
	ring.BackgroundTransparency = 1
	ring.Parent = overlay
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring
	local outline = Instance.new("UIStroke")
	outline.Color = Color3.fromRGB(245, 232, 206)
	outline.Thickness = 1.5
	outline.Parent = ring
	for _, offset in { Vector2.new(0, -10), Vector2.new(0, 10), Vector2.new(-10, 0), Vector2.new(10, 0) } do
		local tick = Instance.new("Frame")
		tick.Name = "Tick"
		tick.AnchorPoint = Vector2.new(0.5, 0.5)
		tick.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y)
		tick.Size = if offset.X == 0 then UDim2.fromOffset(1, 4) else UDim2.fromOffset(4, 1)
		tick.BackgroundColor3 = outline.Color
		tick.BorderSizePixel = 0
		tick.Parent = overlay
	end
	overlay.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	cursor = overlay
	table.insert(
		connections,
		Preferences.Observe(function(key: string): ()
			if key == "MenuOpen" and Preferences.Get(key) == true then
				restore()
			end
		end)
	)
	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean): ()
			if
				not processed
				and input.KeyCode == Enum.KeyCode.LeftShift
				and UserInputService:GetFocusedTextBox() == nil
				and not GuiService.MenuIsOpen
				and Preferences.Get("MenuOpen") ~= true
			then
				enabled = not enabled
				logger.Info(if enabled then "Camera lock selected" else "Camera lock released")
				if not enabled then
					restore()
				end
			end
		end)
	)
	table.insert(
		connections,
		UserInputService.WindowFocusReleased:Connect(function(): ()
			focused = false
			restore()
		end)
	)
	table.insert(
		connections,
		UserInputService.WindowFocused:Connect(function(): ()
			focused = true
		end)
	)
	table.insert(
		connections,
		Players.LocalPlayer.CharacterRemoving:Connect(function(): ()
			restore()
		end)
	)
	table.insert(connections, script.Destroying:Connect(CameraController.Shutdown))
	RunService:BindToRenderStep(BINDING, Enum.RenderPriority.Camera.Value + 1, update)
	logger.Info("Started (Left Shift toggles camera lock)")
end

function CameraController.Shutdown(): ()
	enabled = false
	started = false
	restore()
	RunService:UnbindFromRenderStep(BINDING)
	if cursor then
		cursor:Destroy()
		cursor = nil
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return CameraController
