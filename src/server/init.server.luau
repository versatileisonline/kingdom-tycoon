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
	require(script.Services.EntryService),
	require(script.Services.FarmService),
	require(script.Services.PurchaseService),
	require(script.Services.ProtectionDoorService),
	require(script.Services.KingdomResidentsService),
	require(script.Services.EquipmentService),
	require(script.Services.TrainingCourseService),
	require(script.Services.SprintService),
	require(script.Services.ShopService),
	require(script.Services.RebirthService),
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

if game:GetService("RunService"):IsStudio() and require(Shared.ShopConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function()
		require(script.Tests.ShopServiceTests).Run()
		if script:GetAttribute("StudioShopRegression") == true then
			local suites = {
				{ Name = "FarmServiceTests", Run = require(script.Tests.FarmServiceTests).Run },
				{ Name = "PurchaseServiceTests", Run = require(script.Tests.PurchaseServiceTests).Run },
				{ Name = "MintUpgraderChainTests", Run = require(script.Tests.MintUpgraderChainTests).Run },
				{ Name = "SecondRoyalMintTests", Run = require(script.Tests.SecondRoyalMintTests).Run },
				{ Name = "TutorialServiceTests", Run = require(script.Tests.TutorialServiceTests).Run },
				{ Name = "HudServiceTests", Run = require(script.Tests.HudServiceTests).Run },
			}
			for _, suite in suites do
				task.wait(Config.PLOTS.CLAIM_COOLDOWN_SECONDS + 0.25)
				print("[KingdomTycoon][ShopRegression] Starting " .. suite.Name)
				suite.Run()
			end
			print("[KingdomTycoon][ShopRegression] All shop regression checks passed")
		end
	end)
end

if require(script.Services.EntitlementService).IsPreview() and not require(Shared.ShopConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function()
		require(script.Tests.ShopPreview).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.RebirthConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function()
		require(script.Tests.RebirthServiceTests).Run()
		if script:GetAttribute("StudioRebirthRegression") == true then
			for _, run in
				{
					require(script.Tests.FarmServiceTests).Run,
					require(script.Tests.PurchaseServiceTests).Run,
					require(script.Tests.MintUpgraderChainTests).Run,
					require(script.Tests.SecondRoyalMintTests).Run,
					require(script.Tests.TutorialServiceTests).Run,
					require(script.Tests.HudServiceTests).Run,
				}
			do
				task.wait(1.2)
				run()
			end
			require(script.Tests.ShopEconomyTests).Run(
				require(script.Farms.SessionEarnings),
				require(script.Farms.FarmLedger)
			)
			print("[KingdomTycoon][RebirthRegression] All rebirth regressions passed")
		end
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.SprintConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function()
		require(script.Tests.OptionalAdditionsTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.MainMenuConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function()
		require(script.Tests.EntryServiceTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and require(Shared.TrainingCourseConfig).RUN_TESTS_IN_STUDIO then
	task.spawn(function()
		require(script.Tests.TrainingCourseStateTests).Run(require(script.Training.CourseState))
		require(script.Tests.TrainingCourseServiceTests).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and script:GetAttribute("StudioCourtyardPreview") == true then
	task.spawn(function()
		require(script.Tests.CourtyardPreview).Run()
	end)
end

if game:GetService("RunService"):IsStudio() and script:GetAttribute("StudioStrongholdTests") == true then
	task.spawn(function()
		require(script.Tests.StrongholdServiceTests).Run()
		if script:GetAttribute("StudioStrongholdRegression") == true then
			for _, run in
				{
					require(script.Tests.FarmServiceTests).Run,
					require(script.Tests.PurchaseServiceTests).Run,
					require(script.Tests.RebirthServiceTests).Run,
				}
			do
				task.wait(1.3)
				run()
			end
			print("[KingdomTycoon][Stronghold] All stronghold regressions passed")
		end
	end)
end
