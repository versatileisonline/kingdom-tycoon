--!strict
local Tests = {}
function Tests.Run(): ()
	local services = script.Parent.Parent.Services
	local Data = require(services.DataService)
	local Plots = require(services.PlotService)
	local Purchases = require(services.PurchaseService)
	local Door = require(services.ProtectionDoorService)
	local Shared = game:GetService("ReplicatedStorage").Shared
	assert(game:GetService("RunService"):IsStudio() and Data.GetStorageMode() == "Mock", "Studio Mock only")
	require(script.Parent.ProtectionDoorPolicyTests).Run(require(script.Parent.Parent.Stronghold.ProtectionDoorPolicy))
	local deadline = os.clock() + 20
	repeat
		task.wait(0.1)
	until (
			#game:GetService("Players"):GetPlayers() > 0
			and game:GetService("Players"):GetPlayers()[1].Character ~= nil
			and Data.GetSnapshot(game:GetService("Players"):GetPlayers()[1]) ~= nil
		) or os.clock() > deadline
	local player = game:GetService("Players"):GetPlayers()[1]
	assert(player and player.Character and Data.GetSnapshot(player), "Wait for player data")
	assert(not Plots.GetKingdom(player), "Run before claiming")
	local character = player.Character
	local saved = Data.GetSnapshot(player)
	assert(saved, "Missing snapshot")
	local original = character:GetPivot()
	local entered = player:GetAttribute("KingdomEntered")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
	local anchored = root.Anchored
	local owned: { [string]: boolean } = {}
	for _, entry in require(Shared.PurchaseConfig).PURCHASES do
		owned[entry.Id] = true
		if entry.Id == "RoyalMintUpgrader08" then
			break
		end
	end
	local ok, reason = xpcall(function()
		player:SetAttribute("KingdomEntered", true)
		root.Anchored = false
		assert(Data.Update(player, function(draft)
			draft.Gold = 8000
			draft.PurchasedBuildings = table.clone(owned)
		end))
		local marker = workspace.Plots.Plot01.ClaimMarker :: BasePart
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 0)))
		assert(Plots.TryClaim(player, "Plot01"))
		local kingdom = Plots.GetKingdom(player) :: Model
		local start = kingdom:FindFirstChild("FarmStartPlate") :: BasePart
		character:PivotTo(start.CFrame + Vector3.new(0, 3, 0))
		assert(require(services.FarmService).TryStart(player), "Farm start failed")
		task.wait(0.2)
		local plates = kingdom.PurchasePlates
		assert(plates:FindFirstChild("StoneWalls"), "Stone plate missing")
		assert(not plates:FindFirstChild("ProtectionDoor"), "Future plate revealed")
		local function buy(id: string, price: number)
			assert(Data.Update(player, function(draft)
				draft.Gold = price
			end))
			local plate = plates:FindFirstChild(id) :: BasePart
			assert(plate, "Missing next plate " .. id)
			character:PivotTo(plate.CFrame + Vector3.new(0, 4, 0))
			assert(Purchases.TryPurchase(player, id), "Purchase failed " .. id)
			assert(Data.GetSnapshot(player).Gold == 0, "Incorrect charge")
			assert(not Purchases.TryPurchase(player, id), "Duplicate purchase")
		end
		buy("StoneWalls", 8000)
		assert(not kingdom.PurchaseUnlocks:FindFirstChild("WoodenWalls"), "Wood retained visibly")
		assert(kingdom.PurchaseUnlocks:FindFirstChild("StoneWalls"), "Stone absent")
		print("[KingdomTycoon][Stronghold] All stronghold purchase and replacement checks passed")
		buy("ProtectionDoor", 9000)
		task.wait(0.2)
		local door = kingdom.PurchaseUnlocks.ProtectionDoor
		assert(door:GetAttribute("WardEnabled") == true, "Ward default")
		character:PivotTo(door.ToggleControl.CFrame + Vector3.new(0, 3, 0))
		assert(Door.TryToggle(player, player), "Owner toggle rejected")
		assert(door:GetAttribute("WardEnabled") == false, "Ward did not disable")
		assert(not Door.TryToggle(player, player), "Toggle spam accepted")
		task.wait(1.1)
		assert(Door.TryToggle(player, player))
		character:PivotTo(door.DetectionZone.CFrame)
		task.wait(0.25)
		assert(character:FindFirstChildOfClass("Humanoid").Health > 0, "Owner killed")
		print("[KingdomTycoon][Stronghold] All protection door checks passed")
		buy("ArcherPosts", 10000)
		task.wait(0.2)
		buy("KingdomResidents", 12000)
		task.wait(1)
		local count = 0
		for _, v in kingdom:GetChildren() do
			if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
				count += 1
			end
		end
		assert(count == 14, "Expected14 residents, got " .. count)
		assert(Data.Update(player, function(draft)
			draft.Gold += 1
		end))
		task.wait(0.2)
		local again = 0
		for _, v in kingdom:GetChildren() do
			if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
				again += 1
			end
		end
		assert(again == 14, "Duplicate residents")
		local positions: { [Model]: Vector3 } = {}
		for _, v in kingdom:GetChildren() do
			if v:IsA("Model") and string.sub(v.Name, 1, 8) == "Villager" then
				positions[v] = v:GetPivot().Position
			end
		end
		task.wait(3)
		local moving = 0
		for rig, position in positions do
			if (rig:GetPivot().Position - position).Magnitude > 1 then
				moving += 1
			end
		end
		assert(moving == 8, "Expected eight moving villagers, got " .. moving)
		Plots.Release(player)
		assert(kingdom.Parent == nil, "Released kingdom retained")
		task.wait(1.3)
		character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 0)))
		assert(Plots.TryClaim(player, "Plot01"), "Reclaim failed")
		task.wait(0.3)
		local restored = Plots.GetKingdom(player) :: Model
		assert(not restored.PurchaseUnlocks:FindFirstChild("WoodenWalls"), "Wood restored alongside stone")
		assert(restored.PurchaseUnlocks.ProtectionDoor:GetAttribute("WardEnabled") == true, "Restored ward default")
		local restoredCount = 0
		for _, v in restored:GetChildren() do
			if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
				restoredCount += 1
			end
		end
		assert(restoredCount == 14, "Resident restoration failed")
		for _, v in restored:GetChildren() do
			if v:IsA("Model") and string.sub(v.Name, 1, 8) == "Villager" then
				local npcRoot = v:FindFirstChild("HumanoidRootPart")
				assert(
					npcRoot and npcRoot:FindFirstChild("Player" .. player.UserId),
					"Restored walkers must be nonblocking before data updates"
				)
			end
		end
		local target = require(Shared.RebirthConfig).Target(saved.Rebirths)
		assert(Data.Update(player, function(draft)
			draft.Gold = target
		end))
		assert(require(services.RebirthService).TryRebirth(player, saved.Rebirths), "Rebirth failed")
		task.wait(0.3)
		assert(restored.Parent == nil, "Old populated kingdom survived rebirth")
		local rebuilt = Plots.GetKingdom(player) :: Model
		assert(not rebuilt.PurchaseUnlocks:FindFirstChild("StoneWalls"), "Stone survived rebirth")
		for _, v in rebuilt:GetChildren() do
			assert(not (v:IsA("Model") and v:FindFirstChildOfClass("Humanoid")), "NPC survived rebirth")
		end
		print("[KingdomTycoon][Stronghold] All kingdom resident checks passed")
		print("[KingdomTycoon][Stronghold] Restoration and rebirth cleanup passed")
	end, debug.traceback)
	Plots.Release(player)
	assert(Data.Update(player, function(draft)
		draft.Gold = saved.Gold
		draft.LifetimeGold = saved.LifetimeGold
		draft.Rebirths = saved.Rebirths
		draft.PurchasedBuildings = table.clone(saved.PurchasedBuildings)
	end))
	player:SetAttribute("KingdomEntered", entered)
	root.Anchored = anchored
	character:PivotTo(original)
	assert(ok, reason)
end
return Tests
