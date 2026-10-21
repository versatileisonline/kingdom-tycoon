--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Logger = require(Shared.Logger)
local DataService = require(script.Parent.Parent.Services.DataService)
local PlotService = require(script.Parent.Parent.Services.PlotService)
local PlotRegistry = require(script.Parent.Parent.Plots.PlotRegistry)
local logger = Logger.new("PlotServiceTests")
local Tests = {}

function Tests.Run(): ()
	assert(RunService:IsStudio() and RunService:IsServer(), "Studio server tests only")
	assert(DataService.GetStorageMode() == "Mock", "Plot tests require Mock mode")
	local registry = PlotRegistry.new({ "A", "B" })
	assert(registry.Reserve(1, "A"))
	assert(not registry.Reserve(2, "A"), "A second claimant must lose")
	assert(not registry.Reserve(1, "B"), "One player cannot claim two plots")
	assert(not registry.Reserve(2, "Missing"), "Unknown plots must fail")
	assert(registry.GetOwner("A") == 1 and registry.GetPlot(1) == "A", "Ownership maps disagree")
	assert(registry.Release(2) == nil, "A non-owner cannot release another player's plot")
	assert(registry.GetOwner("A") == 1, "Non-owner release affected owner")
	assert(registry.Release(1) == "A", "Release returned wrong plot")
	assert(registry.GetOwner("A") == nil and registry.GetPlot(1) == nil, "Release left stale ownership")
	assert(registry.Release(1) == nil, "Release must be idempotent")
	assert(registry.Reserve(2, "A"), "Released plots must be reusable")
	assert(not pcall(function(): ()
		PlotRegistry.new({ "A", "A" })
	end), "Duplicate plot IDs must fail")
	logger.Info("Ownership conflict, exclusivity, release, and reuse checks passed")

	local deadline = os.clock() + Config.DATA.TEST_TIMEOUT_SECONDS
	local player: Player? = nil
	repeat
		player = Players:GetPlayers()[1]
		if player ~= nil and player.Character ~= nil and DataService.GetSnapshot(player) ~= nil then
			break
		end
		task.wait(Config.DATA.WAIT_INTERVAL_SECONDS)
	until os.clock() >= deadline
	assert(player ~= nil and DataService.GetSnapshot(player) ~= nil, "No data-ready player for plot checks")
	local character = player.Character
	assert(character ~= nil and character:FindFirstChild("HumanoidRootPart") ~= nil, "Character is not ready")
	assert(PlotService.GetPlotId(player) == nil, "Run plot tests before manually claiming land")
	local original = character:GetPivot()
	local source = game:GetService("ServerStorage"):FindFirstChild("KingdomTemplate")
	assert(source ~= nil, "Missing KingdomTemplate")
	local label = source:FindFirstChild("OwnerLabel", true)
	assert(label ~= nil, "Missing OwnerLabel")
	local plotFolder = workspace:FindFirstChild("Plots")
	local active = workspace:FindFirstChild("ActiveKingdoms")
	assert(plotFolder ~= nil and active ~= nil, "Missing plot folders")
	local availableBefore = plotFolder:GetAttribute("AvailablePlotCount")
	assert(typeof(availableBefore) == "number", "Server availability count missing")
	local plot = plotFolder:FindFirstChild("Plot01")
	assert(plot ~= nil, "Missing Plot01")
	local marker = plot:FindFirstChild("ClaimMarker")
	assert(marker ~= nil and marker:IsA("BasePart"), "Missing ClaimMarker")
	local prompt = marker:FindFirstChild("ClaimPrompt")
	assert(prompt ~= nil and prompt:IsA("ProximityPrompt"), "Missing ClaimPrompt")
	local before = DataService.GetSnapshot(player)
	local function nextRequest(): ()
		task.wait(Config.PLOTS.CLAIM_COOLDOWN_SECONDS + Config.DATA.WAIT_INTERVAL_SECONDS)
	end
	local ok, failure = xpcall(function(): string?
		assert(not PlotService.TryClaim(player :: Player, {}), "Malformed plot argument accepted")
		nextRequest()
		character:PivotTo(marker.CFrame + Vector3.new(0, 0, Config.PLOTS.CLAIM_DISTANCE * 3))
		assert(not PlotService.TryClaim(player :: Player, "Plot01"), "Distant claim accepted")
		nextRequest()
		character:PivotTo(marker.CFrame + Vector3.new(0, 0, 3))
		label.Name = "TemporarilyMissingOwnerLabel"
		assert(not PlotService.TryClaim(player :: Player, "Plot01"), "Broken template should fail")
		label.Name = "OwnerLabel"
		assert(
			PlotService.GetPlotId(player :: Player) == nil and #active:GetChildren() == 0,
			"Rollback leaked ownership or clone"
		)
		assert(plot:GetAttribute("OwnerUserId") == nil and prompt.Enabled, "Rollback did not restore plot")
		nextRequest()
		assert(PlotService.TryClaim(player :: Player, "Plot01"), "Valid claim failed")
		assert(PlotService.GetPlotId(player :: Player) == "Plot01", "Registry assignment missing")
		assert(player:GetAttribute("KingdomPlotId") == "Plot01", "Player ownership attribute missing")
		assert(
			plot:GetAttribute("OwnerUserId") == player.UserId and not prompt.Enabled,
			"Plot ownership state incorrect"
		)
		assert(#active:GetChildren() == 1, "Expected exactly one kingdom")
		assert(
			plotFolder:GetAttribute("AvailablePlotCount") == availableBefore - 1,
			"Claim did not update availability"
		)
		local kingdom = active:FindFirstChild("Plot01")
		assert(
			kingdom ~= nil and player.RespawnLocation == kingdom:FindFirstChild("SpawnPoint"),
			"Kingdom respawn not assigned"
		)
		local claimLabel = marker:FindFirstChild("ClaimLabel", true)
		assert(
			claimLabel ~= nil and claimLabel:IsA("TextLabel") and not claimLabel.Visible,
			"Duplicate claim label still visible"
		)
		assert(not PlotService.TryClaim(player :: Player, "Plot01"), "Rapid repeat claim accepted")
		nextRequest()
		assert(not PlotService.TryClaim(player :: Player, "Plot01"), "Duplicate claim accepted")
		PlotService.Release(player :: Player)
		PlotService.Release(player :: Player)
		assert(#active:GetChildren() == 0 and prompt.Enabled, "Release leaked a kingdom or disabled prompt")
		assert(plotFolder:GetAttribute("AvailablePlotCount") == availableBefore, "Release did not restore availability")
		local map = workspace:FindFirstChild("KingdomMap")
		assert(
			map ~= nil and player.RespawnLocation == map:FindFirstChild("ArrivalSpawn"),
			"Release did not restore plaza spawn"
		)
		assert(
			player:GetAttribute("KingdomPlotId") == nil and plot:GetAttribute("OwnerUserId") == nil,
			"Release left ownership attributes"
		)
		nextRequest()
		assert(PlotService.TryClaim(player :: Player, "Plot01"), "Reclaim failed")
		local after = DataService.GetSnapshot(player :: Player)
		assert(
			before ~= nil and after ~= nil and before.Gold == after.Gold and before.Rebirths == after.Rebirths,
			"Plots modified progression"
		)
		local claimed = active:FindFirstChild("Plot01")
		local spawn = if claimed ~= nil then claimed:FindFirstChild("SpawnPoint") else nil
		assert(spawn ~= nil and spawn:IsA("SpawnLocation"), "Kingdom spawn missing")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		assert(humanoid ~= nil, "Humanoid missing before respawn check")
		humanoid.Health = 0
		local respawnDeadline = os.clock() + Config.DATA.TEST_TIMEOUT_SECONDS
		local respawned = false
		repeat
			local current = player.Character
			local root = if current ~= nil then current:FindFirstChild("HumanoidRootPart") else nil
			if current ~= character and root ~= nil and root:IsA("BasePart") then
				respawned = (root.Position - spawn.Position).Magnitude <= Config.PLOTS.TEST_SPAWN_RADIUS
			end
			if not respawned then
				task.wait(Config.DATA.WAIT_INTERVAL_SECONDS)
			end
		until respawned or os.clock() >= respawnDeadline
		assert(respawned, "Actual character respawn did not reach its kingdom")
		logger.Info("Actual character respawn reached its kingdom")
		return nil
	end, debug.traceback)
	label.Name = "OwnerLabel"
	PlotService.Release(player)
	local current = player.Character
	if current ~= nil then
		current:PivotTo(original)
	end
	assert(ok, failure)
	logger.Info("All plot-system checks passed (validation, throttle, rollback, clone, release, reclaim)")
end

return Tests
