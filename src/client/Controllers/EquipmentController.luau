--!strict
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.EquipmentConfig)
local Controller = {}
local connections: { RBXScriptConnection } = {}
local characterConnections: { RBXScriptConnection } = {}
local tools: { [Tool]: { RBXScriptConnection } } = {}
local remote: RemoteEvent
local started = false
local function clearTools(): ()
	for _, list in tools do
		for _, connection in list do
			connection:Disconnect()
		end
	end
	table.clear(tools)
	for _, connection in characterConnections do
		connection:Disconnect()
	end
	table.clear(characterConnections)
end
local function observe(instance: Instance): ()
	if not instance:IsA("Tool") or instance.Name ~= Config.TEMPLATE_NAME or tools[instance] then
		return
	end
	local tool = instance :: Tool
	local list: { RBXScriptConnection } = {}
	tools[tool] = list
	table.insert(
		list,
		tool.Activated:Connect(function()
			if tool.Parent == Players.LocalPlayer.Character then
				remote:FireServer()
			end
		end)
	)
	table.insert(
		list,
		tool.Destroying:Connect(function()
			for _, connection in list do
				connection:Disconnect()
			end
			tools[tool] = nil
		end)
	)
end
local function bind(character: Model): ()
	clearTools()
	table.insert(characterConnections, character.ChildAdded:Connect(observe))
	for _, child in character:GetChildren() do
		observe(child)
	end
end
function Controller.Init(): () end
function Controller.Start(): ()
	if started then
		return
	end
	started = true
	remote =
		game:GetService("ReplicatedStorage"):WaitForChild(Config.REMOTE_FOLDER):WaitForChild("Swing") :: RemoteEvent
	table.insert(connections, Players.LocalPlayer.CharacterAdded:Connect(bind))
	table.insert(connections, Players.LocalPlayer.CharacterRemoving:Connect(clearTools))
	table.insert(connections, script.Destroying:Connect(Controller.Shutdown))
	if Players.LocalPlayer.Character then
		bind(Players.LocalPlayer.Character)
	end
end
function Controller.Shutdown(): ()
	clearTools()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	started = false
end
return Controller
