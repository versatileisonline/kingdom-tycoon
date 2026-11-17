--!strict
local Tests = {}
-- Pure selection tests; callers provide the client module just like HudStateTests.
function Tests.Run(Playlist: any): ()
	local playlist = Playlist.new({ 11, 22, 33 })
	assert(playlist.Next() == 11, "First track not selected")
	assert(playlist.Next() == 22, "Ended track repeated instead of advancing")
	assert(playlist.Next() == 33, "Third track skipped")
	assert(playlist.Next() == 11, "Playlist did not wrap")
	playlist.Fail(22)
	assert(playlist.Next() == 33, "Unavailable track was retried")
	playlist.Fail(11)
	assert(playlist.Next() == 33, "Remaining playable track skipped")
	playlist.Fail(33)
	assert(playlist.Next() == nil, "All failed tracks should stop")
	assert(playlist.Next() == nil, "Failed tracks caused unbounded retries")
	local independent = Playlist.new({ 11, 22, 33 })
	assert(independent.Next() == 11, "Failed tracks leaked to another session")
	assert(Playlist.new({}).Next() == nil, "Empty playlist should stop")
	local one = Playlist.new({ 11 })
	assert(one.Next() == 11, "Single track not selected")
	assert(one.Next() == 11, "Single playable track should loop")
	print("All music playlist checks passed")
end
return Tests
