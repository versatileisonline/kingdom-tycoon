--!strict
-- Style authored world signs locally, including kingdoms cloned or streamed later.
local Config = require(game:GetService("ReplicatedStorage").Shared.HudConfig)
local Controller = {}
local connections: { RBXScriptConnection } = {}
local roots: { [Instance]: { RBXScriptConnection } } = {}
local originals: { [TextLabel]: Font } = {}
local started = false
local ROOT_NAMES = { ActiveKingdoms = true, KingdomMap = true, Plots = true }
local function apply(item: Instance): ()
	if
		item:IsA("TextLabel")
		and (item:FindFirstAncestorWhichIsA("SurfaceGui") or item:FindFirstAncestorWhichIsA("BillboardGui"))
	then
		if originals[item] == nil then
			originals[item] = item.FontFace
		end
		item.Font = Config.FONT
	end
end
local function restore(item: Instance): ()
	if item:IsA("TextLabel") then
		local previous = originals[item]
		if previous then
			item.FontFace = previous
			originals[item] = nil
		end
	end
end
local function removeRoot(root: Instance): ()
	local list = roots[root]
	if not list then
		return
	end
	for _, c in list do
		c:Disconnect()
	end
	roots[root] = nil
	for item in originals do
		if item:IsDescendantOf(root) then
			restore(item)
		end
	end
end
local function addRoot(root: Instance): ()
	if not ROOT_NAMES[root.Name] or roots[root] then
		return
	end
	roots[root] = {
		root.DescendantAdded:Connect(apply),
		root.DescendantRemoving:Connect(restore),
	}
	for _, item in root:GetDescendants() do
		apply(item)
	end
end
function Controller.Init(): () end
function Controller.Start(): ()
	if started then
		return
	end
	started = true
	table.insert(connections, workspace.ChildAdded:Connect(addRoot))
	table.insert(connections, workspace.ChildRemoved:Connect(removeRoot))
	table.insert(connections, script.Destroying:Connect(Controller.Shutdown))
	for _, root in workspace:GetChildren() do
		addRoot(root)
	end
end
function Controller.Shutdown(): ()
	for _, c in connections do
		c:Disconnect()
	end
	table.clear(connections)
	for root in roots do
		removeRoot(root)
	end
	for item in originals do
		restore(item)
	end
	started = false
end
return Controller
