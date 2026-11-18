--!strict
local Tests = {}
-- Pure selection tests; callers provide the client module just like HudStateTests.
function Tests.Run(Playlist: any): ()
	local source = table.freeze({ 11, 22, 33 })
	local starts: { [number]: boolean } = {}
	for seed = 1, 30 do
		local seeded = Playlist.new(source, Random.new(seed))
		local sameSeed = Playlist.new(source, Random.new(seed))
		local seen: { [number]: boolean } = {}
		local cycle = {}
		for index = 1, #source do
			local id = seeded.Next()
			assert(id ~= nil and table.find(source, id) ~= nil, "Shuffle introduced an unknown track")
			assert(not seen[id], "Shuffle repeated a track before completing the cycle")
			seen[id] = true
			cycle[index] = id
			assert(sameSeed.Next() == id, "Seeded shuffle is not deterministic")
		end
		starts[cycle[1]] = true
		for _, id in cycle do
			assert(seeded.Next() == id, "Playlist did not repeat its shuffled cycle")
		end
	end
	assert(starts[11] and starts[22] and starts[33], "Startup shuffle never selected some tracks first")
	assert(source[1] == 11 and source[2] == 22 and source[3] == 33, "Shuffle mutated the source")
	local playlist = Playlist.new(source, Random.new(42))
	local first, second, third = playlist.Next(), playlist.Next(), playlist.Next()
	assert(first ~= nil and second ~= nil and third ~= nil, "Playlist lost tracks")
	playlist.Fail(second)
	assert(playlist.Next() == first, "Playlist did not wrap")
	assert(playlist.Next() == third, "Unavailable track was retried")
	playlist.Fail(first)
	assert(playlist.Next() == third, "Remaining playable track skipped")
	playlist.Fail(third)
	assert(playlist.Next() == nil, "All failed tracks should stop")
	assert(playlist.Next() == nil, "Failed tracks caused unbounded retries")
	local independent = Playlist.new(source, Random.new(42))
	assert(independent.Next() == first, "Failed tracks leaked to another session")
	assert(Playlist.new({}).Next() == nil, "Empty playlist should stop")
	local one = Playlist.new({ 11 })
	assert(one.Next() == 11, "Single track not selected")
	assert(one.Next() == 11, "Single playable track should loop")
	print("All music playlist checks passed")
end
return Tests
