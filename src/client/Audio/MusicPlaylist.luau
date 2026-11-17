--!strict
-- Session-local circular selection. Unavailable assets are skipped until restart.
local MusicPlaylist = {}
export type Playlist = {
	Next: () -> number?,
	Fail: (number) -> (),
}
function MusicPlaylist.new(ids: { number }): Playlist
	local tracks = table.clone(ids)
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
