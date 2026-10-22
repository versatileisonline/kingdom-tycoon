--!strict

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Settings = require(Shared.FarmConfig)
local Logger = require(Shared.Logger)
local FarmLedger = require(script.Parent.Parent.Farms.FarmLedger)
local logger = Logger.new("FarmServiceTests")
local Tests = {}

-- No players, physics, or data writes. Safe to run alone from Studio Edit mode.
function Tests.RunAccounting(): ()
	local ledger = FarmLedger.new(
		Settings.MAX_BUNDLES,
		Settings.BUNDLE_LIFETIME_SECONDS,
		Settings.BUNDLE_VALUE,
		Config.DATA.MAX_SAFE_INTEGER
	)
	local other = FarmLedger.new(
		Settings.MAX_BUNDLES,
		Settings.BUNDLE_LIFETIME_SECONDS,
		Settings.BUNDLE_VALUE,
		Config.DATA.MAX_SAFE_INTEGER
	)
	local token = {}
	assert(ledger.Register(token, 0))
	assert(not ledger.Register(token, 0), "Duplicate registration accepted")
	assert(not ledger.Remove({}, 1, true), "Unregistered arrival awarded gold")
	assert(not other.Remove(token, 1, true), "One farm credited another farm's bundle")
	assert(ledger.Remove(token, 1, true), "Valid arrival failed")
	assert(not ledger.Remove(token, 1, true), "Repeated arrival credited twice")
	assert(ledger.GetBalance() == Settings.BUNDLE_VALUE and other.GetBalance() == 0, "Farm balances mixed")
	local expired = {}
	assert(ledger.Register(expired, 0))
	assert(not ledger.Remove(expired, Settings.BUNDLE_LIFETIME_SECONDS, true), "Expired arrival awarded gold")
	assert(ledger.GetCount() == 0, "Expiry did not release bundle capacity")
	local destroyed = {}
	assert(ledger.Register(destroyed, 0))
	assert(not ledger.Remove(destroyed, 1, false), "Lost bundle awarded gold")
	for _ = 1, Settings.MAX_BUNDLES do
		assert(ledger.Register({}, 0))
	end
	assert(not ledger.Register({}, 0), "Bundle cap exceeded")
	assert(ledger.GetCount() == Settings.MAX_BUNDLES, "Active count differs from cap")
	local failed = ledger.Collect(function(_amount: number): boolean
		return false
	end)
	assert(not failed and ledger.GetBalance() == Settings.BUNDLE_VALUE, "Failed update lost earnings")
	local credited = 0
	local collected, amount = ledger.Collect(function(value: number): boolean
		credited += value
		return true
	end)
	assert(
		collected and amount == Settings.BUNDLE_VALUE and credited == amount and ledger.GetBalance() == 0,
		"Successful collection did not transfer exactly once"
	)
	assert(not ledger.Collect(function(value: number): boolean
		credited += value
		return true
	end), "Repeated collection succeeded")
	assert(credited == Settings.BUNDLE_VALUE, "Repeated collection duplicated gold")
	ledger.Clear()
	assert(ledger.GetCount() == 0 and ledger.GetBalance() == 0, "Cleanup left session earnings")
	assert(not ledger.Remove(token, 1, true), "Released bundle still credited")
	local limited = FarmLedger.new(2, 20, 1, 1)
	local a, b = {}, {}
	assert(limited.Register(a, 0) and limited.Register(b, 0), "Overflow fixtures not registered")
	assert(limited.Remove(a, 1, true) and not limited.Remove(b, 1, true), "Balance overflow not bounded")
	assert(limited.GetBalance() == 1 and limited.GetCount() == 0, "Overflow changed accounting")
	logger.Info("All farm accounting checks passed (duplicate credit, expiry, isolation, cap, failed update, cleanup)")
end

