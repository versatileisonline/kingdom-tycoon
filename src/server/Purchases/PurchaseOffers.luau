--!strict
type Offer = { Id: string, Requires: string?, Optional: boolean? }
local Offers = {}
function Offers.Next(entries: { any }, owned: { [string]: boolean }): any
	for _, entry in entries do
		if not entry.Optional and owned[entry.Id] ~= true then
			return entry
		end
	end
	return nil
end
function Offers.IsVisible(entry: Offer, nextEntry: any, owned: { [string]: boolean }, started: boolean): boolean
	return started
		and owned[entry.Id] ~= true
		and (entry.Optional == true or entry == nextEntry)
		and (entry.Requires == nil or owned[entry.Requires] == true)
end
return Offers
