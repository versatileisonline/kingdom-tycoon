--!strict
-- One-time Edit-mode recipe. Only decorates the standalone coin source.
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "Stop Play before decorating the source coin")
local storage = game:GetService("ServerStorage")
local name = "RoyalHudCoinBackup_20261117"
assert(storage:FindFirstChild(name) == nil, "Coin artwork already installed; inspect the existing backup")
local coin = storage:FindFirstChild("RoyalMintCoin")
assert(
	coin and coin:IsA("Part") and coin.Shape == Enum.PartType.Cylinder and coin.Archivable,
	"Expected archivable cylindrical RoyalMintCoin"
)
assert(
	coin:FindFirstChild("RoyalGoldFaceLeft") == nil and coin:FindFirstChild("RoyalGoldFaceRight") == nil,
	"Coin has conflicting artwork"
)
for _, item in coin:GetDescendants() do
	assert(not item:IsA("LuaSourceContainer"), "Coin must be script-free")
end
local backup = Instance.new("Folder")
backup.Name = name
local original = coin:Clone()
original.Parent = backup
local faces = {}
for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
	local decal = Instance.new("Decal")
	decal.Name = "RoyalGoldFace" .. face.Name
	decal.Face = face
	decal.Texture = "rbxassetid://94873438043725"
	table.insert(faces, decal)
end
backup.Parent = storage
for _, decal in faces do
	decal.Parent = coin
end
print("Royal HUD coin artwork installed; original preserved in " .. name)
print("Royal HUD coin geometry preserved; verify gold rim brightening through upgraders")
