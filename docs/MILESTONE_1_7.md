# Milestone 1.7: HUD and session settings

A compact brown/gold HUD replaces the large claim instruction card. Gold is at
lower left; Settings is upper right below Roblox controls. Settings uses rounded
brown panels, cream type, muted gold outlines and gold active states. One short
contextual hint disappears after collection. Purchase plates remain unchanged.

## Architecture

DataService.ObserveAvailability(callback) reports readiness/session closure;
ObserveUpdates continues reporting committed mutations. PresentationService subscribes
before reconciling existing players, publishes Gold/GoldReady attributes, and clears
readiness when data becomes unavailable. HUD attributes are read-only presentation:
only DataService mutations affect purchases or saved Gold. No request remotes or
schema changes. Player Gold is public presentation state, like the future leaderboard.

Client SettingsController owns Music, WorldSounds, HelperArrow, LowGraphics, and
MenuOpen. Settings last for this session and survive respawn; new sessions reset.
Volume is clamped to 0–1; invalid keys, types, NaN, and infinity are rejected.
HudConfig holds defaults, palette, audio candidates, and disabled Studio test switch.
Defaults: music 25%, world 100%, helper on, low graphics off.

HudView creates native Roblox UI (no uploaded image or complex asset dependency).
Sliders support pointer/touch dragging and keyboard Left/Right increments. Settings
closes with ×, outside click, or Escape. Panel width caps at 420 with narrow-screen
margins; UIScale fits short viewports. Gold uses exact comma-separated numbers and
shows — while loading. HudController, PlotController, and PurchaseGuidanceController
consume presentation/settings events; there are no polling UI loops.

AudioController plays free Creator Store track **Medieval Castle**, APMOfficial,
asset 1839906422 (about 92 seconds), looped. This track loaded and played in the
intended experience. Fallback is free Royal Court Background Music, 139186694323000,
only if the first fails to load. Music has an independent SoundGroup. Ungrouped game
sounds use KingdomWorld. Already grouped sounds retain their authored groups/effects
and scale per-sound volume against its captured original. Cleanup restores volumes
and groups. Studio plugin sounds and voice-chat audio nodes are outside these roots.
The existing Rojo sound warning for 203785492 is unrelated to game music.

GraphicsController locally disables global shadows, post effects, particles,
trails and beams. Original values are restored when disabled or shut down. Newly
streamed effects are reduced while enabled; removed effects release their snapshots.
No gameplay geometry, wheat physics, server settings, or other players are changed.

CameraController uses Roblox's built-in rbxasset://textures/MouseLockedCursor.png
through UserInputService.MouseIcon while Shift lock actively controls the camera.
This replaces the initial custom overlay after the creator found it off-center.
The native engine positions the cursor. Original cursor/icon visibility are restored.
Settings, text entry, Roblox menus, death, window focus loss, and non-Custom cameras
suspend it. Camera offset/zoom/FOV remain unchanged. The existing client render
callback is reused; no server frame loop is added.

## Verification

Use the normal server/client bootstrap in Studio Mock mode. Enable only
HudConfig.RUN_TESTS_IN_STUDIO on disk, sync through Rojo, then Play. Expect:

- All HUD presentation checks passed
- All HUD client checks passed
- [KingdomTycoon][AudioController] Music loaded: 1839906422

Server tests check ready/committed Gold and prove presentation attributes cannot
credit authoritative data; original Gold is restored. Client tests check actual
settings UI, independent volume/mute, authored sound-group preservation, graphics
reduction/restoration including newly added particles, helper toggle and panel
open/close. Pure HudStateTests cover defaults, clamping, type/NaN rejection, session
isolation, unavailable Gold and comma formatting. Reset test switch afterward.

Run formatting, lint, strict Roblox Luau-LSP, and a code-only Rojo build. Run existing
data/farm/purchase suites separately. Live stores are not used for Studio checks.

Desktop viewport screenshots verified the compact badge and rounded settings panel.
Native Studio mouse input verified Settings open/close and low-graphics toggle.
The Studio key-input tool did not activate the existing Shift gate reliably, but
creator testing confirmed it works and identified the initial custom overlay's
centering issue. The final implementation uses the built-in locked cursor texture;
focused-window centering and typing/menu/death acceptance should be reviewed with
that final cursor. Keyboard slider increments and physical touch dragging still
need hands-on acceptance. The farm suite also passed in an iPhone 17 Pro landscape
simulation; the device simulator was reset to its default viewport afterward.

Settings/audio/graphics modules explicitly disconnect observers and restore owned
state on cleanup. Existing farm/plot performance caps remain unchanged.


## Integration verification (2026-11-16)

Pure state tests, HUD server/client suites, existing mock data-layer suite, full
farm accounting/service suite, and purchase suite passed separately. Tests restored
original data. Formatting, lint, strict Roblox analysis and code-only build passed.
Native locked-cursor texture preload returned Success. Cloud place saved as
**version 70**, Edit mode, all test switches false, default device viewport, no
runtime kingdoms. This was a save, not a publish. Final native-cursor centering
and keyboard/touch acceptance remain for creator review.
