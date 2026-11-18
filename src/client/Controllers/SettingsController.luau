--!strict
local State = require(script.Parent.Parent.UI.HudState)
local Config = require(game:GetService("ReplicatedStorage").Shared.HudConfig)
local state = State.new(Config.DEFAULTS :: any)
local changed = Instance.new("BindableEvent")
local Controller = {}
function Controller.Init(): () end
function Controller.Start(): () end
function Controller.Get(key: string): State.Value?
	return state.Get(key)
end
function Controller.Set(key: string, value: unknown): boolean
	if
		value == true and (key == "MenuOpen" or key == "ShopOpen" or key == "RebirthOpen" or key == "LeaderboardOpen")
	then
		for _, other in { "MenuOpen", "ShopOpen", "RebirthOpen", "LeaderboardOpen" } do
			if other ~= key and state.Get(other) == true then
				state.Set(other, false)
				changed:Fire(other, false)
			end
		end
	end
	local before = state.Get(key)
	if not state.Set(key, value) then
		return false
	end
	if state.Get(key) ~= before then
		changed:Fire(key, state.Get(key))
	end
	return true
end
function Controller.Observe(callback: (string, State.Value?) -> ()): RBXScriptConnection
	return changed.Event:Connect(callback)
end
return Controller
