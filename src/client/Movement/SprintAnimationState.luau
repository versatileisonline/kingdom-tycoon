--!strict
local State = {}
export type Conditions = { Sprinting: boolean, Alive: boolean, Grounded: boolean, Moving: boolean, Blocked: boolean }
function State.ShouldPlay(c: Conditions): boolean
	return c.Sprinting and c.Alive and c.Grounded and c.Moving and not c.Blocked
end
return State
