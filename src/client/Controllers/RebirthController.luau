--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.RebirthConfig)
local Settings = require(script.Parent.SettingsController)
local View = require(script.Parent.Parent.UI.RebirthView)
local State = require(script.Parent.Parent.UI.RebirthState)
local Format = require(script.Parent.Parent.UI.HudState)
local Controller = {}
local alive = false
local connections: { RBXScriptConnection } = {}
local view: any = nil
function Controller.Init(): () end
function Controller.Start(): ()
	if alive then
		return
	end
	alive = true
	local player = Players.LocalPlayer
	local requests = State.Requests()
	view = View.new(player:WaitForChild("PlayerGui"), Settings)
	local requestRemote: RemoteEvent? = nil
	local function currentRebirths(): number
		local value = player:GetAttribute("Rebirths")
		return if typeof(value) == "number" then value else 0
	end
	local function presentation()
		local gold = player:GetAttribute("Gold")
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		return State.Presentation(
			player:GetAttribute("GoldReady") == true,
			if typeof(gold) == "number" then gold else 0,
			currentRebirths(),
			player:GetAttribute("ShopDoubleGold") == "Owned",
			humanoid ~= nil and humanoid.Health > 0,
			typeof(player:GetAttribute("KingdomPlotId")) == "string",
			requests.Busy()
		)
	end
	local function render(): ()
		if not alive then
			return
		end
		local state = presentation()
		local count = currentRebirths()
		local gold = player:GetAttribute("Gold")
		view.Reward.Text = string.format("%g× → %g×", state.CurrentMultiplier, state.NextMultiplier)
		view.Count.Text = string.format("Rebirth %d → %d", count, count + 1)
		view.Fill.Size = UDim2.fromScale(state.Progress, 1)
		view.Amount.Text = if state.Target
			then Format.FormatGold(if typeof(gold) == "number" then gold else nil) .. " / " .. Format.FormatGold(
				state.Target
			) .. " Gold"
			else "Maximum target reached"
		view.Status.Text = state.Status
		view.Confirm.Text = if requests.Busy() then "Rebirthing…" else (Config.COPY.Confirm or "Rebirth")
		view.Confirm.Active = state.Enabled and requestRemote ~= nil
		view.Confirm.Selectable = view.Confirm.Active
		view.Confirm.AutoButtonColor = view.Confirm.Active
		view.Confirm.TextTransparency = if view.Confirm.Active then 0 else 0.45
	end
	for _, attribute in { "Gold", "GoldReady", "Rebirths", "ShopDoubleGold", "KingdomPlotId" } do
		table.insert(connections, player:GetAttributeChangedSignal(attribute):Connect(render))
	end
	local healthConnection: RBXScriptConnection? = nil
	local function characterChanged(character: Model): ()
		if healthConnection then
			healthConnection:Disconnect()
			healthConnection = nil
		end
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 10)
			if not alive or player.Character ~= character then
				return
			end
			if humanoid and humanoid:IsA("Humanoid") then
				healthConnection = humanoid.HealthChanged:Connect(render)
			end
			render()
		end)
		render()
	end
	table.insert(connections, player.CharacterAdded:Connect(characterChanged))
	table.insert(
		connections,
		player.CharacterRemoving:Connect(function()
			if healthConnection then
				healthConnection:Disconnect()
				healthConnection = nil
			end
			task.defer(render)
		end)
	)
	if player.Character then
		characterChanged(player.Character)
	end
	table.insert(
		connections,
		view.Confirm.Activated:Connect(function()
			if not presentation().Enabled or requestRemote == nil then
				return
			end
			local count = currentRebirths()
			local requestId = requests.Begin(count)
			if requestId == nil then
				return
			end
			view.Message.Text = ""
			render()
			requestRemote:FireServer(count, requestId)
			task.delay(Config.REQUEST_TIMEOUT, function()
				if alive and requests.Resolve(requestId, count) then
					view.Message.Text = "Rebirth response delayed. Check your progress before trying again."
					render()
				end
			end)
		end)
	)
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild(Config.REMOTE_FOLDER, 15)
		if not alive then
			return
		end
		if not folder then
			view.Message.Text = "Rebirth is unavailable. Please rejoin."
			return
		end
		local request = folder:WaitForChild("Request", 10)
		local result = folder:WaitForChild("Result", 10)
		if not alive then
			return
		end
		if not request or not request:IsA("RemoteEvent") or not result or not result:IsA("RemoteEvent") then
			view.Message.Text = "Rebirth is unavailable. Please rejoin."
			return
		end
		requestRemote = request
		table.insert(
			connections,
			result.OnClientEvent:Connect(function(ok: unknown, message: unknown, count: unknown, requestId: unknown)
				if
					typeof(ok) ~= "boolean"
					or typeof(message) ~= "string"
					or typeof(count) ~= "number"
					or typeof(requestId) ~= "number"
				then
					return
				end
				if not requests.Resolve(requestId, count) then
					return
				end
				view.Message.Text = message
				if ok then
					Settings.Set("RebirthOpen", false)
				end
				render()
			end)
		)
		render()
	end)
	table.insert(
		connections,
		script.Destroying:Connect(function()
			alive = false
			if healthConnection then
				healthConnection:Disconnect()
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
	render()
	print("[KingdomTycoon][RebirthController] Rebirth ready")
end
return Controller
