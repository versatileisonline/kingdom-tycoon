--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Logger"))

local logger = Logger.new("ExampleController")
local ExampleController = {}

function ExampleController.Init(): ()
	-- Reserve initialization for dependencies/state; start behavior in Start().
end

function ExampleController.Start(): ()
	logger.Info("Started")
end

return ExampleController
