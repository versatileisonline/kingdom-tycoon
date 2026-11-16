--!strict
local Lighting = game:GetService("Lighting")
local Settings = require(script.Parent.SettingsController)
local Controller = {}
local connections: { RBXScriptConnection } = {}
local originals: { [Instance]: boolean } = {}
local shadows = Lighting.GlobalShadows
local started = false
local function enabled(item: Instance): boolean?
	if item:IsA("PostEffect") or item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
		return item.Enabled
	end
	return nil
end
local function setEnabled(item: Instance, value: boolean): ()
	if item:IsA("PostEffect") then
		item.Enabled = value
	end
	if item:IsA("ParticleEmitter") then
		item.Enabled = value
	end
	if item:IsA("Trail") then
		item.Enabled = value
	end
	if item:IsA("Beam") then
		item.Enabled = value
	end
end

local function apply(item: Instance): ()
	if Settings.Get("LowGraphics") ~= true then
		return
	end
	local previous = enabled(item)
	if previous ~= nil and originals[item] == nil then
		originals[item] = previous
		setEnabled(item, false)
	end
end
local function restore(): ()
	Lighting.GlobalShadows = shadows
	for item, value in originals do
		setEnabled(item, value)
	end
	table.clear(originals)
end
function Controller.Init(): () end
function Controller.Start(): ()
	if started then
		return
	end
	started = true
	shadows = Lighting.GlobalShadows
	local function refresh(): ()
		if Settings.Get("LowGraphics") == true then
			Lighting.GlobalShadows = false
			for _, root in { workspace, Lighting } do
				for _, item in root:GetDescendants() do
					apply(item)
				end
			end
		else
			restore()
		end
	end
	table.insert(
		connections,
		Settings.Observe(function(key: string): ()
			if key == "LowGraphics" then
				refresh()
			end
		end)
	)
	for _, root in { workspace, Lighting } do
		table.insert(connections, root.DescendantAdded:Connect(apply))
		table.insert(
			connections,
			root.DescendantRemoving:Connect(function(item: Instance): ()
				local previous = originals[item]
				if previous ~= nil then
					setEnabled(item, previous)
					originals[item] = nil
				end
			end)
		)
	end
	refresh()
	table.insert(connections, script.Destroying:Connect(Controller.Shutdown))
end
function Controller.Shutdown(): ()
	for _, c in connections do
		c:Disconnect()
	end
	table.clear(connections)
	restore()
	started = false
end
return Controller
