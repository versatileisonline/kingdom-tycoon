--!strict
local State = {}
export type Value = number | boolean
function State.new(defaults: { [string]: Value })
	local values: { [string]: Value } = table.clone(defaults)
	return {
		Get = function(key: string): Value?
			return values[key]
		end,
		Set = function(key: string, value: unknown): boolean
			local previous = values[key]
			if previous == nil then
				return false
			end
			if typeof(previous) == "number" then
				if typeof(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
					return false
				end
				values[key] = math.clamp(value, 0, 1)
			else
				if typeof(value) ~= "boolean" then
					return false
				end
				values[key] = value
			end
			return true
		end,
	}
end
function State.FormatGold(value: number?): string
	if value == nil then
		return "—"
	end
	local text = string.format("%.0f", value)
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return formatted:gsub("^,", "")
end
return State
