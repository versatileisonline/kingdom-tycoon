--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Logger"))
local Types = require(Shared:WaitForChild("Types"))

local logger = Logger.new("ServerBootstrap")

-- Require and run services in this explicit order. Add services as milestones land.
local services: { Types.Lifecycle } = {
	require(script.Services.DataService),
	require(script.Services.PresentationService),
	require(script.Services.EntitlementService),
	require(script.Services.PlotService),
	require(script.Services.FarmService),
	require(script.Services.PurchaseService),
	require(script.Services.ShopService),
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
local FarmConfig = require(Shared:WaitForChild("FarmConfig"))
if game:GetService("RunService"):IsStudio() and FarmConfig.RUN_TESTS_IN_STUDIO then
	task.spawn(function(): ()
		require(script.Tests.FarmServiceTests).Run()
	end)
end
if game:GetService("RunService"):IsStudio() and Config.PLOTS.RUN_TESTS_IN_STUDIO then
	task.spawn(function(): ()
		require(script.Tests.PlotServiceTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and Config.DATA.RUN_TESTS_IN_STUDIO then
	task.spawn(function(): ()
		require(script.Tests.DataLayerTests).Run()
	end)
end

local PurchaseConfig = require(Shared:WaitForChild("PurchaseConfig"))
if game:GetService("RunService"):IsStudio() and PurchaseConfig.RUN_TESTS_IN_STUDIO then
	task.spawn(function(): ()
		require(script.Tests.PurchaseServiceTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.HudConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function(): ()
		require(script.Tests.HudServiceTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.MintConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function(): ()
		require(script.Tests.RoyalMintTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.MintConfig).RUN_UPGRADER_TESTS_IN_STUDIO then
	task.spawn(function(): ()
		require(script.Tests.MintUpgraderTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.MintConfig).RUN_UPGRADER_CHAIN_TESTS_IN_STUDIO then
	task.spawn(function(): ()
		require(script.Tests.MintUpgraderChainTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.MintConfig).RUN_SECOND_LANE_TESTS_IN_STUDIO then
	task.spawn(function(): ()
		require(script.Tests.SecondRoyalMintTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.TutorialConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function(): ()
		require(script.Tests.TutorialServiceTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and script:GetAttribute("StudioTutorialPreview") == true then
	task.spawn(function(): ()
		require(script.Tests.TutorialPreview).Run()
	end)
end
