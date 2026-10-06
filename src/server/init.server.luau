--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Logger"))
local Types = require(Shared:WaitForChild("Types"))

local logger = Logger.new("ServerBootstrap")

-- Require and run services in this explicit order. Add services as milestones land.
local services: { Types.Lifecycle } = {
	require(script.Services.DataService),
	require(script.Services.ExampleService),
}

for _, service in services do
	service.Init()
end

for _, service in services do
	service.Start()
end

logger.Info("Ready")

local Config = require(Shared:WaitForChild("Config"))
if game:GetService("RunService"):IsStudio() and Config.DATA.RUN_TESTS_IN_STUDIO then
	task.spawn(function(): ()
		require(script.Tests.DataLayerTests).Run()
	end)
end
