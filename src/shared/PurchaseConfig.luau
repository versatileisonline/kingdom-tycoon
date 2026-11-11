--!strict

export type Purchase = {
	Id: string,
	Name: string,
	Price: number,
	Requires: string?,
	StudioOnly: boolean?,
}

-- Prerequisites must appear before the purchases that require them.
local purchases: { Purchase } = {
	table.freeze({ Id = "StudioFarmCrates", Name = "Farm Crates", Price = 3, StudioOnly = true }),
	table.freeze({
		Id = "StudioFarmSupplies",
		Name = "Farm Supplies",
		Price = 6,
		Requires = "StudioFarmCrates",
		StudioOnly = true,
	}),
}

return table.freeze({
	PURCHASES = table.freeze(purchases),
	TOUCH_DISTANCE = 7,
	TOUCH_COOLDOWN_SECONDS = 0.5,
})
