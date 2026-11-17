--!strict
-- Approved one-time Edit recipe. Never Rojo-map or execute during gameplay.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local BACKUP_NAME = "RoyalMintBackup_20261117"
local PRICES = { 60, 70, 90, 110, 130, 150, 170, 190 }
assert(not RunService:IsRunning(), "Stop Play before installing the Royal Mint")
assert(game.PlaceId == 77311816657817, "Wrong Kingdom Tycoon place")
assert(ServerStorage:FindFirstChild(BACKUP_NAME) == nil, "Mint already installed; use documented rollback")
assert(ServerStorage:FindFirstChild("RoyalMintCoin") == nil, "Coin template already exists; inspect before merging")
local active = workspace:FindFirstChild("ActiveKingdoms")
assert(active == nil or #active:GetChildren() == 0, "Release active kingdoms before installation")
local original = ServerStorage:FindFirstChild("KingdomTemplate")
assert(original ~= nil and original:IsA("Model") and original.Archivable, "Missing archivable KingdomTemplate")
local oldPlates = original:FindFirstChild("PurchasePlates")
local oldUnlocks = original:FindFirstChild("PurchaseUnlocks")
assert(oldPlates ~= nil and oldPlates:IsA("Folder"), "Existing purchase plates required")
assert(oldUnlocks ~= nil and oldUnlocks:IsA("Folder"), "Existing wall unlock required")
assert(oldUnlocks:FindFirstChild("WoodenWalls") ~= nil, "Install wooden walls first")
assert(oldUnlocks:FindFirstChild("RoyalMint") == nil, "Royal Mint already exists")
local sourcePlate = oldPlates:FindFirstChild("FarmDropper04")
assert(sourcePlate ~= nil and sourcePlate:IsA("BasePart") and sourcePlate.Archivable, "Missing styled source plate")
for index = 1, 8 do
	local id = if index == 1 then "RoyalMint" else string.format("RoyalMintDropper%02d", index)
	assert(oldPlates:FindFirstChild(id) == nil, "Conflicting purchase plate: " .. id)
end
for _, item in original:GetDescendants() do
	assert(not item:IsA("LuaSourceContainer"), "KingdomTemplate must be script-free")
end

local replacement = original:Clone()
local coin = Instance.new("Part")
coin.Name = "RoyalMintCoin"
coin.Shape = Enum.PartType.Cylinder
coin.Size = Vector3.new(0.3, 1.6, 1.6)
coin.CFrame = CFrame.Angles(0, 0, math.pi / 2)
coin.Color = Color3.fromRGB(245, 185, 46)
coin.Material = Enum.Material.Metal
coin.Anchored = true -- Runtime clones become movable and server-owned.
coin.CanTouch = false
coin.TopSurface = Enum.SurfaceType.Smooth
coin.BottomSurface = Enum.SurfaceType.Smooth
coin.CustomPhysicalProperties = PhysicalProperties.new(1, 0.35, 0, 100, 100)
local ok, reason = xpcall(function()
	local pivot = replacement:GetPivot()
	local plates = replacement:FindFirstChild("PurchasePlates") :: Folder
	local unlocks = replacement:FindFirstChild("PurchaseUnlocks") :: Folder
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
	for column = 0, 7 do
		for row = 0, 15 do
			local shade = if (column + row) % 3 == 0 then paleStone else stone
			part(
				scenery,
				"Paver",
				Vector3.new(5.94, 0.4, 7.94),
				CFrame.new(-85 + 6 * column, 0.2, -72 + 8 * row),
				shade,
				Enum.Material.Slate
			)
		end
		task.wait()
	end
	for _, x in { -87.5, -40.5 } do
		part(scenery, "YardEdging", Vector3.new(1, 1, 128), CFrame.new(x, 0.5, -12), paleStone, Enum.Material.Slate)
	end
	-- Open the front edge for walking directly onto the collector and service aisle.
	part(scenery, "RearEdging", Vector3.new(46, 1, 1), CFrame.new(-64, 0.5, -75.5), paleStone, Enum.Material.Slate)
	local conveyor =
		part(mint, "Conveyor", Vector3.new(6, 0.8, 96), CFrame.new(-64, 3.1, -16) * CFrame.Angles(0, math.pi, 0), iron)
	conveyor.AssemblyLinearVelocity = Vector3.zero
	for _, x in { -67.5, -60.5 } do
		part(scenery, "ConveyorFrame", Vector3.new(1, 1.5, 96), CFrame.new(x, 2.6, -16), wood, Enum.Material.Wood)
		part(scenery, "BeltRail", Vector3.new(0.35, 0.7, 96), CFrame.new(x, 3.65, -16), gold, Enum.Material.Metal)
		for z = -60, 24, 12 do
			part(scenery, "BeltLeg", Vector3.new(1.4, 2.5, 1.4), CFrame.new(x, 1.65, z), darkWood, Enum.Material.Wood)
			cylinder(
				scenery,
				"FrameBolt",
				Vector3.new(0.12, 0.45, 0.45),
				CFrame.new(x + (if x < -64 then -0.56 else 0.56), 2.8, z),
				gold
			)
		end
	end
	local pit = part(mint, "CollectionPit", Vector3.new(7, 4, 6), CFrame.new(-64, 3.2, 35), gold)
	pit.Transparency = 1
	pit.CanCollide = false
	pit.CanQuery = true
	for _, x in { -68.25, -59.75 } do
		part(scenery, "TroughSide", Vector3.new(1, 3.4, 7.5), CFrame.new(x, 2.1, 35), stone, Enum.Material.Slate)
		part(scenery, "TroughTrim", Vector3.new(1.2, 0.45, 7.7), CFrame.new(x, 3.9, 35), gold, Enum.Material.Metal)
	end
	part(scenery, "TroughFloor", Vector3.new(8, 0.5, 7), CFrame.new(-64, 1, 35), iron)
	part(scenery, "TroughFront", Vector3.new(9.5, 3.5, 1), CFrame.new(-64, 2.1, 39), stone, Enum.Material.Slate)
	part(scenery, "TroughFrontTrim", Vector3.new(9.7, 0.45, 1.2), CFrame.new(-64, 3.9, 39), gold, Enum.Material.Metal)

	-- Eight complete, separately owned presses; runtime hides all unowned models.
	for index = 1, 8 do
		local z = -58 + 12 * (index - 1)
		local press = Instance.new("Model")
		press.Name = string.format("Dropper%02d", index)
		press.Parent = producers
		part(press, "MachinePlinth", Vector3.new(14, 0.8, 8), CFrame.new(-73, 0.8, z), stone, Enum.Material.Slate)
		part(press, "IronBed", Vector3.new(10.5, 1, 6), CFrame.new(-73, 1.7, z), iron, Enum.Material.Metal)
		for _, dx in { -4, 4 } do
			part(press, "PressColumn", Vector3.new(1.3, 9, 1.5), CFrame.new(-73, 6, z + dx), iron, Enum.Material.Metal)
			part(press, "ColumnFoot", Vector3.new(2, 1, 2.2), CFrame.new(-73, 2.2, z + dx), stone, Enum.Material.Slate)
			cylinder(press, "ColumnBolt", Vector3.new(0.2, 0.75, 0.75), CFrame.new(-72.25, 8.5, z + dx), gold)
		end
		part(press, "Crosshead", Vector3.new(2.1, 2, 10.5), CFrame.new(-73, 10, z), iron, Enum.Material.Metal)
		cylinder(
			press,
			"HydraulicRam",
			Vector3.new(5.3, 1.8, 1.8),
			CFrame.new(-73, 7.2, z) * CFrame.Angles(0, 0, math.pi / 2),
			gold
		)
		cylinder(
			press,
			"PressHead",
			Vector3.new(0.8, 4.6, 4.6),
			CFrame.new(-73, 4.7, z) * CFrame.Angles(0, 0, math.pi / 2),
			gold
		)
		cylinder(
			press,
			"RamCap",
			Vector3.new(1.2, 3.8, 3.8),
			CFrame.new(-73, 11.6, z) * CFrame.Angles(0, 0, math.pi / 2),
			gold
		)
		cylinder(
			press,
			"Die",
			Vector3.new(0.5, 3.8, 3.8),
			CFrame.new(-73, 2.45, z) * CFrame.Angles(0, 0, math.pi / 2),
			gold
		)
		-- A shallow output chute ends above the belt center, clear of its rail.
		part(
			press,
			"CoinChute",
			Vector3.new(8, 0.4, 2.8),
			CFrame.new(-68.5, 5.4, z) * CFrame.Angles(0, 0, -0.14),
			wood,
			Enum.Material.Wood
		)
		for _, dz in { -1.6, 1.6 } do
			part(
				press,
				"ChuteLip",
				Vector3.new(8, 0.5, 0.3),
				CFrame.new(-68.5, 5.8, z + dz) * CFrame.Angles(0, 0, -0.14),
				gold,
				Enum.Material.Metal
			)
		end
		cylinder(press, "Flywheel", Vector3.new(0.65, 5, 5), CFrame.new(-78.5, 4.5, z), gold)
		cylinder(press, "WheelHub", Vector3.new(0.9, 2, 2), CFrame.new(-79, 4.5, z), iron)
		for angle = 0, 5 do
			part(
				press,
				"WheelSpoke",
				Vector3.new(0.7, 4.3, 0.3),
				CFrame.new(-78.9, 4.5, z) * CFrame.Angles(angle * math.pi / 3, 0, 0),
				iron,
				Enum.Material.Metal
			)
		end
		local drop =
			part(press, "DropPoint", Vector3.one, CFrame.new(-64, 6.6, z) * CFrame.Angles(0, 0, math.pi / 2), gold)
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
	for _, x in { -86, -42 } do
		for _, z in { -72, -32, 8, 48 } do
			lantern(x, z)
		end
	end
	-- Freestanding blue-and-gold crown plaque; nothing covers the production yard.
	for _, x in { -82, -72 } do
		part(scenery, "SignPost", Vector3.new(1, 8, 1), CFrame.new(x, 4.4, 47), wood, Enum.Material.Wood)
		part(scenery, "SignFinial", Vector3.new(1.5, 0.7, 1.5), CFrame.new(x, 8.6, 47), gold, Enum.Material.Metal)
	end
	part(scenery, "SignBacking", Vector3.new(10, 6, 0.7), CFrame.new(-77, 5, 47), wood, Enum.Material.Wood)
	part(scenery, "RoyalPlaque", Vector3.new(8.5, 4.8, 0.2), CFrame.new(-77, 5, 47.5), blue)
	for _, x in { -81.4, -72.6 } do
		part(scenery, "SignGoldBorder", Vector3.new(0.25, 5, 0.35), CFrame.new(x, 5, 47.6), gold, Enum.Material.Metal)
	end
	for _, y in { 2.5, 7.5 } do
		part(scenery, "SignGoldBorder", Vector3.new(9, 0.25, 0.35), CFrame.new(-77, y, 47.6), gold, Enum.Material.Metal)
	end
	part(scenery, "CrownBand", Vector3.new(4.5, 0.6, 0.4), CFrame.new(-77, 4.2, 47.8), gold, Enum.Material.Metal)
	for index, x in { -78.7, -77, -75.3 } do
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
		local position = if index == 1 then Vector3.new(-28, 0.4, 60) else Vector3.new(-46, 0.8, -58 + 12 * (index - 1))
		local title = if index == 1 then "Royal Mint" else "Mint " .. tostring(index)
		makePlate(id, position, "PurchaseLabel", title, PRICES[index]).Parent = plates
	end
	local collect = makePlate("CollectPlate", Vector3.new(-64, 0.8, 46), "EarningsLabel", "Collect Total", 0)
	collect.Parent = mint
	for _, item in mint:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Mint must be script-free")
		if item:IsA("BasePart") then
			assert(item.Anchored, "Mint template part is not anchored")
			local localPosition = pivot:PointToObjectSpace(item.Position)
			assert(
				localPosition.X > -90 and localPosition.X < -38 and localPosition.Z >= -77 and localPosition.Z < 54,
				"Mint exceeds its reserved yard"
			)
		end
	end
	assert(#producers:GetChildren() == 8, "Incomplete Mint producer set")
	assert(count < 1000, "Mint static part budget exceeded")
	assert(replacement:GetPivot() == original:GetPivot(), "Kingdom pivot changed")
	mint:SetAttribute("AuthoredPartCount", count)
	mint:SetAttribute("YardSize", Vector3.new(48, 0, 128))
	mint:SetAttribute("BeltLength", 96)
	print(string.format("Royal Mint asset checks passed (%d authored parts, eight presses, 96-stud belt)", count))
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
replacement.Parent = ServerStorage
coin.Parent = ServerStorage
print("Installed RoyalMint; original template retained in ServerStorage." .. BACKUP_NAME)
print("Save the Studio place. Runtime source and the Mock acceptance suites must be synced separately.")
