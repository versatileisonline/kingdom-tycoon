--!strict
local Config = require(game:GetService("ReplicatedStorage").Shared.SprintConfig)
export type State = {
	Pressed: boolean,
	Locked: boolean,
	Requested: boolean,
	PressedAt: number,
	LastTap: number?,
	Stopped: number,
}
local Input = {}
function Input.New(): State
	return { Pressed = false, Locked = false, Requested = false, PressedAt = 0, LastTap = nil, Stopped = 0 }
end
function Input.Cancel(state: State): ()
	state.Pressed, state.Locked, state.Requested = false, false, false
	state.LastTap, state.Stopped = nil, 0
end
function Input.Press(state: State, now: number): ()
	if state.Pressed then
		return
	end
	state.Pressed, state.PressedAt = true, now
	if state.Locked then
		state.Locked, state.Requested, state.LastTap = false, false, nil
	else
		state.Locked = state.LastTap ~= nil and now - state.LastTap <= Config.DOUBLE_TAP_SECONDS
		state.Requested, state.LastTap = true, nil
	end
	state.Stopped = 0
end
function Input.Release(state: State, now: number): ()
	if not state.Pressed then
		return
	end
	state.Pressed = false
	state.LastTap = if state.Requested
			and not state.Locked
			and now - state.PressedAt <= Config.DOUBLE_TAP_SECONDS
		then state.PressedAt
		else nil
	state.Requested = state.Locked
end
function Input.Step(state: State, dt: number, moving: boolean): ()
	state.Stopped = if state.Locked and not moving then state.Stopped + dt else 0
	if state.Locked and state.Stopped >= Config.STOP_GRACE_SECONDS then
		Input.Cancel(state)
	end
end
return Input
