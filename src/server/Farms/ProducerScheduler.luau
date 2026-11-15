--!strict
local ProducerScheduler = {}
export type Scheduler = {
	SetEnabled: (number, boolean, number) -> (),
	TakeDue: (number, number) -> { number },
}

function ProducerScheduler.new(count: number, interval: number): Scheduler
	assert(count > 0 and count % 1 == 0 and interval > 0, "Invalid producer scheduling limits")
	local nextDrops: { [number]: number } = {}
	local cursor = 1
	return {
		SetEnabled = function(index: number, enabled: boolean, now: number): ()
			assert(index >= 1 and index <= count and index % 1 == 0, "Invalid producer index")
			if enabled then
				if nextDrops[index] == nil then
					nextDrops[index] = now + interval
				end
			else
				nextDrops[index] = nil
			end
		end,
		TakeDue = function(now: number, capacity: number): { number }
			local due: { number } = {}
			local lastServed: number? = nil
			for offset = 0, count - 1 do
				local index = (cursor + offset - 1) % count + 1
				local nextDrop = nextDrops[index]
				if nextDrop ~= nil and now >= nextDrop then
					nextDrops[index] = now + interval
					if #due < capacity then
						table.insert(due, index)
						lastServed = index
					end
				end
			end
			if lastServed ~= nil then
				cursor = lastServed % count + 1
			end
			return due
		end,
	}
end

return ProducerScheduler
