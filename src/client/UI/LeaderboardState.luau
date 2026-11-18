--!strict
local State = {}
export type Entry = { UserId: number, Name: string, LifetimeGold: number?, Rebirths: number? }
function State.Sort(entries: { Entry }): { Entry }
	local result = table.clone(entries)
	table.sort(result, function(a: Entry, b: Entry): boolean
		if a.LifetimeGold == nil then
			return b.LifetimeGold == nil and a.UserId < b.UserId
		elseif b.LifetimeGold == nil then
			return true
		elseif a.LifetimeGold ~= b.LifetimeGold then
			return a.LifetimeGold > b.LifetimeGold
		end
		return a.UserId < b.UserId
	end)
	return result
end
function State.Format(value: number?): string
	if value == nil then
		return "..."
	end
	local text = string.format("%.0f", value)
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return formatted:gsub("^,", "")
end
return State
