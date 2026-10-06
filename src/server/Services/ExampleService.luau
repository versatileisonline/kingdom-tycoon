--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Logger"))

local logger = Logger.new("ExampleService")
local ExampleService = {}

function ExampleService.Init(): ()
	-- Reserve initialization for dependencies/state; start behavior in Start().
end

function ExampleService.Start(): ()
	logger.Info("Started")
end

return ExampleService
