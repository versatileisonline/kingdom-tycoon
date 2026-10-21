--!strict

-- Session ownership only. All operations are non-yielding, so a reservation is
-- atomic within this server's cooperative Luau scheduler.
local PlotRegistry = {}

function PlotRegistry.new(plotIds: { string })
	local owners: { [string]: number } = {}
	local assignments: { [number]: string } = {}
	local known: { [string]: boolean } = {}
	for _, id in plotIds do
		assert(not known[id], "Duplicate plot ID: " .. id)
		known[id] = true
	end

	return table.freeze({
		Reserve = function(userId: number, plotId: string): (boolean, string)
			if not known[plotId] then
				return false, "Unknown plot."
			end
			if assignments[userId] ~= nil then
				return false, "You already have a kingdom."
			end
			if owners[plotId] ~= nil then
				return false, "This land has already been claimed."
			end
			owners[plotId] = userId
			assignments[userId] = plotId
			return true, "Kingdom claimed."
		end,
		Release = function(userId: number): string?
			local id = assignments[userId]
			if id ~= nil then
				owners[id] = nil
				assignments[userId] = nil
			end
			return id
		end,
		GetPlot = function(userId: number): string?
			return assignments[userId]
		end,
		GetOwner = function(plotId: string): number?
			return owners[plotId]
		end,
	})
end

export type Registry = typeof(PlotRegistry.new({}))

return table.freeze(PlotRegistry)
