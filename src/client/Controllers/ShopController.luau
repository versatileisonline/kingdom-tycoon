--!strict
local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.ShopConfig)
local Settings = require(script.Parent.SettingsController)
local View = require(script.Parent.Parent.UI.ShopView)
local State = require(script.Parent.Parent.UI.ShopState)
local Format = require(script.Parent.Parent.UI.HudState)
local Controller = {}
local view: any = nil
local connections: { RBXScriptConnection } = {}
local alive = false
local busyCollect = false
local requestGeneration = 0
local promptKey: string? = nil
local catalog: { [string]: { Price: number?, Available: boolean } } = {}
local catalogGeneration = 0
function Controller.Init(): () end
function Controller.Start(): ()
	if alive then
		return
	end
	alive = true
	local player = Players.LocalPlayer
	local folder = game:GetService("ReplicatedStorage"):WaitForChild(Config.REMOTE_FOLDER)
	local collectRemote = folder:WaitForChild("CollectNow") :: RemoteEvent
	local resultRemote = folder:WaitForChild("CollectResult") :: RemoteEvent
	local refreshRemote = folder:WaitForChild("RefreshOwnership") :: RemoteEvent
	view = View.new(player:WaitForChild("PlayerGui"), Settings)
	local function preview(): boolean
		return player:GetAttribute("ShopPreview") == true
	end
	local function message(text: string): ()
		if alive then
			view.Message.Text = text
		end
	end
	local function render(): ()
		if not alive then
			return
		end
		for _, offer in Config.OFFERS do
			local data = catalog[offer.Key]
			local label, enabled = State.Offer(
				player:GetAttribute("Shop" .. offer.Key) :: string?,
				if data then data.Price else nil,
				data ~= nil and data.Available
			)
			local button = view.Cards[offer.Key]
			button.Text = if promptKey == offer.Key then "Opening…" else label
			button.Active = enabled and promptKey == nil
			button.AutoButtonColor = button.Active
			button.TextTransparency = if enabled or label == "Owned" then 0 else 0.35
		end
		local owns = player:GetAttribute("ShopCollectNow") == "Owned"
		local pending = player:GetAttribute("UncollectedGold")
		local amount = if typeof(pending) == "number" then pending else 0
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		view.Collect.Visible = owns
		view.Collect.Active = owns
			and not busyCollect
			and amount > 0
			and player:GetAttribute("GoldReady") == true
			and player:GetAttribute("StarterFarmStarted") == true
			and humanoid ~= nil
			and humanoid.Health > 0
		view.Collect.AutoButtonColor = view.Collect.Active
		view.Collect.TextTransparency = if view.Collect.Active then 0 else 0.35
		view.Collect.Text = if busyCollect
			then "Collecting…"
			else "Collect Now\n" .. Format.FormatGold(amount) .. " Gold"
		view.Auto.Visible = player:GetAttribute("ShopAutoCollect") == "Owned" and not owns
		view.PreviewReset.Visible = preview()
		view.Subtitle.Text = if preview()
			then "STUDIO PREVIEW • No Robux charged"
			else "Permanent passes • Yours to keep"
	end
	local function loadCatalog(): ()
		catalogGeneration += 1
		local generation = catalogGeneration
		for _, offer in Config.OFFERS do
			if preview() then
				catalog[offer.Key] = { Price = offer.PreviewPrice, Available = true }
			elseif offer.PassId <= 0 then
				catalog[offer.Key] = { Available = false }
			else
				task.spawn(function()
					local ok, info = pcall(function()
						return Marketplace:GetProductInfoAsync(offer.PassId, Enum.InfoType.GamePass)
					end)
					if not alive or catalogGeneration ~= generation then
						return
					end
					catalog[offer.Key] = if ok
						then {
							Price = info.PriceInRobux,
							Available = info.IsForSale == true and typeof(info.PriceInRobux) == "number",
						}
						else { Available = false }
					render()
				end)
			end
		end
		render()
	end
	table.insert(connections, player:GetAttributeChangedSignal("ShopPreview"):Connect(loadCatalog))

	for _, offer in Config.OFFERS do
		table.insert(connections, player:GetAttributeChangedSignal("Shop" .. offer.Key):Connect(render))
		table.insert(
			connections,
			view.Cards[offer.Key].Activated:Connect(function()
				local data = catalog[offer.Key]
				local _, enabled = State.Offer(
					player:GetAttribute("Shop" .. offer.Key) :: string?,
					if data then data.Price else nil,
					data ~= nil and data.Available
				)
				if not enabled or promptKey ~= nil then
					return
				end
				if preview() then
					local event = folder:FindFirstChild("PreviewPurchase")
					if event and event:IsA("RemoteEvent") then
						event:FireServer(offer.Key)
						message("Preview purchase: " .. offer.Name .. " • No Robux charged")
					end
					return
				end
				promptKey = offer.Key
				render()
				local ok = pcall(function()
					Marketplace:PromptGamePassPurchase(player, offer.PassId)
				end)
				if not ok then
					promptKey = nil
					message("Purchase prompt unavailable. Please try again.")
					render()
				end
			end)
		)
	end
	table.insert(
		connections,
		Marketplace.PromptGamePassPurchaseFinished:Connect(function(who, passId, purchased)
			if who ~= player then
				return
			end
			for _, offer in Config.OFFERS do
				if passId == offer.PassId then
					promptKey = nil
					message(if purchased then "Confirming ownership…" else "Purchase cancelled.")
					render()
				end
			end
		end)
	)
	for _, attribute in { "UncollectedGold", "GoldReady", "StarterFarmStarted" } do
		table.insert(connections, player:GetAttributeChangedSignal(attribute):Connect(render))
	end
	local humanoidConnection: RBXScriptConnection? = nil
	local function characterChanged(character: Model): ()
		if humanoidConnection then
			humanoidConnection:Disconnect()
			humanoidConnection = nil
		end
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 10)
			if not alive or player.Character ~= character then
				return
			end
			if humanoid and humanoid:IsA("Humanoid") then
				humanoidConnection = humanoid.HealthChanged:Connect(render)
			end
			render()
		end)
		render()
	end
	table.insert(connections, player.CharacterAdded:Connect(characterChanged))
	if player.Character then
		characterChanged(player.Character)
	end
	table.insert(
		connections,
		view.Collect.Activated:Connect(function()
			if not view.Collect.Active then
				return
			end
			busyCollect = true
			requestGeneration += 1
			local generation = requestGeneration
			render()
			collectRemote:FireServer()
			task.delay(5, function()
				if alive and busyCollect and requestGeneration == generation then
					busyCollect = false
					message("Collection unavailable. Please try again.")
					render()
				end
			end)
		end)
	)
	table.insert(
		connections,
		resultRemote.OnClientEvent:Connect(function(ok: boolean, amount: number)
			busyCollect = false
			message(
				if ok
					then "Collected " .. Format.FormatGold(amount) .. " Gold"
					else "Nothing collected. Check your kingdom and try again."
			)
			render()
		end)
	)
	table.insert(
		connections,
		view.Retry.Activated:Connect(function()
			refreshRemote:FireServer()
			loadCatalog()
			message("Refreshing shop…")
		end)
	)
	table.insert(
		connections,
		view.PreviewReset.Activated:Connect(function()
			local event = folder:FindFirstChild("PreviewPurchase")
			if preview() and event and event:IsA("RemoteEvent") then
				event:FireServer("Reset")
				message("Preview passes reset • No Robux charged")
			end
		end)
	)
	table.insert(
		connections,
		script.Destroying:Connect(function()
			alive = false
			if humanoidConnection then
				humanoidConnection:Disconnect()
			end
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			if view then
				view.Screen:Destroy()
				view = nil
			end
		end)
	)
	local function previewReady(): ()
		if preview() and player:GetAttribute("ShopPreviewReady") == true then
			Settings.Set("ShopOpen", true)
		end
	end
	table.insert(connections, player:GetAttributeChangedSignal("ShopPreviewReady"):Connect(previewReady))
	previewReady()
	loadCatalog()
	print("[KingdomTycoon][ShopController] Shop ready")
end
return Controller
