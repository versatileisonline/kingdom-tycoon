# Kingdom music: shuffled session playlist

The creator approved replacing the previous court/ambient/battle rotation with
Dungeon Quest and two stronger medieval companions on 2026-11-18. All three were
returned as free (price 0) by Creator Store search. Catalog availability does not
prove runtime permission or listening acceptance.

| Role | Track | Creator | Asset ID |
| --- | --- | --- | --- |
| Chosen reference | [Dungeon Quest](https://create.roblox.com/store/asset/115384070099102) | DistrokidOfficial | 115384070099102 |
| Medieval orchestral | [The Rise of Kings](https://create.roblox.com/store/asset/128045338895178) | DistrokidOfficial | 128045338895178 |
| Medieval companion | [Viking Invasion](https://create.roblox.com/store/asset/100085318455652) | DistrokidOfficial | 100085318455652 |

## Behavior

HudConfig.MUSIC_IDS owns the three tracks. MusicPlaylist.new(ids, random?) clones
the list and shuffles it once with Fisher–Yates. The optional Random instance lets
tests reproduce an order; normal startup uses a fresh Random.new(). Each client
has its own order, which repeats after every playable track has played. Startup
may legitimately select the same first song as the previous session. There is no
saved order or cross-player synchronization. AudioController keeps
one local KingdomBackgroundMusic Sound under SoundService, plays each song once,
and advances on Sound.Ended. After the third song it returns to its first.
Settings music volume and mute still scale the independent KingdomMusic group;
world audio routing and authored sound groups retain their existing behavior.
No new UI, remotes, saved preferences or Studio assets are required.

An asset that does not load within the configured 12-second timeout is skipped
for the rest of this controller session. If every track fails, playback stops
with Background music unavailable instead of retrying forever. Shutdown disconnects
Ended and existing observers, destroys owned audio, and makes any pending loader
obsolete. A subsequent Start receives a fresh playlist and fresh Sound.

## Verification

MusicPlaylistTests.Run(Playlist) accepts the pure client Audio.MusicPlaylist module,
like the existing HudState tests accept their state module. It tests deterministic
seeded shuffles, all three possible starting tracks across fixed seeds, exactly
one appearance per cycle, unchanged frozen input, wrap, skipping failed tracks,
bounded exhaustion, session isolation, empty lists and one remaining track. Expect:

`All music playlist checks passed`

For actual audio, use normal client startup in the intended Studio place. Expect
`[KingdomTycoon][AudioController] Music loaded: <asset ID>` with one of the three
new IDs initially. Let each finish: all three should play before the first repeats.
Restart several times to observe varied starts; do not require consecutive starts
to differ.
To verify advancement quickly in a temporary Play session, seek the local
KingdomBackgroundMusic.TimePosition near TimeLength and let native Ended fire;
do not call private controller functions or spoof the signal.

Run existing HUD client volume/mute and world-group preservation checks separately.
Check all three assets actually load in this experience; Creator Store availability
alone does not prove runtime permission or aesthetic acceptance. The search did
not include a listening review. Formatting, lint and strict Roblox types are
checked independently of playback.

Current change verification (2026-11-18): the expanded suite failed against the
old ordered implementation, then passed with startup shuffling in Studio's native
Luau runtime. StyLua, Selene (zero errors/warnings), Rojo build and independent
code review passed. New-track playback and native transitions are checked
separately from these pure selection tests.

Native integration (2026-11-18): startup selected Viking Invasion, then seeking
near each ending let native Sound.Ended advance to The Rise of Kings, Dungeon
Quest, and back to Viking Invasion. All three were checked IsLoaded=true and
IsPlaying=true; the cycle contained each ID once. The live music gain remained
0.25 during transitions. Native Settings slider input changed the gain near zero
and restored it to approximately 25% (0.2513); the panel was closed afterward.
Exact-zero mute was not established by the automated drag and remains a manual
acceptance check. Direct SettingsController.Set from the MCP execution context
did not update the live controller's SoundGroup, so it was not used as volume
verification evidence. No production volume behavior was changed. Listening
preference remains with the creator; these checks establish asset permission and
playback, not an auditory review.

## Historical verification: superseded playlist (2026-11-17)

The results below apply only to the old IDs 139186694323000, 87479584695420,
and 137177134668386, not the replacement tracks.

Runtime asset check (2026-11-17): all three old IDs loaded successfully in the intended
Kingdom Tycoon client using temporary muted Sounds. Reported lengths were
224.60 seconds (Royal Court), 207.80 seconds (Ravensmoor Keep), and 189.44 seconds
(Medieval Battle Blaze). This establishes loading permission, not a listening review.
Initial native transition testing found that the next ID loaded but remained
stopped when Play was issued before the new asset finished loading. AudioController
now waits for IsLoaded, resets playback position, and then calls Play. Native
transition recheck and HUD volume checks remain pending integration.

Native integration (2026-11-17): after the load-before-Play correction, seeking
each playing track near its end caused real Sound.Ended events to advance through
Ravensmoor Keep, Medieval Battle Blaze, and back to Royal Court. Every successor
was checked IsLoaded and IsPlaying=true; music group gain remained 0.25. This
verifies real playback transitions rather than calling private methods or firing
signals. All three tracks loaded in the intended experience. Listening preference
and long-session acceptance remain with the creator.

Existing normal-bootstrap HUD presentation/client suites passed after the music
change, including independent music/world mute and preservation of authored sound
groups. Final place saved version 85 in Edit with all tests disabled. The three
songs are the free Creator Store versions linked above; no original television
soundtrack asset was used.
