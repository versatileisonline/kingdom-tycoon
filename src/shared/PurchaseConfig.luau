--!strict

export type Purchase = {
	Id: string,
	Name: string,
	Price: number,
	Requires: string?,
	StudioOnly: boolean?,
	FarmDropper: boolean?,
}

-- Prerequisites must appear before the purchases that require them.
local purchases: { Purchase } = {
	table.freeze({ Id = "FarmDropper02", Name = "Farm Dropper 2", Price = 6, FarmDropper = true }),
	table.freeze({
		Id = "FarmDropper03",
		Name = "Farm Dropper 3",
		Price = 12,
		Requires = "FarmDropper02",
		FarmDropper = true,
	}),
	table.freeze({
		Id = "FarmDropper04",
		Name = "Farm Dropper 4",
		Price = 24,
		Requires = "FarmDropper03",
		FarmDropper = true,
	}),
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
	RUN_TESTS_IN_STUDIO = false,
	TOUCH_DISTANCE = 7,
	TOUCH_COOLDOWN_SECONDS = 0.5,
})
