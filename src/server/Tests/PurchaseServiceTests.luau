--!strict
-- Requires the authored farm and wooden-wall assets and the normal server bootstrap, never plugin require.
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Settings = require(Shared.PurchaseConfig)
local FarmSettings = require(Shared.FarmConfig)
local DataService = require(script.Parent.Parent.Services.DataService)
local PlotService = require(script.Parent.Parent.Services.PlotService)
local FarmService = require(script.Parent.Parent.Services.FarmService)
local PurchaseService = require(script.Parent.Parent.Services.PurchaseService)
local Logger = require(Shared.Logger)
local Tests = {}

function Tests.Run(): ()
	assert(game:GetService("RunService"):IsStudio(), "Studio tests only")
	assert(DataService.GetStorageMode() == "Mock", "Purchase tests require Mock mode")
	assert(
		not Config.DATA.RUN_TESTS_IN_STUDIO
			and not Config.PLOTS.RUN_TESTS_IN_STUDIO
			and not FarmSettings.RUN_TESTS_IN_STUDIO,
		"Run purchase tests separately"
	)
	require(script.Parent.PlatePresentationTests).Run()
	require(script.Parent.ProductionTests).Run()
	local deadline = os.clock() + Config.DATA.TEST_TIMEOUT_SECONDS
	local player: Player? = nil
	repeat
		player = Players:GetPlayers()[1]
		if player ~= nil and player.Character ~= nil and DataService.GetSnapshot(player) ~= nil then
			break
		end
		task.wait(Config.DATA.WAIT_INTERVAL_SECONDS)
	until os.clock() >= deadline
	assert(player ~= nil, "No player ready")
	local owner = player :: Player
	local character = owner.Character
	local before = DataService.GetSnapshot(owner)
	assert(
		character ~= nil and character:FindFirstChild("HumanoidRootPart") ~= nil and before ~= nil,
		"Character/data unavailable"
	)
	assert(PlotService.GetKingdom(owner) == nil, "Run before claiming")
	local original = character:GetPivot()
	local function setGold(gold: number): ()
		assert(DataService.Update(owner, function(draft): ()
			draft.Gold = gold
		end))
	end
	local function claim(): Model
		local marker = workspace.Plots.Plot01.ClaimMarker :: BasePart
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 10)))
		assert(PlotService.TryClaim(owner, "Plot01"), "Claim failed")
		local kingdom = PlotService.GetKingdom(owner)
		assert(kingdom ~= nil, "Missing kingdom")
		return kingdom
	end
	local function attempt(kingdom: Model, id: string): boolean
		local plates = kingdom:FindFirstChild("PurchasePlates")
		local plate = if plates ~= nil then plates:FindFirstChild(id) else nil
		assert(plate ~= nil and plate:IsA("BasePart"), "Install 1.6 purchase plates")
		-- No yield between placement and request: native touches cannot race this call.
		character:PivotTo(CFrame.new(plate.Position + Vector3.new(0, 3, 0)))
		return PurchaseService.TryPurchase(owner, id)
	end
	local ok, reason = xpcall(function(): string?
		assert(DataService.Update(owner, function(draft): ()
			draft.Gold = 0
			draft.PurchasedBuildings = {}
		end))
		local kingdom = claim()
		local plates = kingdom:FindFirstChild("PurchasePlates")
		assert(plates ~= nil, "Missing purchase plates")
		local unlocks = kingdom:FindFirstChild("PurchaseUnlocks")
		assert(unlocks ~= nil, "Install wooden-wall unlock folder")
		assert(unlocks:FindFirstChild("WoodenWalls") == nil, "Unowned walls visible")
		assert(not PurchaseService.TryPurchase(owner, "WoodenWalls"), "Bought walls before farm upgrades")
		local marker = workspace.Plots.Plot01.ClaimMarker :: BasePart
		assert(
			marker.Transparency == 1 and (marker:FindFirstChild("Outline") :: BasePart).Transparency == 1,
			"Used claim plate remains visible"
		)
		assert(FarmService.HasProducer(owner, "FarmDropper04"), "Install all three producer models")
		setGold(100)
		assert(not PurchaseService.TryPurchase(owner, "FarmDropper02"), "Bought before Start Farm")
		assert(#plates:GetChildren() == 0, "Purchases shown before farm activation")
		local start = kingdom:FindFirstChild("FarmStartPlate") :: BasePart
		character:PivotTo(CFrame.new(start.Position + Vector3.new(0, 3, 0)))
		assert(FarmService.TryStart(owner), "Start failed")
		local farm = kingdom:FindFirstChild("StarterFarm") :: Model
		local producers = farm:FindFirstChild("Producers") :: Folder
		assert(#producers:GetChildren() == 0, "Locked producers visible")
		assert(not PurchaseService.TryPurchase(owner, "FarmDropper03"), "Skipped prerequisite")
		local revealDeadline = os.clock() + Config.DATA.TEST_TIMEOUT_SECONDS
		while #plates:GetChildren() == 0 and os.clock() < revealDeadline do
			task.wait(Config.DATA.WAIT_INTERVAL_SECONDS)
		end
		local visible = plates:GetChildren()
		assert(#visible == 1 and visible[1].Name == "FarmDropper02", "Future purchases are visible")
		assert(
			start.Transparency == 1 and (start:FindFirstChild("Outline") :: BasePart).Transparency == 1,
			"Used start plate remains visible"
		)
		setGold(0)
		task.wait(Settings.TOUCH_COOLDOWN_SECONDS + FarmSettings.TICK_SECONDS)
		assert(not attempt(kingdom, "FarmDropper02"), "Insufficient funds accepted")
		assert(
			(plates:FindFirstChild("FarmDropper02") :: BasePart).Color == Config.PLATES.UNAVAILABLE_COLOR,
			"Unaffordable next plate not red"
		)
		setGold(100)
		character:PivotTo(original)
		task.wait(Settings.TOUCH_COOLDOWN_SECONDS + FarmSettings.TICK_SECONDS)
		local remaining = 100
		local expectedNext = 2
		for _, entry in Settings.PURCHASES do
			if not entry.FarmDropper then
				continue
			end
			assert(#plates:GetChildren() == 1, "More than the next purchase is visible")
			local nextPlate = plates:FindFirstChild(entry.Id)
			assert(
				nextPlate ~= nil and nextPlate:IsA("BasePart") and nextPlate.Color == Config.PLATES.AVAILABLE_COLOR,
				"Funded next plate not green"
			)
			assert(
				(nextPlate:FindFirstChild("PurchaseLabel", true) :: TextLabel).Text
					== string.format('Dropper %d\n%d <font color="#E7B84B">●</font>', expectedNext, entry.Price),
				"Purchase name/price/icon incorrect"
			)
			local label = nextPlate:FindFirstChild("PurchaseLabel", true) :: TextLabel
			assert(label.Parent ~= nil and label.Parent:IsA("BillboardGui"), "Label is not hovering over the plate")
			assert(
				label.BackgroundTransparency == 1
					and label.Font == Enum.Font.GothamBold
					and label.TextSize == Config.PLATES.LABEL_SIZE,
				"Label style regressed"
			)
			assert(nextPlate.Size.Y == Config.PLATES.DIAMETER, "Plate is not compact")
			assert(attempt(kingdom, entry.Id), "Valid purchase rejected")
			expectedNext += 1
			remaining -= entry.Price
			local after = DataService.GetSnapshot(owner)
			assert(
				after ~= nil and after.Gold == remaining and after.PurchasedBuildings[entry.Id],
				"Incorrect charge/ownership"
			)
			assert(not PurchaseService.TryPurchase(owner, entry.Id), "Duplicate purchase accepted")
		end
		character:PivotTo(original)
		-- Data notifications may be deferred by Studio's signal behavior.
		task.wait(FarmSettings.TICK_SECONDS)
		assert(#producers:GetChildren() == 3, "Purchased producers not revealed")
		local bundles = farm:FindFirstChild("ActiveBundles") :: Folder
		local sources: { [string]: boolean } = {}
		local watch = bundles.ChildAdded:Connect(function(bundle: Instance): ()
			local id = bundle:GetAttribute("ProducerId")
			if typeof(id) == "string" then
				sources[id] = true
			end
		end)
		local spawnDeadline = os.clock() + Config.DATA.TEST_TIMEOUT_SECONDS
		repeat
			task.wait(FarmSettings.TICK_SECONDS)
		until (sources.StarterFarm and sources.Dropper02 and sources.Dropper03 and sources.Dropper04)
			or os.clock() >= spawnDeadline
		watch:Disconnect()
		assert(
			sources.StarterFarm and sources.Dropper02 and sources.Dropper03 and sources.Dropper04,
			"Not all four drop points produced bundles"
		)
		assert(farm:GetAttribute("ActiveProducerCount") == 4, "Four producers not enabled")
		assert(#bundles:GetChildren() <= FarmSettings.MAX_BUNDLES, "Shared cap exceeded")
		local earningsBefore = farm:GetAttribute("UncollectedGold") :: number
		local productionDeadline = os.clock() + Config.DATA.TEST_TIMEOUT_SECONDS
		repeat
			task.wait(FarmSettings.TICK_SECONDS)
		until (farm:GetAttribute("UncollectedGold") :: number) >= earningsBefore + 4 * FarmSettings.BUNDLE_VALUE
			or os.clock() >= productionDeadline
		assert(
			(farm:GetAttribute("UncollectedGold") :: number) >= earningsBefore + 4 * FarmSettings.BUNDLE_VALUE,
			"Upgraded physical production did not reach shared collector"
		)
		local wallPlate = plates:FindFirstChild("WoodenWalls")
		assert(
			#plates:GetChildren() == 1 and wallPlate ~= nil and wallPlate:IsA("BasePart"),
			"Walls not offered after Dropper 4"
		)
		assert(
			(wallPlate:FindFirstChild("PurchaseLabel", true) :: TextLabel).Text
				== 'Wooden Walls\n40 <font color="#E7B84B">●</font>',
			"Wrong wall label"
		)
		setGold(39)
		character:PivotTo(original)
		task.wait(Settings.TOUCH_COOLDOWN_SECONDS + FarmSettings.TICK_SECONDS)
		assert(wallPlate.Color == Config.PLATES.UNAVAILABLE_COLOR, "39 Gold wall plate not red")
		assert(not attempt(kingdom, "WoodenWalls"), "Walls accepted 39 Gold")
		local rejected = DataService.GetSnapshot(owner)
		assert(
			rejected ~= nil and rejected.Gold == 39 and not rejected.PurchasedBuildings.WoodenWalls,
			"Rejected walls changed saved data"
		)
		character:PivotTo(original)
		setGold(40)
		task.wait(Settings.TOUCH_COOLDOWN_SECONDS + FarmSettings.TICK_SECONDS)
		assert(wallPlate.Color == Config.PLATES.AVAILABLE_COLOR, "40 Gold wall plate not green")
		assert(not PurchaseService.TryPurchase(owner, "WoodenWalls"), "Distant wall purchase accepted")
		task.wait(Settings.TOUCH_COOLDOWN_SECONDS + FarmSettings.TICK_SECONDS)
		assert(attempt(kingdom, "WoodenWalls"), "Valid wall purchase rejected")
		remaining = 0
		local bought = DataService.GetSnapshot(owner)
		assert(
			bought ~= nil and bought.Gold == 0 and bought.PurchasedBuildings.WoodenWalls == true,
			"Incorrect wall charge/ownership"
		)
		assert(not PurchaseService.TryPurchase(owner, "WoodenWalls"), "Duplicate wall purchase accepted")
		local walls = unlocks:FindFirstChild("WoodenWalls")
		assert(walls ~= nil and walls:IsA("Model"), "Purchased walls not revealed")
		assert(#plates:GetChildren() == 0, "Completed chain left a purchase plate")
		PlotService.Release(owner)
		assert(marker.Transparency == 0, "Released claim plate did not return")
		assert(producers.Parent == nil and bundles.Parent == nil and walls.Parent == nil, "Release leaked assets")
		task.wait(Config.PLOTS.CLAIM_COOLDOWN_SECONDS + FarmSettings.TICK_SECONDS)
		kingdom = claim()
		assert(
			not FarmService.IsStarted(owner) and kingdom:FindFirstChild("StarterFarm") == nil,
			"Reclaim auto-started"
		)
		local restoredUnlocks = kingdom:FindFirstChild("PurchaseUnlocks")
		assert(
			restoredUnlocks ~= nil and restoredUnlocks:FindFirstChild("WoodenWalls") ~= nil,
			"Saved walls not restored before farm activation"
		)
		assert(
			(kingdom:FindFirstChild("PurchasePlates") :: Folder):FindFirstChild("WoodenWalls") == nil,
			"Owned wall plate restored"
		)
		start = kingdom:FindFirstChild("FarmStartPlate") :: BasePart
		character:PivotTo(CFrame.new(start.Position + Vector3.new(0, 3, 0)))
		assert(FarmService.TryStart(owner), "Restore start failed")
		farm = kingdom:FindFirstChild("StarterFarm") :: Model
		assert(#(farm:FindFirstChild("Producers") :: Folder):GetChildren() == 3, "Saved producers not restored")
		local restored = DataService.GetSnapshot(owner)
		assert(restored ~= nil and restored.Gold == remaining, "Reclaim charged again")
		return nil
	end, debug.traceback)
	PlotService.Release(owner)
	character:PivotTo(original)
	assert(DataService.Update(owner, function(draft): ()
		draft.Gold = before.Gold
		draft.PurchasedBuildings = table.clone(before.PurchasedBuildings)
	end))
	assert(ok, reason)
	Logger.new("PurchaseServiceTests").Info("All farm purchase-service checks passed")
	Logger.new("PurchaseServiceTests").Info("All wooden-wall purchase checks passed")
end

return Tests
