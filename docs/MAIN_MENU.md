# Kingdom Awaits startup menu

Every join opens a dark, blocky menu with pixel lettering, gold/brass edging,
Play and Settings. Existing session preferences and medieval music remain.
Background artwork/castle panorama and broader project renaming are deferred.
No external assets or changes to Studio templates/Rojo mappings are required.

## Behavior and architecture

MainMenuConfig owns title, sizing, cooldown, timeout and placement constants.
MainMenuController/View run before gameplay HUD creation. MainMenuOpen is a
client presentation flag distinct from MenuOpen (the existing Settings dialog).
Settings overlays the backdrop; closing it returns to Play. Shop, Rebirth,
Gold, hints and stamina are hidden before entry. The normal gameplay camera
resumes after entry; respawning does not reopen the menu.

EntryService owns player KingdomEntered, initially false. The live character's
root is temporarily anchored, including replacement characters before entry.
The client requests only the literal Play action using KingdomEntry.Request;
KingdomEntry.Result returns success and a user-facing message. The server checks
profile/character readiness, limits requests and duplicate replies, and publishes
KingdomEntered=true only after placement. The client timeout permits retry;
duplicate successful requests acknowledge without teleporting again.

PlotService.TryEnter shuffles currently free plots, tries three 12-stud offsets
beside each ClaimMarker, raycasts to walkable ground and checks a 4x5x4 clearance
box. It faces the character toward the plate and clears assembly velocities.
No ownership, reservation, template clone or saved-data write occurs. Claim
plate touches are ignored before entry; the server-only TryClaim method remains
usable by existing test fixtures. On Play success players can roam or touch Claim,
then use Start Farm as before. Claimed-kingdom respawn behavior stays unchanged.

No free plot or no clear grounded arrival produces a visible retry message and
a server warning rather than an unhandled exception. Multiple entrants can be
sent beside the same free plot; owning land still requires touching its plate.

## Verification

Enable only MainMenuConfig.RUN_TESTS_IN_STUDIO in Studio Mock and Play before
claiming. Server checks restore the character's original position afterward.
Expected Output:

- All main menu entry checks passed
- All main menu placement checks passed
- All main menu client checks passed
- [KingdomTycoon][MainMenuController] Menu ready

Reset the switch to false after stopping. For normal manual verification:

1. Join: title reads KINGDOM AWAITS, buttons read PLAY/SETTINGS; no gameplay HUD.
2. Open Settings, adjust music/helper arrow, close: return to main menu.
3. Press Play: arrive beside a free plate, not touching it or owning the plot.
   Output includes Entry placed <userId> beside <plot> (unclaimed), followed by
   [KingdomTycoon][MainMenuController] Entered game.
4. Walk elsewhere, then touch Claim. Ownership and farm tutorial should work.
5. Reset character after entry: normal respawn, no startup menu.
6. In a separate Mock fixture with every plot occupied, entry stays on the menu
   and reports No free tycoon is available. Please retry. Release a plot and retry.
7. Check narrow phone/landscape layouts and gamepad selection, replacement
   characters while menu is open, double clicks, and returning saved progress.

## Capacity and limits

Current connected Studio scene has one plot and StreamingEnabled=true. Set the
published server's player limit no higher than installed full-size plots; this
change does not alter publishing settings or duplicate land. The placement
algorithm runs on server geometry; streaming does not determine availability.
A dedicated scenic camera/streaming policy is deferred with the background work.
There is no server per-frame menu loop; client rendering updates camera ownership
and readiness only while the menu is visible. Cleanup releases connections and
restores camera/HUD presentation.

## Verified in this implementation

Studio Mock entry policy, actual placement and client view suites passed. Physical
mouse Settings/close/Play restored the HUD and camera, server readback confirmed
KingdomEntered=true, unanchored root and no ownership; walking to Claim assigned
Plot01. Death afterward respawned normally without reopening the menu. Existing
PlotServiceTests passed in a separate bootstrap run, including actual respawn.
selene src and Rojo build passed; the pure request policy also passed Luau CLI.

Physical mobile/gamepad and multi-player/full-server tests remain hands-on. Studio
Output also reports pre-existing asset203785492 type mismatch messages and an
Assistant plugin version warning; these are outside the menu change. Test switches
were restored to false after verification.
