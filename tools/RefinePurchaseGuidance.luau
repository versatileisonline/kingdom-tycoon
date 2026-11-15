--!strict
-- Approved one-time Edit refinement; source geometry remains Studio-owned.
local storage = game:GetService("ServerStorage")
local shared = game:GetService("ReplicatedStorage").Shared
local BACKUP = "PlateGuidanceBackup_20261115"
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before refining assets")
assert(game.PlaceId == 77311816657817, "Wrong Kingdom Tycoon place")
assert(storage:FindFirstChild(BACKUP) == nil, "Refinement already applied")
local kingdom = storage:FindFirstChild("KingdomTemplate")
assert(kingdom ~= nil and kingdom:IsA("Model"), "Stored template required")
local farm = kingdom:FindFirstChild("StarterFarm")
assert(farm ~= nil and farm:IsA("Model"), "Farm required")
local plots = workspace:FindFirstChild("Plots")
local plot = if plots ~= nil then plots:FindFirstChild("Plot01") else nil
local claim = if plot ~= nil then plot:FindFirstChild("ClaimMarker") else nil
assert(claim ~= nil and claim:IsA("BasePart"), "Claim plate required")
-- Fresh copies avoid stale Edit-mode require caches; no script Source edits.
local scope = Instance.new("Folder")
for _, name in { "Config", "PlatePresentation" } do
	local source = shared:FindFirstChild(name)
	assert(source ~= nil and source:IsA("ModuleScript"), "Sync " .. name .. " through Rojo first")
	source:Clone().Parent = scope
end
local styleModule = scope:FindFirstChild("PlatePresentation") :: ModuleScript
scope.Parent = storage
local backup = Instance.new("Folder")
backup.Name = BACKUP
kingdom:Clone().Parent = backup
claim:Clone().Parent = backup
backup.Parent = storage

local ok, reason = pcall(function(): string?
	local style: any = (require :: any)(styleModule)
	style.Style(claim)
	local claimLabel = claim:FindFirstChild("ClaimLabel", true) :: TextLabel
	claimLabel.Text = "Claim"
	local start = kingdom:FindFirstChild("FarmStartPlate") :: BasePart
	local collect = farm:FindFirstChild("CollectPlate") :: BasePart
	style.Style(start)
	style.Style(collect)
	local startLabel = start:FindFirstChild("StartLabel", true) :: TextLabel
	local collectLabel = collect:FindFirstChild("EarningsLabel", true) :: TextLabel
	startLabel.Text = "Start Farm"
	collectLabel.Text = "Collect\n0"
	local plates = kingdom:FindFirstChild("PurchasePlates")
	assert(plates ~= nil, "Purchase plates required")
	for _, plate in plates:GetChildren() do
		assert(plate:IsA("BasePart"), "Purchase plate must be a BasePart")
		style.Style(plate)
		local index = string.match(plate.Name, "^FarmDropper0([234])$")
		assert(index ~= nil, "Unexpected purchase plate; inspect before styling")
		local label = plate:FindFirstChild("PurchaseLabel", true) :: TextLabel
		label.Text = "Dropper " .. index
	end
	return nil
end)
scope:Destroy()
assert(ok, reason)
print("Small plates and text-only labels installed; prior template/claim preserved in " .. BACKUP)
