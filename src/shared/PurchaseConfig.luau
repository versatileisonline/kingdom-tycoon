--!strict

export type Purchase = {
	Id: string,
	Name: string,
	Price: number,
	Requires: string?,
	StudioOnly: boolean?,
	FarmDropper: boolean?,
	ProductionSite: "RoyalMint"?,
	UpgraderSite: "RoyalMint"?,
}

-- Prerequisites must appear before the purchases that require them.
local purchases: { Purchase } = {
	table.freeze({ Id = "FarmDropper02", Name = "Dropper 2", Price = 6, FarmDropper = true }),
	table.freeze({
		Id = "FarmDropper03",
		Name = "Dropper 3",
		Price = 12,
		Requires = "FarmDropper02",
		FarmDropper = true,
	}),
	table.freeze({
		Id = "FarmDropper04",
		Name = "Dropper 4",
		Price = 24,
		Requires = "FarmDropper03",
		FarmDropper = true,
	}),
	table.freeze({ Id = "WoodenWalls", Name = "Wooden Walls", Price = 40, Requires = "FarmDropper04" }),
	table.freeze({
		Id = "RoyalMint",
		Name = "Royal Mint",
		Price = 60,
		Requires = "WoodenWalls",
		ProductionSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintDropper02",
		Name = "Mint Dropper 2",
		Price = 70,
		Requires = "RoyalMint",
		ProductionSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintDropper03",
		Name = "Mint Dropper 3",
		Price = 90,
		Requires = "RoyalMintDropper02",
		ProductionSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintDropper04",
		Name = "Mint Dropper 4",
		Price = 110,
		Requires = "RoyalMintDropper03",
		ProductionSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintDropper05",
		Name = "Mint Dropper 5",
		Price = 130,
		Requires = "RoyalMintDropper04",
		ProductionSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintDropper06",
		Name = "Mint Dropper 6",
		Price = 150,
		Requires = "RoyalMintDropper05",
		ProductionSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintDropper07",
		Name = "Mint Dropper 7",
		Price = 170,
		Requires = "RoyalMintDropper06",
		ProductionSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintDropper08",
		Name = "Mint Dropper 8",
		Price = 190,
		Requires = "RoyalMintDropper07",
		ProductionSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintUpgrader01",
		Name = "Upgrader 1",
		Price = 250,
		Requires = "RoyalMintDropper08",
		UpgraderSite = "RoyalMint" :: "RoyalMint",
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
