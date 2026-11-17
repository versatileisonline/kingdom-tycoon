--!strict
-- Approved one-time Edit-mode prototype. Never Rojo-map or execute during gameplay.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local BACKUP_NAME = "MintUpgraderBackup_20261117"
local PURCHASE_ID = "RoyalMintUpgrader01"
assert(not RunService:IsRunning(), "Stop Play before installing the Mint upgrader")
assert(game.PlaceId == 77311816657817, "Wrong Kingdom Tycoon place")
assert(ServerStorage:FindFirstChild(BACKUP_NAME) == nil, "Mint upgrader already installed; inspect its backup")
local active = workspace:FindFirstChild("ActiveKingdoms")
assert(active == nil or #active:GetChildren() == 0, "Release active kingdoms before installation")
local original = ServerStorage:FindFirstChild("KingdomTemplate")
assert(original ~= nil and original:IsA("Model") and original.Archivable, "Archivable KingdomTemplate required")
local originalUnlocks = original:FindFirstChild("PurchaseUnlocks")
local originalPlates = original:FindFirstChild("PurchasePlates")
assert(originalUnlocks ~= nil and originalUnlocks:IsA("Folder"), "PurchaseUnlocks required")
assert(originalPlates ~= nil and originalPlates:IsA("Folder"), "PurchasePlates required")
local mint = originalUnlocks:FindFirstChild("RoyalMint")
assert(mint ~= nil and mint:IsA("Model"), "Installed Royal Mint required")
assert(mint:GetAttribute("Revision") == "RaisedHousedPresses", "Install the raised housed-press revision first")
assert(originalUnlocks:FindFirstChild(PURCHASE_ID) == nil, "Upgrader model already exists")
assert(originalPlates:FindFirstChild(PURCHASE_ID) == nil, "Upgrader plate already exists")
local sourcePlate = originalPlates:FindFirstChild("RoyalMintDropper02")
assert(sourcePlate ~= nil and sourcePlate:IsA("BasePart") and sourcePlate.Archivable, "Styled Mint plate required")
for _, item in original:GetDescendants() do
	assert(not item:IsA("LuaSourceContainer"), "KingdomTemplate must be script-free")
end

local replacement = original:Clone()
local ok, reason = xpcall(function()
	local pivot = replacement:GetPivot()
	local unlocks = replacement:FindFirstChild("PurchaseUnlocks") :: Folder
	local plates = replacement:FindFirstChild("PurchasePlates") :: Folder
	local arch = Instance.new("Model")
	arch.Name = PURCHASE_ID
	arch.Parent = unlocks
	local iron = Color3.fromRGB(53, 57, 67)
	local blue = Color3.fromRGB(40, 65, 108)
	local gold = Color3.fromRGB(223, 165, 44)
	local stone = Color3.fromRGB(158, 149, 136)
	local amber = Color3.fromRGB(255, 184, 62)
	local count = 0
	local function part(name: string, size: Vector3, frame: CFrame, color: Color3, material: Enum.Material?): Part
		local item = Instance.new("Part")
		item.Name = name
		item.Size = size
		item.CFrame = pivot * frame
		item.Color = color
		item.Material = material or Enum.Material.Metal
		item.Anchored = true
		item.CanTouch = false
		item.TopSurface = Enum.SurfaceType.Smooth
		item.BottomSurface = Enum.SurfaceType.Smooth
		item.Parent = arch
		count += 1
		return item
	end
	-- The 10.8-stud clear arch opening straddles the existing 8-stud belt and rails.
	-- Posts/feet stay at Z -52 and clear the preceding press's forward housing edge.
	for _, x in { -86, -74 } do
		part("StoneFoot", Vector3.new(2.3, 0.8, 1.8), CFrame.new(x, 0.8, -52), stone, Enum.Material.Slate)
		part("GoldFootBand", Vector3.new(1.7, 0.35, 1.6), CFrame.new(x, 1.3, -52), gold)
		part("IronPillar", Vector3.new(1.2, 9.4, 1.2), CFrame.new(x, 5.9, -52), iron)
		part("RoyalBlueInset", Vector3.new(0.85, 6.7, 0.2), CFrame.new(x, 5.8, -51.3), blue)
		for _, dx in { -0.48, 0.48 } do
			part("GoldPillarEdge", Vector3.new(0.15, 7.8, 0.18), CFrame.new(x + dx, 5.8, -51.24), gold)
		end
		for _, y in { 2.1, 8.9 } do
			part("PillarCollar", Vector3.new(1.6, 0.35, 1.6), CFrame.new(x, y, -52), gold)
		end
		part("AmberInsetFrame", Vector3.new(0.65, 3.4, 0.25), CFrame.new(x, 5.5, -51.1), gold)
		local glow =
			part("AmberGlowInset", Vector3.new(0.32, 3, 0.12), CFrame.new(x, 5.5, -50.9), amber, Enum.Material.Neon)
		glow.CanCollide = false
		local light = Instance.new("PointLight")
		light.Name = "UpgraderAmberLight"
		light.Color = amber
		light.Brightness = 0.35
		light.Range = 6
		light.Shadows = false
		light.Parent = glow
		part("CapitalBlock", Vector3.new(1.9, 0.8, 1.8), CFrame.new(x, 10, -52), gold)
	end
	part("IronLintel", Vector3.new(14, 1.6, 1.6), CFrame.new(-80, 10.8, -52), iron)
	part("RoyalLintelFace", Vector3.new(12.6, 1.05, 0.25), CFrame.new(-80, 10.85, -51.05), blue)
	for _, y in { 10.15, 11.5 } do
		part("LintelGoldTrim", Vector3.new(14.2, 0.2, 1.85), CFrame.new(-80, y, -52), gold)
	end
	for _, x in { -85, -83, -77, -75 } do
		local rivet = part("LintelRivet", Vector3.new(0.35, 0.35, 0.2), CFrame.new(x, 10.85, -50.87), gold)
		rivet.Shape = Enum.PartType.Ball
	end
	-- Raised crown-and-coin medallion, readable from the service/collector side.
	local medallion = part(
		"GoldMedallion",
		Vector3.new(0.4, 3.7, 3.7),
		CFrame.new(-80, 12.1, -51.75) * CFrame.Angles(0, math.pi / 2, 0),
		gold
	)
	medallion.Shape = Enum.PartType.Cylinder
	local inset = part(
		"MedallionBlueInset",
		Vector3.new(0.2, 3.1, 3.1),
		CFrame.new(-80, 12.1, -51.4) * CFrame.Angles(0, math.pi / 2, 0),
		blue
	)
	inset.Shape = Enum.PartType.Cylinder
	part("CrownBand", Vector3.new(2.1, 0.35, 0.3), CFrame.new(-80, 11.6, -51.15), gold)
	for index, dx in { -0.8, 0, 0.8 } do
		local height = if index == 2 then 1.45 else 1.05
		part("CrownPoint", Vector3.new(0.42, height, 0.3), CFrame.new(-80 + dx, 11.75 + height / 2, -51.15), gold)
		local gem = part("CrownTip", Vector3.new(0.52, 0.52, 0.35), CFrame.new(-80 + dx, 11.8 + height, -51.15), gold)
		gem.Shape = Enum.PartType.Ball
	end
	local zone =
		part("UpgradeZone", Vector3.new(8, 4, 4), CFrame.new(-80, 5.5, -52) * CFrame.Angles(0, math.pi, 0), amber)
	zone.Transparency = 1
	zone.CanCollide = false
	zone.CanQuery = true
	arch.PrimaryPart = zone
	arch:SetAttribute("AuthoredPartCount", count)
	arch:SetAttribute("UpgraderId", PURCHASE_ID)
	-- Small background-free multiplier mark; no giant world-space instruction card.
	local multiplierGui = Instance.new("BillboardGui")
	multiplierGui.Name = "MultiplierLabel"
	multiplierGui.Adornee = zone
	multiplierGui.Size = UDim2.fromOffset(54, 24)
	multiplierGui.StudsOffsetWorldSpace = Vector3.new(0, 8.5, 0)
	multiplierGui.MaxDistance = 85
	multiplierGui.AlwaysOnTop = false
	multiplierGui.Parent = zone
	local multiplier = Instance.new("TextLabel")
	multiplier.Name = "MultiplierText"
	multiplier.Size = UDim2.fromScale(1, 1)
	multiplier.BackgroundTransparency = 1
	multiplier.Font = Enum.Font.GothamBold
	multiplier.TextSize = 14
	multiplier.Text = "×2"
	multiplier.TextColor3 = gold
	multiplier.TextStrokeTransparency = 0.4
	multiplier.Parent = multiplierGui

	local plate = sourcePlate:Clone()
	plate.Name = PURCHASE_ID
	local shift = pivot:PointToWorldSpace(Vector3.new(-64, 0.8, -52)) - plate.Position
	plate.CFrame += shift
	for _, item in plate:GetDescendants() do
		if item:IsA("BasePart") then
			item.CFrame += shift
		end
	end
	local label = plate:FindFirstChild("PurchaseLabel", true)
	assert(label ~= nil and label:IsA("TextLabel"), "PurchaseLabel required")
	local presentation = require(game.ReplicatedStorage.Shared.PlatePresentation)
	presentation.Style(plate)
	presentation.SetAmount(label, "Upgrader 1", 250)
	plate.Color = Color3.fromRGB(255, 45, 45)
	plate.Parent = plates
	assert(count < 150, "Upgrader prototype exceeds static part budget")
	for _, item in arch:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Upgrader must be script-free")
		if item:IsA("BasePart") then
			assert(
				item.Anchored and item:GetAttribute("MintCoinGuide") == nil,
				"Upgrader cannot alter Mint coin guides"
			)
			for _, x in { -0.5, 0.5 } do
				for _, y in { -0.5, 0.5 } do
					for _, z in { -0.5, 0.5 } do
						local corner = pivot:PointToObjectSpace(
							item.CFrame:PointToWorldSpace(
								Vector3.new(x * item.Size.X, y * item.Size.Y, z * item.Size.Z)
							)
						)
						assert(
							corner.X >= -88 and corner.X <= -72 and corner.Z >= -54 and corner.Z <= -50,
							"Upgrader exceeds reserved first station"
						)
					end
				end
			end
		end
	end
	assert(replacement:GetPivot() == original:GetPivot(), "Kingdom pivot changed")
	print(string.format("Mint upgrader asset checks passed (%d anchored parts, first arch only)", count))
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
print("Installed RoyalMintUpgrader01; original template retained in ServerStorage." .. BACKUP_NAME)
print("Coin template and existing Mint geometry are unchanged. Sync runtime source and verify before saving.")
