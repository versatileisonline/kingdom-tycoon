--!strict
-- Approved one-time Edit recipe: raise the installed housed presses, keeping a visible coin fall.
-- Runtime source remains on disk; this file is never Rojo-mapped.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local BACKUP_NAME = "RoyalMintHeightBackup_20261117"
local RAISE_HEIGHT = 3
assert(not RunService:IsRunning(), "Stop Play before raising the Royal Mint droppers")
assert(game.PlaceId == 77311816657817, "Wrong Kingdom Tycoon place")
assert(ServerStorage:FindFirstChild(BACKUP_NAME) == nil, "Mint height revision already installed")
local active = workspace:FindFirstChild("ActiveKingdoms")
assert(active == nil or #active:GetChildren() == 0, "Release active kingdoms before installation")
local original = ServerStorage:FindFirstChild("KingdomTemplate")
assert(original ~= nil and original:IsA("Model") and original.Archivable, "Archivable KingdomTemplate required")
local unlocks = original:FindFirstChild("PurchaseUnlocks")
local originalMint = if unlocks ~= nil then unlocks:FindFirstChild("RoyalMint") else nil
assert(originalMint ~= nil and originalMint:IsA("Model"), "Installed Royal Mint required")
assert(
	originalMint:GetAttribute("Revision") == "WideYardHousedPresses",
	"Install the wide-yard housed-press revision first"
)
local previousCount = originalMint:GetAttribute("AuthoredPartCount")
assert(typeof(previousCount) == "number", "Mint authored part count required")
for _, item in original:GetDescendants() do
	assert(not item:IsA("LuaSourceContainer"), "Template must be script-free")
end

local replacement = original:Clone()
local ok, reason = xpcall(function()
	local pivot = replacement:GetPivot()
	local copiedUnlocks = replacement:FindFirstChild("PurchaseUnlocks")
	assert(copiedUnlocks ~= nil, "Cloned unlock folder missing")
	local mint = copiedUnlocks:FindFirstChild("RoyalMint")
	assert(mint ~= nil and mint:IsA("Model"), "Cloned Mint missing")
	local producers = mint:FindFirstChild("Producers")
	assert(producers ~= nil and producers:IsA("Folder") and #producers:GetChildren() == 8, "Eight presses required")
	local raised = 0
	local added = 0
	local function supportPart(
		parent: Model,
		name: string,
		size: Vector3,
		position: Vector3,
		color: Color3,
		material: Enum.Material
	): ()
		assert(parent:FindFirstChild(name) == nil, "Support already exists: " .. name)
		local item = Instance.new("Part")
		item.Name = name
		item.Size = size
		item.CFrame = pivot * CFrame.new(position)
		item.Color = color
		item.Material = material
		item.Anchored = true
		item.CanTouch = false
		item.TopSurface = Enum.SurfaceType.Smooth
		item.BottomSurface = Enum.SurfaceType.Smooth
		item.Parent = parent
		added += 1
	end
	for index = 1, 8 do
		local press = producers:FindFirstChild(string.format("Dropper%02d", index))
		assert(press ~= nil and press:IsA("Model"), "Missing housed press")
		local drop = press:FindFirstChild("DropPoint")
		local plinth = press:FindFirstChild("MachinePlinth")
		assert(drop ~= nil and drop:IsA("BasePart"), "Press requires direct DropPoint")
		assert(plinth ~= nil and plinth:IsA("BasePart"), "Press requires its existing floor plinth")
		local dropPosition = pivot:PointToObjectSpace(drop.Position)
		assert(math.abs(dropPosition.Y - 4.1) < 0.01, "Unexpected drop height; inspect before replacing edited assets")
		local originalPlinthFrame = plinth.CFrame
		local offset = pivot.UpVector * RAISE_HEIGHT
		for _, item in press:GetDescendants() do
			if item:IsA("BasePart") then
				assert(item.Anchored, "Only static anchored machinery can be raised")
				if item ~= plinth then
					item.CFrame += offset
				end
			end
		end
		local z = -58 + 12 * (index - 1)
		-- Solid support joins the unchanged floor plinth to the raised iron bed.
		supportPart(
			press,
			"RaisedPressPedestal",
			Vector3.new(11.5, 3, 8.5),
			Vector3.new(-89, 2.6, z),
			Color3.fromRGB(115, 112, 107),
			Enum.Material.Slate
		)
		supportPart(
			press,
			"PedestalIronFoot",
			Vector3.new(11.8, 0.35, 8.8),
			Vector3.new(-89, 1.375, z),
			Color3.fromRGB(53, 57, 67),
			Enum.Material.Metal
		)
		supportPart(
			press,
			"PedestalGoldCap",
			Vector3.new(11.8, 0.25, 8.8),
			Vector3.new(-89, 3.975, z),
			Color3.fromRGB(223, 165, 44),
			Enum.Material.Metal
		)
		assert(plinth.CFrame == originalPlinthFrame, "Floor plinth moved")
		assert(math.abs(pivot:PointToObjectSpace(drop.Position).Y - 7.1) < 0.01, "Raised DropPoint height mismatch")
		raised += 1
		task.wait()
	end
	for _, item in mint:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Mint must remain script-free")
		if item:IsA("BasePart") then
			assert(item.Anchored, "Mint must remain anchored")
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
							"Raised Mint exceeds yard bounds"
						)
					end
				end
			end
		end
	end
	assert(raised == 8 and added == 24, "Incomplete press-height revision")
	assert(replacement:GetPivot() == original:GetPivot(), "Kingdom pivot changed")
	mint:SetAttribute("AuthoredPartCount", previousCount + added)
	mint:SetAttribute("Revision", "RaisedHousedPresses")
	print(
		string.format(
			"Raised Royal Mint asset checks passed (%d presses, +%d support parts, DropPoint Y 7.1)",
			raised,
			added
		)
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
print("Raised Royal Mint droppers; original template retained in ServerStorage." .. BACKUP_NAME)
print("Belt, rails, coin template, rates, prices and collection are unchanged. Verify coin fall, then save the place.")
