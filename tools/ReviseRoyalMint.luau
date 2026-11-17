--!strict
-- Approved one-time Royal Mint revision. Never Rojo-map or execute during gameplay.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local BACKUP_NAME = "RoyalMintRevisionBackup_20261117"
local PRICES = { 60, 70, 90, 110, 130, 150, 170, 190 }
assert(not RunService:IsRunning(), "Stop Play before revising the Royal Mint")
assert(game.PlaceId == 77311816657817, "Wrong Kingdom Tycoon place")
assert(ServerStorage:FindFirstChild(BACKUP_NAME) == nil, "Mint revision already installed; use documented rollback")
local originalCoin = ServerStorage:FindFirstChild("RoyalMintCoin")
assert(
	originalCoin ~= nil and originalCoin:IsA("BasePart") and originalCoin.Archivable,
	"Existing coin template required"
)
local active = workspace:FindFirstChild("ActiveKingdoms")
assert(active == nil or #active:GetChildren() == 0, "Release active kingdoms before installation")
local original = ServerStorage:FindFirstChild("KingdomTemplate")
assert(original ~= nil and original:IsA("Model") and original.Archivable, "Missing archivable KingdomTemplate")
local oldPlates = original:FindFirstChild("PurchasePlates")
local oldUnlocks = original:FindFirstChild("PurchaseUnlocks")
assert(oldPlates ~= nil and oldPlates:IsA("Folder"), "Existing purchase plates required")
assert(oldUnlocks ~= nil and oldUnlocks:IsA("Folder"), "Existing wall unlock required")
assert(oldUnlocks:FindFirstChild("WoodenWalls") ~= nil, "Install wooden walls first")
assert(oldUnlocks:FindFirstChild("RoyalMint") ~= nil, "Install the initial Mint before this revision")
local sourcePlate = oldPlates:FindFirstChild("FarmDropper04")
assert(sourcePlate ~= nil and sourcePlate:IsA("BasePart") and sourcePlate.Archivable, "Missing styled source plate")
for index = 1, 8 do
	local id = if index == 1 then "RoyalMint" else string.format("RoyalMintDropper%02d", index)
	assert(oldPlates:FindFirstChild(id) ~= nil, "Missing existing purchase plate: " .. id)
end
for _, item in original:GetDescendants() do
	assert(not item:IsA("LuaSourceContainer"), "KingdomTemplate must be script-free")
end

local replacement = original:Clone()
local coin = originalCoin:Clone()
coin.Size = Vector3.new(0.5, 1.6, 1.6)
coin.CFrame = CFrame.Angles(0, 0, math.pi / 2)
coin.Anchored = true
coin.CanTouch = false
coin.CustomPhysicalProperties = PhysicalProperties.new(1, 0.35, 0, 100, 100)
local ok, reason = xpcall(function()
	local pivot = replacement:GetPivot()
	local plates = replacement:FindFirstChild("PurchasePlates") :: Folder
	local unlocks = replacement:FindFirstChild("PurchaseUnlocks") :: Folder
	-- Only remove newly cloned revision targets; the original is archived intact.
	local previousMint = unlocks:FindFirstChild("RoyalMint")
	assert(previousMint ~= nil and previousMint:IsA("Model"), "Existing Mint must be a Model")
	previousMint:Destroy()
	for index = 1, 8 do
		local id = if index == 1 then "RoyalMint" else string.format("RoyalMintDropper%02d", index)
		local previousPlate = plates:FindFirstChild(id)
		assert(previousPlate ~= nil, "Missing cloned Mint purchase plate")
		previousPlate:Destroy()
	end
	local mint = Instance.new("Model")
	mint.Name = "RoyalMint"
	mint.Parent = unlocks
	local producers = Instance.new("Folder")
	producers.Name = "Producers"
	producers.Parent = mint
	local stone = Color3.fromRGB(158, 149, 136)
	local paleStone = Color3.fromRGB(180, 167, 147)
	local wood = Color3.fromRGB(105, 65, 37)
	local darkWood = Color3.fromRGB(65, 42, 29)
	local iron = Color3.fromRGB(53, 57, 67)
	local gold = Color3.fromRGB(223, 165, 44)
	local blue = Color3.fromRGB(40, 65, 108)
	local count = 0
	local function part(
		parent: Instance,
		name: string,
		size: Vector3,
		frame: CFrame,
		color: Color3,
		material: Enum.Material?
	): Part
		local item = Instance.new("Part")
		item.Name = name
		item.Size = size
		item.CFrame = pivot * frame
		item.Color = color
		item.Material = material or Enum.Material.SmoothPlastic
		item.Anchored = true
		item.CanTouch = false
		item.TopSurface = Enum.SurfaceType.Smooth
		item.BottomSurface = Enum.SurfaceType.Smooth
		item.Parent = parent
		count += 1
		return item
	end
	local function cylinder(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3): Part
		local item = part(parent, name, size, frame, color, Enum.Material.Metal)
		item.Shape = Enum.PartType.Cylinder
		return item
	end
	local scenery = Instance.new("Model")
	scenery.Name = "Scenery"
	scenery.Parent = mint
	-- Separate shallow pavers keep the low-poly yard readable without texture assets.
	for column = 0, 10 do
		for row = 0, 15 do
			local shade = if (column + row) % 3 == 0 then paleStone else stone
			part(
				scenery,
				"Paver",
				Vector3.new(7.94, 0.4, 7.94),
				CFrame.new(-96 + 8 * column, 0.2, -72 + 8 * row),
				shade,
				Enum.Material.Slate
			)
		end
		task.wait()
	end
	for _, x in { -99.5, -12.5 } do
		part(scenery, "YardEdging", Vector3.new(1, 1, 128), CFrame.new(x, 0.5, -12), paleStone, Enum.Material.Slate)
	end
	-- Open the front edge for walking directly onto the collector and service aisle.
	part(scenery, "RearEdging", Vector3.new(86, 1, 1), CFrame.new(-56, 0.5, -75.5), paleStone, Enum.Material.Slate)
	local conveyor =
		part(mint, "Conveyor", Vector3.new(8, 2, 96), CFrame.new(-80, 2.5, -16) * CFrame.Angles(0, math.pi, 0), iron)
	conveyor.AssemblyLinearVelocity = Vector3.zero
	conveyor:SetAttribute("MintCoinGuide", true)
	for _, x in { -84.5, -75.5 } do
		part(scenery, "ConveyorFrame", Vector3.new(1, 1.5, 96), CFrame.new(x, 2.6, -16), wood, Enum.Material.Wood)
		local rail =
			part(scenery, "BeltRail", Vector3.new(0.6, 1.8, 96), CFrame.new(x, 4.4, -16), gold, Enum.Material.Metal)
		rail:SetAttribute("MintCoinGuide", true)
		for z = -60, 24, 12 do
			part(scenery, "BeltLeg", Vector3.new(1.4, 2.5, 1.4), CFrame.new(x, 1.65, z), darkWood, Enum.Material.Wood)
			cylinder(
				scenery,
				"FrameBolt",
				Vector3.new(0.12, 0.45, 0.45),
				CFrame.new(x + (if x < -80 then -0.56 else 0.56), 2.8, z),
				gold
			)
		end
	end
	local pit = part(mint, "CollectionPit", Vector3.new(9, 4, 6), CFrame.new(-80, 3.2, 35), gold)
	pit.Transparency = 1
	pit.CanCollide = false
	pit.CanQuery = true
	for _, x in { -85.25, -74.75 } do
		part(scenery, "TroughSide", Vector3.new(1, 3.4, 7.5), CFrame.new(x, 2.1, 35), stone, Enum.Material.Slate)
		part(scenery, "TroughTrim", Vector3.new(1.2, 0.45, 7.7), CFrame.new(x, 3.9, 35), gold, Enum.Material.Metal)
	end
	part(scenery, "TroughFloor", Vector3.new(10, 0.5, 7), CFrame.new(-80, 1, 35), iron)
	part(scenery, "TroughFront", Vector3.new(11.5, 3.5, 1), CFrame.new(-80, 2.1, 39), stone, Enum.Material.Slate)
	part(scenery, "TroughFrontTrim", Vector3.new(11.7, 0.45, 1.2), CFrame.new(-80, 3.9, 39), gold, Enum.Material.Metal)

	-- Eight complete, separately owned presses; runtime hides all unowned models.
	for index = 1, 8 do
		local z = -58 + 12 * (index - 1)
		local press = Instance.new("Model")
		press.Name = string.format("Dropper%02d", index)
		press.Parent = producers
		-- Solid blue-black housing, brass corner armour and a broad gold hopper.
		part(press, "MachinePlinth", Vector3.new(16, 0.8, 10), CFrame.new(-89, 0.8, z), stone, Enum.Material.Slate)
		part(press, "IronBed", Vector3.new(12, 1, 9), CFrame.new(-89, 1.6, z), iron, Enum.Material.Metal)
		part(press, "SolidPressHousing", Vector3.new(10, 7.4, 8.6), CFrame.new(-89, 5.1, z), iron, Enum.Material.Metal)
		part(
			press,
			"RoyalEnamelFace",
			Vector3.new(0.25, 5.4, 6.4),
			CFrame.new(-83.85, 5.1, z),
			blue,
			Enum.Material.Metal
		)
		part(
			press,
			"RearEnamelPanel",
			Vector3.new(0.25, 4.8, 5.8),
			CFrame.new(-94.15, 5.1, z),
			blue,
			Enum.Material.Metal
		)
		for _, dx in { -4.8, 4.8 } do
			for _, dz in { -4.1, 4.1 } do
				part(
					press,
					"GoldCornerArmour",
					Vector3.new(0.6, 7.6, 0.6),
					CFrame.new(-89 + dx, 5.1, z + dz),
					gold,
					Enum.Material.Metal
				)
			end
		end
		for _, y in { 1.9, 8.5 } do
			part(
				press,
				"HousingGoldBand",
				Vector3.new(10.5, 0.55, 9.1),
				CFrame.new(-89, y, z),
				gold,
				Enum.Material.Metal
			)
		end
		part(press, "HopperNeck", Vector3.new(5.8, 0.8, 5.8), CFrame.new(-89, 9, z), gold, Enum.Material.Metal)
		part(press, "HopperShoulder", Vector3.new(7.5, 0.65, 7.5), CFrame.new(-89, 9.65, z), gold, Enum.Material.Metal)
		part(press, "HeavyHopperRim", Vector3.new(10, 0.9, 10), CFrame.new(-89, 10.4, z), gold, Enum.Material.Metal)
		part(press, "HopperInterior", Vector3.new(8.1, 0.15, 8.1), CFrame.new(-89, 10.9, z), darkWood)
		for _, dz in { -4.7, 4.7 } do
			part(press, "HopperLip", Vector3.new(10, 0.8, 0.55), CFrame.new(-89, 11, z + dz), gold, Enum.Material.Metal)
		end
		for _, dx in { -4.7, 4.7 } do
			part(
				press,
				"HopperLip",
				Vector3.new(0.55, 0.8, 8.8),
				CFrame.new(-89 + dx, 11, z),
				gold,
				Enum.Material.Metal
			)
		end
		-- Large stamped crown/coin badge on the front face, above the outlet.
		cylinder(press, "RoyalCoinBadge", Vector3.new(0.3, 3.5, 3.5), CFrame.new(-83.55, 6.9, z), gold)
		cylinder(press, "BadgeInset", Vector3.new(0.35, 2.8, 2.8), CFrame.new(-83.35, 6.9, z), blue)
		part(press, "CrownBand", Vector3.new(0.4, 0.35, 2), CFrame.new(-83.1, 6.5, z), gold, Enum.Material.Metal)
		for crownIndex, dz in { -0.75, 0, 0.75 } do
			local height = if crownIndex == 2 then 1.3 else 0.95
			part(
				press,
				"CrownPoint",
				Vector3.new(0.4, height, 0.4),
				CFrame.new(-83.1, 6.6 + height / 2, z + dz),
				gold,
				Enum.Material.Metal
			)
		end
		-- Recessed discharge opening and brass elbow place coins directly above belt.
		part(press, "OutletShadow", Vector3.new(0.4, 2.2, 3.4), CFrame.new(-83.65, 3.7, z), Color3.fromRGB(24, 25, 30))
		part(press, "OutletCollar", Vector3.new(1.1, 1.7, 2.8), CFrame.new(-83.2, 4.6, z), gold, Enum.Material.Metal)
		part(press, "DischargeNozzle", Vector3.new(3.4, 1.1, 2.3), CFrame.new(-81.5, 5.3, z), iron, Enum.Material.Metal)
		cylinder(
			press,
			"NozzleMouth",
			Vector3.new(0.6, 2.7, 2.7),
			CFrame.new(-80, 4.95, z) * CFrame.Angles(0, 0, math.pi / 2),
			gold
		)
		cylinder(
			press,
			"NozzleInterior",
			Vector3.new(0.15, 1.9, 1.9),
			CFrame.new(-80, 4.59, z) * CFrame.Angles(0, 0, math.pi / 2),
			iron
		)
		cylinder(press, "Flywheel", Vector3.new(0.8, 5.6, 5.6), CFrame.new(-95.2, 4.5, z), gold)
		cylinder(press, "WheelHub", Vector3.new(1.1, 2.2, 2.2), CFrame.new(-95.7, 4.5, z), iron)
		for angle = 0, 5 do
			part(
				press,
				"WheelSpoke",
				Vector3.new(0.85, 4.8, 0.35),
				CFrame.new(-95.7, 4.5, z) * CFrame.Angles(angle * math.pi / 3, 0, 0),
				iron,
				Enum.Material.Metal
			)
		end
		for _, y in { 2.6, 7.6 } do
			for _, dz in { -3.1, 3.1 } do
				cylinder(press, "ArmourRivet", Vector3.new(0.2, 0.45, 0.45), CFrame.new(-83.7, y, z + dz), gold)
			end
		end
		local drop = part(
			press,
			"DropPoint",
			Vector3.new(0.2, 0.2, 0.2),
			CFrame.new(-80, 4.1, z) * CFrame.Angles(0, 0, math.pi / 2),
			gold
		)
		drop.Transparency = 1
		drop.CanCollide = false
		drop.CanQuery = false
		press.PrimaryPart = drop
		task.wait()
	end
	local function lantern(x: number, z: number): ()
		part(scenery, "LanternBase", Vector3.new(2.2, 1.2, 2.2), CFrame.new(x, 0.8, z), stone, Enum.Material.Slate)
		part(scenery, "LanternPost", Vector3.new(0.8, 7, 0.8), CFrame.new(x, 4.5, z), wood, Enum.Material.Wood)
		part(scenery, "LanternCap", Vector3.new(1.7, 0.4, 1.7), CFrame.new(x, 8.2, z), gold, Enum.Material.Metal)
		local glass = part(
			scenery,
			"LanternGlow",
			Vector3.new(1.2, 1.5, 1.2),
			CFrame.new(x, 7.15, z),
			Color3.fromRGB(255, 196, 87),
			Enum.Material.Neon
		)
		glass.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = glass.Color
		light.Brightness = 0.5
		light.Range = 10
		light.Shadows = false
		light.Parent = glass
	end
	for _, x in { -98, -14 } do
		for _, z in { -72, -32, 8, 48 } do
			lantern(x, z)
		end
	end
	-- Freestanding blue-and-gold crown plaque; nothing covers the production yard.
	for _, x in { -97, -87 } do
		part(scenery, "SignPost", Vector3.new(1, 8, 1), CFrame.new(x, 4.4, 47), wood, Enum.Material.Wood)
		part(scenery, "SignFinial", Vector3.new(1.5, 0.7, 1.5), CFrame.new(x, 8.6, 47), gold, Enum.Material.Metal)
	end
	part(scenery, "SignBacking", Vector3.new(10, 6, 0.7), CFrame.new(-92, 5, 47), wood, Enum.Material.Wood)
	part(scenery, "RoyalPlaque", Vector3.new(8.5, 4.8, 0.2), CFrame.new(-92, 5, 47.5), blue)
	for _, x in { -96.4, -87.6 } do
		part(scenery, "SignGoldBorder", Vector3.new(0.25, 5, 0.35), CFrame.new(x, 5, 47.6), gold, Enum.Material.Metal)
	end
	for _, y in { 2.5, 7.5 } do
		part(scenery, "SignGoldBorder", Vector3.new(9, 0.25, 0.35), CFrame.new(-92, y, 47.6), gold, Enum.Material.Metal)
	end
	part(scenery, "CrownBand", Vector3.new(4.5, 0.6, 0.4), CFrame.new(-92, 4.2, 47.8), gold, Enum.Material.Metal)
	for index, x in { -93.7, -92, -90.3 } do
		local height = if index == 2 then 2 else 1.4
		part(
			scenery,
			"CrownPoint",
			Vector3.new(0.65, height, 0.4),
			CFrame.new(x, 4.4 + height / 2, 47.8),
			gold,
			Enum.Material.Metal
		)
		local gem = part(
			scenery,
			"CrownTip",
			Vector3.new(0.8, 0.8, 0.5),
			CFrame.new(x, 4.6 + height, 47.8),
			gold,
			Enum.Material.Metal
		)
		gem.Shape = Enum.PartType.Ball
	end
	local presentation = require(game.ReplicatedStorage.Shared.PlatePresentation)
	local function makePlate(
		name: string,
		position: Vector3,
		labelName: string,
		title: string,
		amount: number
	): BasePart
		local plate = sourcePlate:Clone()
		plate.Name = name
		local shift = pivot:PointToWorldSpace(position) - plate.Position
		plate.CFrame += shift
		for _, item in plate:GetDescendants() do
			if item:IsA("BasePart") then
				item.CFrame += shift
			end
		end
		local label = plate:FindFirstChild("PurchaseLabel", true)
		assert(label ~= nil and label:IsA("TextLabel"), "Source plate requires PurchaseLabel")
		label.Name = labelName
		presentation.Style(plate)
		presentation.SetAmount(label, title, amount)
		plate.Color = Color3.fromRGB(255, 45, 45)
		return plate
	end
	for index = 1, 8 do
		local id = if index == 1 then "RoyalMint" else string.format("RoyalMintDropper%02d", index)
		local position = if index == 1 then Vector3.new(-28, 0.4, 60) else Vector3.new(-64, 0.8, -58 + 12 * (index - 1))
		local title = if index == 1 then "Royal Mint" else "Mint " .. tostring(index)
		makePlate(id, position, "PurchaseLabel", title, PRICES[index]).Parent = plates
	end
	local collect = makePlate("CollectPlate", Vector3.new(-80, 0.8, 46), "EarningsLabel", "Collect Total", 0)
	collect.Parent = mint
	for _, item in mint:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Mint must be script-free")
		if item:IsA("BasePart") then
			assert(item.Anchored, "Mint template part is not anchored")
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
							"Mint exceeds its reserved yard"
						)
					end
				end
			end
		end
	end
	assert(#producers:GetChildren() == 8, "Incomplete Mint producer set")
	assert(conveyor:GetAttribute("MintCoinGuide") == true, "Conveyor must guide Mint coins")
	local guides = 0
	for _, item in mint:GetDescendants() do
		if item:IsA("BasePart") and item:GetAttribute("MintCoinGuide") == true then
			assert(item.CanCollide, "Mint coin guide must collide")
			guides += 1
		end
	end
	assert(guides == 3, "Only the conveyor and paired tall rails should guide coins")
	assert(count < 1000, "Mint static part budget exceeded")
	assert(replacement:GetPivot() == original:GetPivot(), "Kingdom pivot changed")
	mint:SetAttribute("AuthoredPartCount", count)
	mint:SetAttribute("YardSize", Vector3.new(88, 0, 128))
	mint:SetAttribute("BeltLength", 96)
	mint:SetAttribute("Revision", "WideYardHousedPresses")
	print(
		string.format("Royal Mint revision asset checks passed (%d authored parts, eight presses, 96-stud belt)", count)
	)
end, debug.traceback)
if not ok then
	replacement:Destroy()
	coin:Destroy()
	error(reason)
end
-- Commit the detached construction only after all checks pass. Preserve original intact.
local backup = Instance.new("Folder")
backup.Name = BACKUP_NAME
backup.Parent = ServerStorage
original.Parent = backup
originalCoin.Parent = backup
replacement.Parent = ServerStorage
coin.Parent = ServerStorage
print("Revised RoyalMint; original template and coin retained in ServerStorage." .. BACKUP_NAME)
print("Save the Studio place. Runtime source and the Mock acceptance suites must be synced separately.")
