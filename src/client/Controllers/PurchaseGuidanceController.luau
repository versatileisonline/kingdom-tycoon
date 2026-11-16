--!strict
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local SettingsController = require(script.Parent.SettingsController)
local Controller = {}
local connections: { RBXScriptConnection } = {}
local gui: BillboardGui? = nil

function Controller.Init(): () end

function Controller.Start(): ()
	if gui ~= nil then
		return
	end
	local player = Players.LocalPlayer
	local kingdoms = workspace:WaitForChild("ActiveKingdoms", Config.PLOTS.CHARACTER_TIMEOUT_SECONDS)
	if kingdoms == nil then
		return
	end
	local arrow = Instance.new("BillboardGui")
	arrow.Name = "FirstPurchaseArrow"
	arrow.ResetOnSpawn = false
	arrow.Size = UDim2.fromOffset(Config.PLATES.ARROW_SIZE, Config.PLATES.ARROW_SIZE)
	arrow.StudsOffsetWorldSpace = Vector3.new(0, Config.PLATES.ARROW_OFFSET, 0)
	arrow.MaxDistance = Config.PLATES.LABEL_DISTANCE
	arrow.AlwaysOnTop = true
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "↓"
	text.Font = Enum.Font.GothamMedium
	text.TextSize = Config.PLATES.ARROW_SIZE
	text.TextColor3 = Color3.fromRGB(245, 239, 218)
	text.TextTransparency = Config.PLATES.ARROW_TRANSPARENCY
	text.Parent = arrow
	local function refresh(): ()
		if gui == nil then
			return
		end
		local target: BasePart? = nil
		for _, kingdom in kingdoms:GetChildren() do
			if kingdom:GetAttribute("OwnerUserId") ~= player.UserId then
				continue
			end
			local plates = kingdom:FindFirstChild("PurchasePlates")
			local plate = if plates ~= nil then plates:FindFirstChild("FarmDropper02") else nil
			if plate ~= nil and plate:IsA("BasePart") then
				target = plate
			end
		end
		-- Engine permits clearing Adornee; current definitions type its setter as nonoptional.
		(arrow :: any).Adornee = target
		arrow.Enabled = target ~= nil and SettingsController.Get("HelperArrow") == true
	end
	table.insert(
		connections,
		SettingsController.Observe(function(key: string): ()
			if key == "HelperArrow" then
				refresh()
			end
		end)
	)
	gui = arrow
	arrow.Parent = player:WaitForChild("PlayerGui")
	table.insert(
		connections,
		kingdoms.DescendantAdded:Connect(function(item: Instance): ()
			if item.Name == "FarmDropper02" then
				refresh()
			end
		end)
	)
	table.insert(
		connections,
		kingdoms.DescendantRemoving:Connect(function(item: Instance): ()
			if item == arrow.Adornee then
				(arrow :: any).Adornee = nil
				arrow.Enabled = false
			end
		end)
	)
	table.insert(connections, player:GetAttributeChangedSignal("KingdomPlotId"):Connect(refresh))
	table.insert(
		connections,
		arrow.Destroying:Connect(function(): ()
			gui = nil
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
		end)
	)
	refresh()
end

return Controller
