--!strict
-- Pure presentation choice. Authoritative purchases and collections remain server-owned.
local State = {}
export type Target =
	"StartFarm"
	| "FarmCollect"
	| "Walls"
	| "RoyalMint"
	| "MintDropper02"
	| "MintCollect"
	| "Upgrader01"
export type Input = {
	Ready: boolean,
	Started: boolean,
	FarmCollected: boolean,
	MintCollected: boolean,
	WallsOwned: boolean,
	MintOwned: boolean,
	MintDropper02Owned: boolean,
	Upgrader01Owned: boolean,
	Gold: number,
	Balance: number,
}
export type Prices = { Walls: number, RoyalMint: number, MintDropper02: number, Upgrader01: number }
function State.Select(input: Input, prices: Prices): Target?
	if not input.Ready then
		return nil
	end
	if not input.Started then
		return "StartFarm"
	end
	if not input.FarmCollected then
		return if input.Balance >= 1 then "FarmCollect" else nil
	end
	if not input.WallsOwned then
		return if input.Gold >= prices.Walls then "Walls" else nil
	end
	if not input.MintOwned then
		return if input.Gold >= prices.RoyalMint then "RoyalMint" else nil
	end
	if not input.MintDropper02Owned then
		return if input.Gold >= prices.MintDropper02 then "MintDropper02" else nil
	end
	if not input.MintCollected then
		return if input.Balance >= 1 then "MintCollect" else nil
	end
	if not input.Upgrader01Owned then
		return if input.Gold >= prices.Upgrader01 then "Upgrader01" else nil
	end
	return nil
end
return State
