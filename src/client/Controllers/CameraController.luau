--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config).CAMERA
local Logger = require(Shared.Logger)
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

local function restore(): ()
	local humanoid = activeHumanoid
	if humanoid ~= nil then
		humanoid.CameraOffset = previousOffset
		humanoid.AutoRotate = previousAutoRotate
		UserInputService.MouseBehavior = previousMouse
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
	end
	humanoid.CameraOffset = previousOffset + Settings.SHOULDER_OFFSET
	humanoid.AutoRotate = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
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
	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean): ()
			if
				not processed
				and input.KeyCode == Enum.KeyCode.LeftShift
				and UserInputService:GetFocusedTextBox() == nil
				and not GuiService.MenuIsOpen
			then
				enabled = not enabled
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
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return CameraController
