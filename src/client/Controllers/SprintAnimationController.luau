--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.SprintConfig)
local State = require(script.Parent.Parent.Movement.SprintAnimationState)
local Preferences = require(script.Parent.SettingsController)
local logger = require(Shared.Logger).new("SprintAnimationController")
local Controller = {}
local player = Players.LocalPlayer
local connections: { RBXScriptConnection } = {}
local characterConnections: { RBXScriptConnection } = {}
local humanoid: Humanoid? = nil
local track: AnimationTrack? = nil
local animation: Animation? = nil
local generation = 0
local focused = true
local started = false
local runningSpeed = 0

local function blocked(): boolean
	return not focused
		or UserInputService:GetFocusedTextBox() ~= nil
		or GuiService.MenuIsOpen
		or player:GetAttribute("KingdomEntered") == false
		or Preferences.Get("MainMenuOpen") == true
		or Preferences.Get("MenuOpen") == true
		or Preferences.Get("ShopOpen") == true
		or Preferences.Get("RebirthOpen") == true
		or Preferences.Get("LeaderboardOpen") == true
end

local function update(): ()
	local h, t = humanoid, track
	if not h or not t then
		return
	end
	local state = h:GetState()
	local grounded = h.FloorMaterial ~= Enum.Material.Air
		and (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics)
	local playing = State.ShouldPlay({
		Sprinting = player:GetAttribute("Sprinting") == true,
		Alive = h.Health > 0 and not h.Sit,
		Grounded = grounded,
		Moving = h.MoveDirection.Magnitude > 0 and runningSpeed > 0.5,
		Blocked = blocked(),
	})
	if playing then
		local speed = math.clamp(runningSpeed / Config.ANIMATION_REFERENCE_SPEED, 0.5, 1.5)
		if not t.IsPlaying then
			t:Play(Config.ANIMATION_FADE, 1, speed)
		else
			t:AdjustSpeed(speed)
		end
	elseif t.IsPlaying then
		t:Stop(Config.ANIMATION_FADE)
	end
end

local function clearCharacter(): ()
	generation += 1
	for _, connection in characterConnections do
		connection:Disconnect()
	end
	table.clear(characterConnections)
	if track then
		track:Stop(0)
		track:Destroy()
		track = nil
	end
	if animation then
		animation:Destroy()
		animation = nil
	end
	humanoid = nil
	runningSpeed = 0
end

local function bind(character: Model): ()
	clearCharacter()
	local expected = generation
	task.spawn(function()
		local h = character:WaitForChild("Humanoid", 10)
		if not h or not h:IsA("Humanoid") then
			return
		end
		-- The server creates this Animator; owner-loaded tracks then replicate normally.
		local animator = h:WaitForChild("Animator", 10)
		if expected ~= generation or not animator or not animator:IsA("Animator") or h.Health <= 0 then
			return
		end
		if h.RigType ~= Enum.HumanoidRigType.R15 then
			return
		end
		local asset = Instance.new("Animation")
		asset.Name, asset.AnimationId = "KingdomSprintAnimation", Config.ANIMATION_ID
		local ok, loaded = pcall(function()
			return animator:LoadAnimation(asset)
		end)
		if not ok then
			asset:Destroy()
			logger.Warn("Sprint animation failed to load")
			return
		end
		if expected ~= generation then
			loaded:Destroy()
			asset:Destroy()
			return
		end
		humanoid, animation, track = h, asset, loaded
		loaded.Priority, loaded.Looped = Enum.AnimationPriority.Movement, true
		table.insert(
			characterConnections,
			h.Running:Connect(function(speed: number)
				runningSpeed = speed
				update()
			end)
		)
		table.insert(characterConnections, h.StateChanged:Connect(update))
		table.insert(characterConnections, h:GetPropertyChangedSignal("MoveDirection"):Connect(update))
		table.insert(characterConnections, h:GetPropertyChangedSignal("FloorMaterial"):Connect(update))
		table.insert(characterConnections, h.Died:Connect(clearCharacter))
		update()
	end)
end

function Controller.Init(): () end
function Controller.Start(): ()
	if started then
		return
	end
	started = true
	table.insert(connections, player.CharacterAdded:Connect(bind))
	table.insert(connections, player.CharacterRemoving:Connect(clearCharacter))
	table.insert(connections, player:GetAttributeChangedSignal("Sprinting"):Connect(update))
	table.insert(connections, player:GetAttributeChangedSignal("KingdomEntered"):Connect(update))
	table.insert(
		connections,
		UserInputService.WindowFocusReleased:Connect(function()
			focused = false
			update()
		end)
	)
	table.insert(
		connections,
		UserInputService.WindowFocused:Connect(function()
			focused = true
			update()
		end)
	)
	table.insert(connections, UserInputService.TextBoxFocused:Connect(update))
	table.insert(connections, UserInputService.TextBoxFocusReleased:Connect(update))
	table.insert(connections, GuiService.MenuOpened:Connect(update))
	table.insert(connections, GuiService.MenuClosed:Connect(update))
	table.insert(connections, Preferences.Observe(update))
	table.insert(connections, script.Destroying:Connect(Controller.Shutdown))
	if player.Character then
		bind(player.Character)
	end
	logger.Info("Ready (R15 sprint animation)")
end

function Controller.Shutdown(): ()
	clearCharacter()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	started = false
end
return Controller
