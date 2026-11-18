--!strict
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.SprintConfig)
local Hud = require(Shared.HudConfig)
local View = {}
function View.Create(parent: Instance): any
	local screen = Instance.new("ScreenGui")
	screen.Name, screen.ResetOnSpawn, screen.IgnoreGuiInset = "KingdomStaminaHUD", false, true
	screen.DisplayOrder = 6
	screen.Parent = parent
	local group = Instance.new("CanvasGroup")
	group.Name = "StaminaBar"
	group.AnchorPoint = Vector2.new(0.5, 0)
	group.Position = UDim2.new(0.5, 0, 0.5, Config.BAR_OFFSET)
	group.Size = UDim2.fromOffset(Config.BAR_WIDTH, Config.BAR_HEIGHT)
	group.BackgroundColor3, group.BackgroundTransparency = Color3.fromRGB(28, 22, 18), 0.15
	group.GroupTransparency, group.Visible = 1, false
	group.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 3), group
	local fill = Instance.new("Frame")
	fill.Name, fill.Size = "Fill", UDim2.fromScale(1, 1)
	fill.BorderSizePixel, fill.BackgroundColor3, fill.Parent = 0, Color3.fromHex(Hud.COLORS.Gold), group
	local fillCorner = corner:Clone()
	fillCorner.Parent = fill
	local tween: Tween? = nil
	local fading = true
	local object = {}
	function object.Set(owned: boolean, fraction: number): ()
		fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		local shouldFade = not owned or fraction >= 1
		if shouldFade == fading and group.Visible == owned then
			return
		end
		fading = shouldFade
		if tween then
			tween:Cancel()
		end
		group.Visible = owned
		if not owned then
			group.GroupTransparency = 1
			return
		end
		if shouldFade then
			local fade = TweenService:Create(group, TweenInfo.new(Config.FADE_SECONDS), { GroupTransparency = 1 })
			tween = fade
			fade:Play()
		else
			group.GroupTransparency = 0
		end
	end
	function object.Destroy(): ()
		if tween then
			tween:Cancel()
		end
		screen:Destroy()
	end
	return object
end
return View
