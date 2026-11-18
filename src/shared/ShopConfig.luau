--!strict
export type Offer = { Key: string, Name: string, Description: string, PassId: number, PreviewPrice: number }
local offers: { Offer } = {
	table.freeze({
		Key = "CollectNow",
		Name = "Collect Now",
		Description = "Collect your earnings from anywhere.",
		PassId = 0,
		PreviewPrice = 49,
	}),
	table.freeze({
		Key = "DoubleGold",
		Name = "2× Gold",
		Description = "Double newly earned farm and Mint Gold.",
		PassId = 0,
		PreviewPrice = 99,
	}),
	table.freeze({
		Key = "AutoCollect",
		Name = "Auto-Collect",
		Description = "Earnings bank automatically as coins arrive.",
		PassId = 0,
		PreviewPrice = 149,
	}),
}
local byKey: { [string]: Offer } = {}
for _, offer in offers do
	byKey[offer.Key] = offer
end
return table.freeze({
	OFFERS = table.freeze(offers),
	BY_KEY = table.freeze(byKey),
	REMOTE_FOLDER = "KingdomShop",
	COLLECT_COOLDOWN = 0.75,
	REFRESH_COOLDOWN = 5,
	REQUEST_TIMEOUT_SECONDS = 5,
	LOOKUP_ATTEMPTS = 3,
	LOOKUP_RETRY_SECONDS = 2,
	AUTO_RETRY_SECONDS = 1,
	RUN_TESTS_IN_STUDIO = false,
	-- Approved shop illustration atlas. Zero means use the existing coin artwork.
	ART_ATLAS = "rbxassetid://83808747914581",
})
