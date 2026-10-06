--!strict

-- Shared type declarations do not replicate actual player profiles.
export type Lifecycle = {
	Init: () -> (),
	Start: () -> (),
}

export type PlayerData = {
	SchemaVersion: number,
	Gold: number,
	Rebirths: number,
	PurchasedBuildings: { [string]: boolean },
}

return {}
