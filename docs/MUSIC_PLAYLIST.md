# Medieval music rotation

The client cycles three tracks rather than looping the first available asset.
All three were returned as free (price 0) by the Roblox Creator Store audio search
on 2026-11-17. They are mood references for kingdom gameplay, not tracks from the
Game of Thrones soundtrack.

| Mood | Track | Creator | Asset ID |
| --- | --- | --- | --- |
| Court | [Royal Court Background Music](https://create.roblox.com/store/asset/139186694323000) | DistrokidOfficial | 139186694323000 |
| Calm kingdom | [Ravensmoor Keep (Peaceful Medieval Ambient)](https://create.roblox.com/store/asset/87479584695420) | DistrokidOfficial | 87479584695420 |
| Dramatic medieval | [Medieval Battle Blaze](https://create.roblox.com/store/asset/137177134668386) | DistrokidOfficial | 137177134668386 |

## Behavior

HudConfig.MUSIC_IDS owns the ordered three-track rotation. AudioController keeps
one local KingdomBackgroundMusic Sound under SoundService, plays each song once,
and advances on Sound.Ended. After the third song it returns to the first.
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
like the existing HudState tests accept their state module. It tests ordered
advancement/wrap, skipping failed tracks, bounded exhaustion, session isolation,
empty lists and a single remaining playable track. Expect:

`All music playlist checks passed`

For actual audio, use normal client startup in the intended Studio place. Expect
`[KingdomTycoon][AudioController] Music loaded: 139186694323000` initially; when it
finishes, expect IDs 87479584695420, then 137177134668386, then the first ID again.
To verify advancement quickly in a temporary Play session, seek the local
KingdomBackgroundMusic.TimePosition near TimeLength and let native Ended fire;
do not call private controller functions or spoof the signal.

Run existing HUD client volume/mute and world-group preservation checks separately.
Check all three assets actually load in this experience; Creator Store availability
alone does not prove runtime permission or aesthetic acceptance. The search did
not include a listening review. Formatting, lint and strict Roblox types are
checked independently of playback.

Runtime asset check (2026-11-17): all three IDs loaded successfully in the intended
Kingdom Tycoon client using temporary muted Sounds. Reported lengths were
224.60 seconds (Royal Court), 207.80 seconds (Ravensmoor Keep), and 189.44 seconds
(Medieval Battle Blaze). This establishes loading permission, not a listening review.
Native end-to-next-track and HUD volume checks are performed during integration.
