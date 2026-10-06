--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Logger"))
local Types = require(Shared:WaitForChild("Types"))

local logger = Logger.new("ServerBootstrap")

-- Require and run services in this explicit order. Add services as milestones land.
local services: { Types.Lifecycle } = {
	require(script.Services.ExampleService),
}

for _, service in services do
	service.Init()
end

for _, service in services do
	service.Start()
end

logger.Info("Ready")
