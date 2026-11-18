--!strict
-- Shuffled once per session, then circular. Unavailable assets skip until restart.
local MusicPlaylist = {}
export type Playlist = {
	Next: () -> number?,
	Fail: (number) -> (),
}
function MusicPlaylist.new(ids: { number }, random: Random?): Playlist
	local tracks = table.clone(ids)
	local rng = random or Random.new()
	for index = #tracks, 2, -1 do
		local other = rng:NextInteger(1, index)
		tracks[index], tracks[other] = tracks[other], tracks[index]
	end
	local failed: { [number]: boolean } = {}
	local cursor = 0
	return {
		Next = function(): number?
			for _ = 1, #tracks do
				cursor = cursor % #tracks + 1
				local id = tracks[cursor]
				if not failed[id] then
					return id
				end
			end
			return nil
		end,
		Fail = function(id: number): ()
			failed[id] = true
		end,
	}
end
return MusicPlaylist
