--!strict

export type Purchase = {
	Id: string,
	Name: string,
	Price: number,
	Requires: string?,
	StudioOnly: boolean?,
	Optional: boolean?,
	FarmDropper: boolean?,
	ProductionSite: ("RoyalMint" | "RoyalMint02")?,
	UpgraderSite: ("RoyalMint" | "RoyalMint02")?,
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
	table.freeze({
		Id = "RoyalMintUpgrader02",
		Name = "Upgrader 2",
		Price = 300,
		Requires = "RoyalMintUpgrader01",
		UpgraderSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintUpgrader03",
		Name = "Upgrader 3",
		Price = 400,
		Requires = "RoyalMintUpgrader02",
		UpgraderSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintUpgrader04",
		Name = "Upgrader 4",
		Price = 600,
		Requires = "RoyalMintUpgrader03",
		UpgraderSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintUpgrader05",
		Name = "Upgrader 5",
		Price = 1000,
		Requires = "RoyalMintUpgrader04",
		UpgraderSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintUpgrader06",
		Name = "Upgrader 6",
		Price = 1900,
		Requires = "RoyalMintUpgrader05",
		UpgraderSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintUpgrader07",
		Name = "Upgrader 7",
		Price = 3800,
		Requires = "RoyalMintUpgrader06",
		UpgraderSite = "RoyalMint" :: "RoyalMint",
	}),
	table.freeze({
		Id = "RoyalMintUpgrader08",
		Name = "Upgrader 8",
		Price = 7500,
		Requires = "RoyalMintUpgrader07",
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

local secondPrices =
	{ 12000, 12200, 12400, 12600, 12800, 13000, 13200, 13400, 13600, 13800, 14000, 14200, 14500, 15000, 16500, 19500 }
local previous = "RoyalMintUpgrader08"
-- Insert before Studio-only fixtures so the live frontier remains contiguous.
local insertion = #purchases - 1
for index, price in secondPrices do
	local id = if index == 1
		then "RoyalMint02"
		elseif index <= 8 then string.format("RoyalMint02Dropper%02d", index)
		else string.format("RoyalMint02Upgrader%02d", index - 8)
	local entry: Purchase = {
		Id = id,
		Name = if index == 1
			then "Royal Mint 2"
			elseif index <= 8 then string.format("Mint 2 Dropper %d", index)
			else string.format("Mint 2 Upgrader %d", index - 8),
		Price = price,
		Requires = previous,
	}
	if index <= 8 then
		entry.ProductionSite = "RoyalMint02"
	else
		entry.UpgraderSite = "RoyalMint02"
	end
	table.insert(purchases, insertion, table.freeze(entry))
	insertion += 1
	previous = id
end

local optionalOffers: { { string | number } } = {
	{ "RoyalBanners", "Royal Banners", 250 },
	{ "RoyalLanterns", "Lanterns", 400 },
	{ "TrainingSword", "Sword", 600 },
	{ "SprintTraining", "Sprint Training", 1000 },
	{ "HorsePaddock", "Horse Paddock", 1900 },
	{ "RoyalFountain", "Fountain", 4000 },
}
for _, offer in optionalOffers do
	table.insert(
		purchases,
		table.freeze({
			Id = offer[1] :: string,
			Name = offer[2] :: string,
			Price = offer[3] :: number,
			Requires = "RoyalMintDropper08",
			Optional = true,
		})
	)
end

return table.freeze({
	PURCHASES = table.freeze(purchases),
	RUN_TESTS_IN_STUDIO = false,
	TOUCH_DISTANCE = 7,
	TOUCH_COOLDOWN_SECONDS = 0.5,
})