function Tests.Run(): ()
	assert(RunService:IsStudio() and RunService:IsServer(), "Studio server tests only")
	assert(not Config.PLOTS.RUN_TESTS_IN_STUDIO and not Config.DATA.RUN_TESTS_IN_STUDIO, "Run farm tests separately")
	Tests.RunAccounting()
	local DataService = require(script.Parent.Parent.Services.DataService)
	local PlotService = require(script.Parent.Parent.Services.PlotService)
	local FarmService = require(script.Parent.Parent.Services.FarmService)
	assert(DataService.GetStorageMode() == "Mock", "Farm tests require Mock mode")
	local player: Player? = nil
	local deadline = os.clock() + Config.DATA.TEST_TIMEOUT_SECONDS
	repeat
		player = Players:GetPlayers()[1]
		local character = if player ~= nil then player.Character else nil
		if
			player ~= nil
			and character ~= nil
			and character:FindFirstChild("HumanoidRootPart") ~= nil
			and DataService.GetSnapshot(player) ~= nil
		then
			break
		end
		task.wait(Config.DATA.WAIT_INTERVAL_SECONDS)
	until os.clock() >= deadline
	assert(player ~= nil, "No player for farm tests")
	local owner = player :: Player
	local character = owner.Character
	local before = DataService.GetSnapshot(owner)
	assert(character ~= nil and before ~= nil, "Player character/data not ready")
	assert(PlotService.GetKingdom(owner) == nil, "Run tests before manually claiming")
	local original = character:GetPivot()
	local plots = workspace:FindFirstChild("Plots")
	local plot = if plots ~= nil then plots:FindFirstChild("Plot01") else nil
	local marker = if plot ~= nil then plot:FindFirstChild("ClaimMarker") else nil
	assert(marker ~= nil and marker:IsA("BasePart"), "Missing Plot01 marker")
	local releaseBeforeDestroy = false
	local unsubscribe = PlotService.ObserveKingdoms(
		function(_player: Player, _kingdom: Model): () end,
		function(released: Player, kingdom: Model): ()
			if released == owner then
				releaseBeforeDestroy = kingdom.Parent ~= nil
			end
		end
	)
	local ok, reason = xpcall(function(): string?
		-- Stay off the plate while invoking TryClaim directly, avoiding native-touch races.
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 10)))
		assert(PlotService.TryClaim(owner, "Plot01"), "Claim failed")
		local initialKingdom = PlotService.GetKingdom(owner)
		assert(initialKingdom ~= nil, "Missing assigned kingdom")
		assert(initialKingdom:FindFirstChild("StarterFarm") == nil, "Farm revealed on claim")
		assert(initialKingdom:GetAttribute("StarterFarmStarted") == false, "Farm started on claim")
		assert(not FarmService.TryCollect(owner), "Inactive farm allowed collection")
		local initialStart = initialKingdom:FindFirstChild("FarmStartPlate")
		assert(initialStart ~= nil and initialStart:IsA("BasePart"), "Missing farm start plate")
		assert(not FarmService.TryStart(owner), "Distant farm activation accepted")
		task.wait(Settings.PRODUCTION_SECONDS + Settings.TICK_SECONDS)
		assert(initialKingdom:FindFirstChild("StarterFarm") == nil, "Inactive farm began producing")
		local inactiveSnapshot = DataService.GetSnapshot(owner)
		assert(inactiveSnapshot ~= nil and inactiveSnapshot.Gold == before.Gold, "Inactive farm changed Gold")
		-- Releasing before activation must also clean the retained, unparented model.
		PlotService.Release(owner)
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 10)))
		assert(PlotService.TryClaim(owner, "Plot01"), "Reclaim before activation failed")
		local kingdom = PlotService.GetKingdom(owner)
		assert(kingdom ~= nil and kingdom:FindFirstChild("StarterFarm") == nil, "Reclaim activated farm")
		local startPlate = kingdom:FindFirstChild("FarmStartPlate")
		assert(startPlate ~= nil and startPlate:IsA("BasePart"), "Missing start plate after reclaim")
		character:PivotTo(CFrame.new(startPlate.Position + Vector3.new(0, 3, 0)))
		assert(FarmService.TryStart(owner), "Owner farm activation failed")
		assert(not FarmService.TryStart(owner), "Farm activated twice")
		assert(not startPlate.CanTouch and startPlate.Transparency == 1, "Start plate remained enabled")
		assert(owner:GetAttribute("StarterFarmStarted") == true, "Activation guidance state missing")
		local farm = kingdom:FindFirstChild("StarterFarm")
		assert(farm ~= nil and farm:GetAttribute("UncollectedGold") == 0, "New farm must start empty")
		local plate = farm:FindFirstChild("CollectPlate")
		local bundles = farm:FindFirstChild("ActiveBundles")
		assert(plate ~= nil and plate:IsA("BasePart") and bundles ~= nil, "Farm did not activate")
		local productionDeadline = os.clock() + Config.DATA.TEST_TIMEOUT_SECONDS
		repeat
			task.wait(Settings.TICK_SECONDS)
		until (farm:GetAttribute("UncollectedGold") :: number) >= 2 * Settings.BUNDLE_VALUE
			or os.clock() >= productionDeadline
		local balance = farm:GetAttribute("UncollectedGold") :: number
		assert(balance >= 2 * Settings.BUNDLE_VALUE, "Bundles failed to travel to pit before timeout")
		assert(#bundles:GetChildren() <= Settings.MAX_BUNDLES, "Active bundle cap exceeded")
		local plateExtent = math.max(plate.Size.X, plate.Size.Y, plate.Size.Z)
		character:PivotTo(CFrame.new(plate.Position + Vector3.new(Settings.COLLECT_DISTANCE + plateExtent, 0, 0)))
		assert(not FarmService.TryCollect(owner), "Distant collection accepted")
		character:PivotTo(CFrame.new(plate.Position + Vector3.new(0, 3, 0)))
		assert(DataService.Update(owner, function(draft): ()
			draft.Gold = Config.DATA.MAX_SAFE_INTEGER
		end))
		assert(not FarmService.TryCollect(owner), "Overflowing data update accepted")
		assert(farm:GetAttribute("UncollectedGold") == balance, "Failed data update lost earnings")
		assert(DataService.Update(owner, function(draft): ()
			draft.Gold = before.Gold
		end))
		-- Stay away while waiting for the cooldown, avoiding automatic touch collection.
		character:PivotTo(original)
		task.wait(Settings.COLLECT_COOLDOWN_SECONDS + Settings.TICK_SECONDS)
		character:PivotTo(CFrame.new(plate.Position + Vector3.new(0, 3, 0)))
		local expected = farm:GetAttribute("UncollectedGold") :: number
		local success, amount = FarmService.TryCollect(owner)
		assert(
			success and amount == expected and farm:GetAttribute("UncollectedGold") == 0,
			"Full balance not collected"
		)
		local after = DataService.GetSnapshot(owner)
		assert(after ~= nil and after.Gold == before.Gold + amount, "Saved Gold differs from collected amount")
		assert(not FarmService.TryCollect(owner), "Repeated collection accepted")
		PlotService.Release(owner)
		assert(releaseBeforeDestroy and kingdom.Parent == nil and bundles.Parent == nil, "Release order/cleanup failed")
		task.wait(Config.PLOTS.CLAIM_COOLDOWN_SECONDS + Settings.TICK_SECONDS)
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 10)))
		assert(PlotService.TryClaim(owner, "Plot01"), "Reclaim failed")
		local nextKingdom = PlotService.GetKingdom(owner)
		assert(nextKingdom ~= nil and nextKingdom:FindFirstChild("StarterFarm") == nil, "Reclaim auto-started farm")
		local nextStart = nextKingdom:FindFirstChild("FarmStartPlate")
		assert(nextStart ~= nil and nextStart:IsA("BasePart"), "Reclaim lost start plate")
		character:PivotTo(CFrame.new(nextStart.Position + Vector3.new(0, 3, 0)))
		assert(FarmService.TryStart(owner), "Reclaimed farm did not start")
		local nextFarm = nextKingdom:FindFirstChild("StarterFarm")
		assert(nextFarm ~= nil and nextFarm:GetAttribute("UncollectedGold") == 0, "Reclaim retained old earnings")
		return nil
	end, debug.traceback)
	unsubscribe()
	PlotService.Release(owner)
	character:PivotTo(original)
	local restored, restoreReason = DataService.Update(owner, function(draft): ()
		draft.Gold = before.Gold
	end)
	assert(restored, restoreReason)
	assert(ok, reason)
	logger.Info(
		"All farm-service checks passed (plate activation, inactive release, production, collection, failure retention, reclaim)"
	)
end

return Tests
