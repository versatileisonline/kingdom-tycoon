--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.TrainingCourseConfig)
local Settings = require(script.Parent.SettingsController)
local Controller = {}
local connections: { RBXScriptConnection } = {}
local started = false
function Controller.Init(): () end
function Controller.Start(): ()
	if started then
		return
	end
	started = true
	local player = Players.LocalPlayer
	local remote =
		game:GetService("ReplicatedStorage"):WaitForChild("KingdomTrainingCourse"):WaitForChild("Menu") :: RemoteEvent
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn = "KingdomTrainingHUD", false
	gui.Parent = player:WaitForChild("PlayerGui")
	local label = Instance.new("TextLabel")
	label.Name, label.AnchorPoint = "CourseTimer", Vector2.new(0.5, 0)
	label.Position, label.Size = UDim2.new(0.5, 0, 0, Config.UI_OFFSET_Y), UDim2.fromOffset(360, 50)
	label.BackgroundTransparency, label.TextColor3, label.TextStrokeTransparency =
		1, Color3.fromRGB(240, 207, 127), 0.35
	label.Font, label.TextSize = require(game:GetService("ReplicatedStorage").Shared.HudConfig).FONT, 20
	label.Parent = gui
	local function blocked(): boolean
		return Settings.Get("MenuOpen") == true
			or Settings.Get("ShopOpen") == true
			or Settings.Get("RebirthOpen") == true
			or Settings.Get("LeaderboardOpen") == true
			or GuiService.MenuIsOpen
	end
	local function sendMenu(): ()
		remote:FireServer(blocked())
	end
	table.insert(connections, Settings.Observe(sendMenu))
	table.insert(connections, GuiService.MenuOpened:Connect(sendMenu))
	table.insert(connections, GuiService.MenuClosed:Connect(sendMenu))
	table.insert(
		connections,
		RunService.RenderStepped:Connect(function()
			label.Visible = not blocked() and player:GetAttribute("KingdomEntered") ~= false
			local best = player:GetAttribute("CourseBest")
			if player:GetAttribute("CourseActive") == true then
				local origin = player:GetAttribute("CourseStarted")
				local elapsed = workspace:GetServerTimeNow()
					- (if typeof(origin) == "number" then origin else workspace:GetServerTimeNow())
				label.Text = string.format(
					"Practice: %.1fs  •  Checkpoint %d/3",
					elapsed,
					player:GetAttribute("CourseCheckpoint") or 0
				)
			else
				local result = player:GetAttribute("CourseResult")
				label.Text = if typeof(result) == "number" and typeof(best) == "number"
					then string.format("Finished: %.1fs  •  Best: %.1fs", result, best)
					else ""
			end
		end)
	)
	table.insert(
		connections,
		script.Destroying:Connect(function()
			started = false
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			gui:Destroy()
		end)
	)
end
return Controller
