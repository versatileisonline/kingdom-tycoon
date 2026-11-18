--!strict
-- Lookup generations prevent stale network responses from replacing newer state.
local Registry = {}
export type Status = "Loading" | "Owned" | "Unowned" | "Unavailable"
export type Registry = {
	Get: (string) -> Status,
	Owns: (string) -> boolean,
	Begin: (string) -> number,
	Complete: (string, number, boolean?) -> boolean,
	SetPreview: (string, boolean) -> (),
	Destroy: () -> (),
}
function Registry.new(): Registry
	local statuses: { [string]: Status } = {}
	local generations: { [string]: number } = {}
	local alive = true
	local function begin(key: string): number
		generations[key] = (generations[key] or 0) + 1
		if statuses[key] ~= "Owned" then
			statuses[key] = "Loading"
		end
		return generations[key]
	end
	return {
		Get = function(key)
			return statuses[key] or "Loading"
		end,
		Owns = function(key)
			return alive and statuses[key] == "Owned"
		end,
		Begin = begin,
		Complete = function(key, generation, owned)
			if not alive or generations[key] ~= generation then
				return false
			end
			if owned == true then
				statuses[key] = "Owned"
			elseif statuses[key] ~= "Owned" then
				statuses[key] = if owned == false then "Unowned" else "Unavailable"
			end
			return true
		end,
		SetPreview = function(key, owned)
			begin(key)
			statuses[key] = if owned then "Owned" else "Unowned"
		end,
		Destroy = function()
			alive = false
			table.clear(statuses)
			table.clear(generations)
		end,
	}
end
return Registry
