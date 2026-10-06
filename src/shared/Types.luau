--!strict

-- Startup contract only. Add gameplay/data types in their respective milestones.
export type Lifecycle = {
	Init: () -> (),
	Start: () -> (),
}

return {}
