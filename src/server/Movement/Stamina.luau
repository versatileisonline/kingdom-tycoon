--!strict
local Config = require(game:GetService("ReplicatedStorage").Shared.SprintConfig)
export type State = { Remaining: number, Held: boolean, Exhausted: boolean, Active: boolean, Rest: number }
local Stamina = {}
function Stamina.New(): State
	return { Remaining = Config.CAPACITY, Held = false, Exhausted = false, Active = false, Rest = 0 }
end
function Stamina.SetHeld(state: State, held: boolean): ()
	state.Held = held
	if not held then
		state.Exhausted = false
	end
end
function Stamina.Step(state: State, dt: number, moving: boolean, allowed: boolean): ()
	if not allowed then
		Stamina.SetHeld(state, false)
	end
	state.Active = allowed and moving and state.Held and not state.Exhausted and state.Remaining > 0
	if state.Active then
		state.Rest = 0
		state.Remaining = math.max(0, state.Remaining - dt)
		if state.Remaining == 0 then
			state.Exhausted = true
			state.Active = false
		end
	else
		local old = state.Rest
		state.Rest += dt
		local recovery = math.max(0, state.Rest - Config.RECOVERY_DELAY) - math.max(0, old - Config.RECOVERY_DELAY)
		state.Remaining =
			math.min(Config.CAPACITY, state.Remaining + recovery * Config.CAPACITY / Config.REFILL_SECONDS)
	end
end
return Stamina
