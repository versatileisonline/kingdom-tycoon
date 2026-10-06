--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Logger"))
local Types = require(Shared:WaitForChild("Types"))

local logger = Logger.new("ClientBootstrap")

-- Require and run controllers in this explicit order. Add controllers as milestones land.
local controllers: { Types.Lifecycle } = {
	require(script.Controllers.ExampleController),
}

for _, controller in controllers do
	controller.Init()
end

for _, controller in controllers do
	controller.Start()
end

logger.Info("Ready")
