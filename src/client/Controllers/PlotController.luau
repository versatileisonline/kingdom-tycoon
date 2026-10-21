--!strict

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local PlotController = {}
local connections: { RBXScriptConnection } = {}
local gui: ScreenGui? = nil
local generation = 0

function PlotController.Init(): () end

function PlotController.Start(): ()
	if gui ~= nil then
		return
	end
	local player = Players.LocalPlayer
	local screen = Instance.new("ScreenGui")
	screen.Name = "KingdomClaim"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 5
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = UDim2.new(0.5, 0, 1, -30)
	card.Size = UDim2.new(0.88, 0, 0, 94)
	card.BackgroundColor3 = Color3.fromRGB(28, 33, 30)
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0
	card.Parent = screen
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(480, 94)
	constraint.Parent = card
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(175, 146, 85)
	stroke.Transparency = 0.3
	stroke.Parent = card
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -32, 0, 24)
	title.Position = UDim2.fromOffset(16, 12)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextColor3 = Color3.fromRGB(232, 205, 144)
	title.Parent = card
	local detail = Instance.new("TextLabel")
	detail.Size = UDim2.new(1, -32, 0, 42)
	detail.Position = UDim2.fromOffset(16, 39)
	detail.BackgroundTransparency = 1
	detail.Font = Enum.Font.Gotham
	detail.TextSize = 14
	detail.TextWrapped = true
	detail.TextColor3 = Color3.fromRGB(237, 238, 222)
	detail.Parent = card
	local plots = workspace:WaitForChild("Plots", Config.PLOTS.CHARACTER_TIMEOUT_SECONDS)
	if plots == nil then
		screen:Destroy()
		return
	end
	local function render(): ()
		if player:GetAttribute("KingdomPlotId") ~= nil then
			title.Text = "YOUR KINGDOM"
			detail.Text = "Your banner is raised. You will respawn in your courtyard."
			return
		end
		local available = plots:GetAttribute("AvailablePlotCount")
		if typeof(available) ~= "number" then
			title.Text = "THE KINGDOM GROUNDS"
			detail.Text = "Checking available land..."
			return
		end
		title.Text = if available > 0 then "FOUND YOUR KINGDOM" else "ALL LAND IS CLAIMED"
		detail.Text = if available > 0
			then "Choose an open plot and interact with its gold claim banner."
			else "Explore the grounds. A plot becomes available when its owner leaves."
	end
	local function refresh(): ()
		generation += 1
		render()
	end
	table.insert(connections, plots:GetAttributeChangedSignal("AvailablePlotCount"):Connect(refresh))
	table.insert(connections, player:GetAttributeChangedSignal("KingdomPlotId"):Connect(refresh))
	table.insert(
		connections,
		player:GetAttributeChangedSignal("PlotMessageSerial"):Connect(function(): ()
			generation += 1
			local current = generation
			local message = player:GetAttribute("PlotMessage")
			if typeof(message) == "string" then
				detail.Text = message
			end
			task.delay(Config.PLOTS.FEEDBACK_SECONDS, function(): ()
				if gui ~= nil and generation == current then
					render()
				end
			end)
		end)
	)
	table.insert(
		connections,
		screen.Destroying:Connect(function(): ()
			generation += 1
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			gui = nil
		end)
	)
	gui = screen
	render()
	screen.Parent = player:WaitForChild("PlayerGui")
end

return PlotController
