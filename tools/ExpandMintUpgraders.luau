--!strict
-- Approved one-time Edit recipe: eight holographic Mint arches and collector clearance.
-- Never Rojo-map or execute during gameplay. Existing source geometry is archived intact.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local BACKUP_NAME = "MintUpgraderChainBackup_20261117"
local PRICES = { 250, 300, 400, 600, 1000, 1900, 3800, 7500 }
assert(not RunService:IsRunning(), "Stop Play before expanding Mint upgraders")
assert(game.PlaceId == 77311816657817, "Wrong Kingdom Tycoon place")
assert(ServerStorage:FindFirstChild(BACKUP_NAME) == nil, "Mint upgrader chain already installed")
local active = workspace:FindFirstChild("ActiveKingdoms")
assert(active == nil or #active:GetChildren() == 0, "Release active kingdoms before installation")
local original = ServerStorage:FindFirstChild("KingdomTemplate")
assert(original ~= nil and original:IsA("Model") and original.Archivable, "Archivable KingdomTemplate required")
local originalUnlocks = original:FindFirstChild("PurchaseUnlocks")
local originalPlates = original:FindFirstChild("PurchasePlates")
assert(originalUnlocks ~= nil and originalUnlocks:IsA("Folder"), "PurchaseUnlocks required")
assert(originalPlates ~= nil and originalPlates:IsA("Folder"), "PurchasePlates required")
local firstArch = originalUnlocks:FindFirstChild("RoyalMintUpgrader01")
local firstPlate = originalPlates:FindFirstChild("RoyalMintUpgrader01")
assert(firstArch ~= nil and firstArch:IsA("Model") and firstArch.Archivable, "Accepted first upgrader required")
assert(
	firstPlate ~= nil and firstPlate:IsA("BasePart") and firstPlate.Archivable,
	"Existing first upgrader plate required"
)
assert(firstArch:FindFirstChild("GoldHologram") == nil, "Inspect existing hologram before installing")
for index = 2, 8 do
	local id = string.format("RoyalMintUpgrader%02d", index)
	assert(
		originalUnlocks:FindFirstChild(id) == nil and originalPlates:FindFirstChild(id) == nil,
		"Existing chain asset: " .. id
	)
end
for _, item in original:GetDescendants() do
	assert(not item:IsA("LuaSourceContainer"), "KingdomTemplate must remain script-free")
end

local replacement = original:Clone()
local ok, reason = xpcall(function()
	local pivot = replacement:GetPivot()
	local unlocks = replacement:FindFirstChild("PurchaseUnlocks") :: Folder
	local plates = replacement:FindFirstChild("PurchasePlates") :: Folder
	local mint = unlocks:FindFirstChild("RoyalMint")
	assert(mint ~= nil and mint:IsA("Model"), "Installed Mint required")
	local conveyor = mint:FindFirstChild("Conveyor")
	local pit = mint:FindFirstChild("CollectionPit")
	local collect = mint:FindFirstChild("CollectPlate")
	local scenery = mint:FindFirstChild("Scenery")
	assert(conveyor ~= nil and conveyor:IsA("BasePart"), "Mint conveyor required")
	assert(pit ~= nil and pit:IsA("BasePart"), "Mint pit required")
	assert(collect ~= nil and collect:IsA("BasePart"), "Mint collector required")
	assert(scenery ~= nil and scenery:IsA("Model"), "Mint scenery required")
	assert(math.abs(conveyor.Size.Z - 96) < 0.01, "Unexpected edited conveyor length")
	assert(math.abs(pivot:PointToObjectSpace(conveyor.Position).Z + 16) < 0.01, "Unexpected conveyor position")
	assert(math.abs(pivot:PointToObjectSpace(pit.Position).Z - 35) < 0.01, "Unexpected pit position")
	assert(math.abs(pivot:PointToObjectSpace(collect.Position).Z - 46) < 0.01, "Unexpected collector position")
	-- Keep the upstream start at Z -64; add four studs downstream, leaving room after arch 8.
	conveyor.Size = Vector3.new(conveyor.Size.X, conveyor.Size.Y, 100)
	conveyor.CFrame += pivot:VectorToWorldSpace(Vector3.new(0, 0, 2))
	local extendedRails = 0
	local extendedFrames = 0
	local movedTroughs = 0
	for _, item in scenery:GetDescendants() do
		if item:IsA("BasePart") then
			if item.Name == "ConveyorFrame" or item.Name == "BeltRail" then
				assert(math.abs(item.Size.Z - 96) < 0.01, "Unexpected edited rail/frame length")
				item.Size = Vector3.new(item.Size.X, item.Size.Y, 100)
				item.CFrame += pivot:VectorToWorldSpace(Vector3.new(0, 0, 2))
				if item.Name == "BeltRail" then
					extendedRails += 1
				else
					extendedFrames += 1
				end
			elseif string.sub(item.Name, 1, 6) == "Trough" then
				item.CFrame += pivot:VectorToWorldSpace(Vector3.new(0, 0, 4))
				movedTroughs += 1
			end
		end
	end
	assert(extendedRails == 2 and extendedFrames == 2 and movedTroughs == 7, "Incomplete conveyor/trough extension")
	pit.CFrame += pivot:VectorToWorldSpace(Vector3.new(0, 0, 4))
	local collectionShift = pivot:VectorToWorldSpace(Vector3.new(0, 0, 3.5))
	collect.CFrame += collectionShift
	for _, item in collect:GetDescendants() do
		if item:IsA("BasePart") then
			item.CFrame += collectionShift
		end
	end
	mint:SetAttribute("BeltLength", 100)
	local sourceArch = unlocks:FindFirstChild("RoyalMintUpgrader01")
	local sourcePlate = plates:FindFirstChild("RoyalMintUpgrader01")
	assert(sourceArch ~= nil and sourceArch:IsA("Model"), "Cloned first arch missing")
	assert(sourcePlate ~= nil and sourcePlate:IsA("BasePart"), "Cloned first plate missing")
	local sourceZone = sourceArch:FindFirstChild("UpgradeZone")
	assert(sourceZone ~= nil and sourceZone:IsA("BasePart"), "First arch requires direct UpgradeZone")
	assert(
		(pivot:PointToObjectSpace(sourceZone.Position) - Vector3.new(-80, 5.5, -52)).Magnitude < 0.01,
		"First arch moved; inspect before installation"
	)
	local hologram = Instance.new("Part")
	hologram.Name = "GoldHologram"
	hologram.Size = Vector3.new(10.4, 6.3, 0.12)
	hologram.CFrame = pivot * CFrame.new(-80, 6.8, -52)
	hologram.Anchored = true
	hologram.Material = Enum.Material.Neon
	hologram.Color = Color3.fromRGB(255, 198, 65)
	hologram.Transparency = 0.65
	hologram.CanCollide = false
	hologram.CanTouch = false
	hologram.CanQuery = false
	hologram.CastShadow = false
	hologram.TopSurface = Enum.SurfaceType.Smooth
	hologram.BottomSurface = Enum.SurfaceType.Smooth
	hologram.Parent = sourceArch
	local sourceFrame = sourceArch:GetPivot()
	local presentation = require(game.ReplicatedStorage.Shared.PlatePresentation)
	local archCount = 0
	for index = 1, 8 do
		local id = string.format("RoyalMintUpgrader%02d", index)
		local z = -52 + 12 * (index - 1)
		local arch: Model
		local plate: BasePart
		if index == 1 then
			arch = sourceArch
			plate = sourcePlate
		else
			arch = sourceArch:Clone()
			arch.Name = id
			arch:PivotTo(sourceFrame + pivot:VectorToWorldSpace(Vector3.new(0, 0, 12 * (index - 1))))
			arch.Parent = unlocks
			plate = sourcePlate:Clone()
			plate.Name = id
			local shift = pivot:PointToWorldSpace(Vector3.new(-64, 0.8, z)) - plate.Position
			plate.CFrame += shift
			for _, item in plate:GetDescendants() do
				if item:IsA("BasePart") then
					item.CFrame += shift
				end
			end
			plate.Parent = plates
		end
		arch:SetAttribute("UpgraderId", id)
		local parts = 0
		for _, item in arch:GetDescendants() do
			assert(not item:IsA("LuaSourceContainer"), "Upgrader arch must be script-free")
			if item:IsA("BasePart") then
				parts += 1
				assert(item.Anchored and item:GetAttribute("MintCoinGuide") == nil, "Arches cannot alter coin guides")
				for _, x in { -0.5, 0.5 } do
					for _, y in { -0.5, 0.5 } do
						for _, dz in { -0.5, 0.5 } do
							local corner = pivot:PointToObjectSpace(
								item.CFrame:PointToWorldSpace(
									Vector3.new(x * item.Size.X, y * item.Size.Y, dz * item.Size.Z)
								)
							)
							assert(
								corner.X >= -88.01
									and corner.X <= -71.99
									and corner.Z >= z - 2.01
									and corner.Z <= z + 2.01,
								"Arch exceeds its station footprint"
							)
						end
					end
				end
			end
		end
		assert(parts <= 150, "Arch part budget exceeded")
		arch:SetAttribute("AuthoredPartCount", parts)
		local zone = arch:FindFirstChild("UpgradeZone")
		local laser = arch:FindFirstChild("GoldHologram")
		assert(
			zone ~= nil and zone:IsA("BasePart") and zone.CanQuery and not zone.CanCollide,
			"Missing valid UpgradeZone"
		)
		assert(
			(pivot:PointToObjectSpace(zone.Position) - Vector3.new(-80, 5.5, z)).Magnitude < 0.01,
			"Incorrect zone position"
		)
		assert(
			laser ~= nil
				and laser:IsA("BasePart")
				and not laser.CanCollide
				and not laser.CanTouch
				and not laser.CanQuery,
			"Hologram must be visual-only"
		)
		local label = plate:FindFirstChild("PurchaseLabel", true)
		assert(label ~= nil and label:IsA("TextLabel"), "PurchaseLabel required")
		presentation.Style(plate)
		presentation.SetAmount(label, "Upgrader " .. tostring(index), PRICES[index])
		plate.Color = Color3.fromRGB(255, 45, 45)
		archCount += 1
		task.wait()
	end
	-- Check shifted geometry/collector rims remain inside the existing paved yard.
	for _, item in mint:GetDescendants() do
		if item:IsA("BasePart") then
			assert(item.Anchored, "Mint template must remain anchored")
			for _, x in { -0.5, 0.5 } do
				for _, y in { -0.5, 0.5 } do
					for _, z in { -0.5, 0.5 } do
						local corner = pivot:PointToObjectSpace(
							item.CFrame:PointToWorldSpace(
								Vector3.new(x * item.Size.X, y * item.Size.Y, z * item.Size.Z)
							)
						)
						assert(
							corner.X >= -100.01 and corner.X <= -11.99 and corner.Z >= -76.01 and corner.Z <= 52.01,
							"Extended Mint exceeds yard bounds"
						)
					end
				end
			end
		end
	end
	assert(replacement:GetPivot() == original:GetPivot(), "Kingdom pivot changed")
	print(
		string.format("Mint upgrader chain asset checks passed (%d arches, 100-stud belt, gold holograms)", archCount)
	)
end, debug.traceback)
if not ok then
	replacement:Destroy()
	error(reason)
end
local backup = Instance.new("Folder")
backup.Name = BACKUP_NAME
backup.Parent = ServerStorage
original.Parent = backup
replacement.Parent = ServerStorage
print("Installed eight Mint upgraders; original template retained in ServerStorage." .. BACKUP_NAME)
print("Coin template, droppers, paving and walls unchanged. Verify transit/stacking, then save the place.")
