--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Logger"))
local Types = require(Shared:WaitForChild("Types"))

local logger = Logger.new("ClientBootstrap")

-- Require and run controllers in this explicit order. Add controllers as milestones land.
local controllers: { Types.Lifecycle } = {
	require(script.Controllers.SettingsController),
	require(script.Controllers.MainMenuController),
	require(script.Controllers.HudController),
	require(script.Controllers.ShopController),
	require(script.Controllers.RebirthController),
	require(script.Controllers.AudioController),
	require(script.Controllers.GraphicsController),
	require(script.Controllers.ExampleController),
	require(script.Controllers.PlotController),
	require(script.Controllers.CameraController),
	require(script.Controllers.SprintController),
	require(script.Controllers.EquipmentController),
	require(script.Controllers.PurchaseGuidanceController),
}

for _, controller in controllers do
	controller.Init()
end

for _, controller in controllers do
	controller.Start()
end

logger.Info("Ready")

if game:GetService("RunService"):IsStudio() and require(Shared.HudConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function(): ()
		require(script.UI.HudClientTests).Run(require(script.Controllers.SettingsController))
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.ShopConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function()
		require(script.UI.ShopClientTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.RebirthConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function()
		require(script.UI.RebirthClientTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.SprintConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function()
		require(script.UI.StaminaViewTests).Run()
		require(script.UI.EquipmentInputTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.MainMenuConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function()
		require(script.UI.MainMenuClientTests).Run()
	end)
end
