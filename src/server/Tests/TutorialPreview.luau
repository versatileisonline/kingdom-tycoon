--!strict
-- Opt-in, session-only developer fixture. Never operates outside Studio Mock.
local Preview = {}
function Preview.Run(): ()
	local Server = script.Parent.Parent
	local Config = require(game.ReplicatedStorage.Shared.Config)
	assert(game:GetService("RunService"):IsStudio() and Config.DATA.STUDIO_MODE == "Mock", "Studio Mock only")
	local Data = require(Server.Services.DataService)
	local Plots = require(Server.Services.PlotService)
	local Farms = require(Server.Services.FarmService)
	local Progress = require(Server.Presentation.TutorialProgress)
	local player: Player? = nil
	local deadline = os.clock() + 30
	repeat
		player = game.Players:GetPlayers()[1]
		if
			player
			and player.Character
			and player.Character:FindFirstChild("HumanoidRootPart")
			and Data.GetSnapshot(player)
		then
			break
		end
		task.wait(0.1)
	until os.clock() > deadline
	assert(player and player.Character, "Preview player unavailable")
	local owner = player :: Player
	local character = owner.Character :: Model
	local frontierAttribute = Server:GetAttribute("StudioPreviewFrontier")
	local frontier = if typeof(frontierAttribute) == "string" then frontierAttribute else "RoyalMintDropper02"
	local purchases: { [string]: boolean } = {}
	local found = false
	for _, purchase in require(game.ReplicatedStorage.Shared.PurchaseConfig).PURCHASES do
		if purchase.Id == frontier then
			found = true
			break
		end
		if not purchase.StudioOnly then
			purchases[purchase.Id] = true
		end
	end
	assert(found, "Unknown preview frontier")
	local initialGold = Server:GetAttribute("StudioPreviewGold")
	local gold = if typeof(initialGold) == "number" then initialGold else 1000000
	assert(Data.Update(owner, function(draft)
		draft.Gold = gold
		draft.PurchasedBuildings = purchases
	end))
	local marker = workspace.Plots.Plot01.ClaimMarker
	character:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 3, 10)))
	assert(Plots.TryClaim(owner, "Plot01"), "Preview claim failed")
	local kingdom = Plots.GetKingdom(owner) :: Model
	local start = kingdom:FindFirstChild("FarmStartPlate") :: BasePart
	character:PivotTo(CFrame.new(start.Position + Vector3.new(0, 3, 0)))
	assert(Farms.TryStart(owner), "Preview farm start failed")
	Progress.MarkCollected(owner, "StarterFarm")
	if purchases.RoyalMintDropper02 then
		Progress.MarkCollected(owner, "RoyalMint")
	end
	local plate = (kingdom:FindFirstChild("PurchasePlates") :: Folder):FindFirstChild(frontier) :: BasePart
	assert(plate, "Preview frontier plate missing")
	character:PivotTo(CFrame.lookAt(plate.Position + Vector3.new(0, 3, 12), plate.Position + Vector3.new(0, 3, 0)))
	local connection: RBXScriptConnection? = nil
	connection = Server:GetAttributeChangedSignal("StudioGrantGold"):Connect(function(): ()
		local amount = Server:GetAttribute("StudioGrantGold")
		Server:SetAttribute("StudioGrantGold", nil)
		if typeof(amount) ~= "number" or amount ~= amount or amount < 1 or amount % 1 ~= 0 then
			return
		end
		local success = Data.Update(owner, function(draft)
			assert(amount <= Config.DATA.MAX_SAFE_INTEGER - draft.Gold, "Grant exceeds safe range")
			draft.Gold += amount
		end)
		print(if success then "Studio preview Gold granted" else "Studio preview Gold grant rejected")
	end)
	game.Players.PlayerRemoving:Once(function(): ()
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end)
	print(string.format("Tutorial preview ready: %s; %d Gold (Mock only)", frontier, gold))
end
return Preview
