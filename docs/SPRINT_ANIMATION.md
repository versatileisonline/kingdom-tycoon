# Sprint animation

## Evade-style replacement

The creator selected [Evade Animations v1](https://create.roblox.com/store/asset/74987847468722)
by wifonn3 and requested more sway. Its free script-free Run is authored for R6,
so the motion was adapted to R15 and exported by Studio to
assets/animations/evade-sprint-r15.rbxm. The published Animation is
**98098361982208**, owned by experience creator9916983918 and approved by Roblox.
SprintConfig.ANIMATION_ID now uses that permanent ID. No temporary hashes ship.

The adaptation preserves25 keys/0.65s, converts R6 joint axes, keeps R15 limb chains
connected and closes the loop exactly. Alternating torso roll is amplified around
its original center and distributed across pelvis/waist. Native measurements show
11.69 degrees of total torso roll versus7.42 for the previous run. Small elbow/knee
bends accommodate the R15 rig. Only the Run motion is reused; the source character,
walk/jump/fall/idle clips and controls are not installed.

Native fresh-Play checks confirmed the published clip loads and loops at full
Movement weight during24-stud Shift sprint. One sword567479941 Action track played
at full weight alongside one new run track, preserving the upper-body swipe and
lower-body stride. Existing jump/freefall animations took over while airborne;
release stopped the run and restored16-stud walking. Continuous circular movement
reported authoritative exhaustion and stopped the new track/restored walking.
An initial sword check ran before preview equipment was ready; after waiting for
the issued sword, the native readback confirmed both tracks at full weight.

Authoring checks assert the16-pose hierarchy, timing, priority, loop equality and
sway. See assets/animations/README.md for attribution, asset contract, owner asset
and rebuild steps. Formatting/Selene pass. Existing runtime controller, controls,
stamina, sword code, schema and Rojo mappings are unchanged. The upload used the
Open Cloud API after the creator approved the upload directory. No game publish.

Creator acceptance: inspect the feel of the stronger sway and transitions with
and without the sword. A two-client visibility test is still outstanding.
Normal Output stays `[SprintAnimationController] Ready (R15 sprint animation)`.
Authoring check Output: `All Evade R15 sprint asset checks passed`.

## Previous compatible fallback (historical)

Uses R15 run clip `507767714`, referenced by the free [Default Animate Script
(R15)](https://create.roblox.com/store/asset/13015609472) by RoiGipot. The animation
loads successfully in this experience (0.65-second loop). Creator Store search
exposes free results but no reliable trending rank; this is a compatible free
fallback, not a verified top-trending selection. Several other free sprint packs
referenced unavailable clips or replaced character controls and were rejected.
Only the animation ID is used. No imported scripts or temporary models remain.

SprintService publishes read-only `Player.Sprinting` from the existing authoritative
stamina state, only when it changes. SprintAnimationController uses that signal
and local grounded/moving/alive/menu/focus state. One looping Movement-priority
track per character fades over 0.15s, with playback speed scaled to motion. Jump,
fall, climb, swim, seating, death, menus and focus loss stop the track. Landing can
resume it while sprint remains active. Generation checks discard obsolete loads;
respawn and shutdown destroy the old track and disconnect character listeners.

The existing Animate script, sprint input modes, speed, stamina, purchase, saves
and remotes are retained. Sword Action priority overrides its keyed upper-body
joints while the sprint legs continue. No damage, physics assets, schema or Rojo
mapping changes. This adds no frame loop; it uses existing server stamina ticks
and client character/input/settings events. One boolean attribute transition is
replicated when sprint activates/deactivates.

## Verification

Native Studio Mock preview checks passed:
- Physical W + Left Shift: server Sprinting=true, WalkSpeed=24, exactly one loaded
  Movement run track at full weight, while existing Core locomotion stays enabled.
- Tool activation while running: one Action SideSwipe plus one Movement run.
- Space: sprint track yields to the default Freefall/jump animation.
- Shift release: sprint false, run stopped, WalkSpeed=16.
- Death/respawn: new character runs without stacked sprint tracks; release cleans up.
- Continuous circular movement on open ground: owner Status reported exhausted;
  sprint stopped and WalkSpeed returned to16. A straight-line exhaustion attempt
  through scenery was inconclusive because collisions interrupted movement.
- SprintAnimationTests gating checks passed; formatting, Selene and Rojo build pass.
- Strict analysis reports only the seven existing nullable Frame diagnostics in
  PlatePresentation; no diagnostics in the modified sprint files.
- Focused read-only review found no actionable correctness/lifecycle issues.

Expected normal Output: `[SprintAnimationController] Ready (R15 sprint animation)`.
In Client Command Bar, run:
```lua
local client = game.Players.LocalPlayer.PlayerScripts.Client
require(client.UI.SprintAnimationTests).Run(require(client.Movement.SprintAnimationState))
```
Expected: `All sprint animation state checks passed`.
The existing SprintConfig.RUN_TESTS_IN_STUDIO switch also runs these checks.
All test switches remain false by default.

Creator acceptance: inspect the look/stride with the upright sword, test double-tap
lock and landing, open/close each modal, and check a second client's view. Multiplayer
animation visibility has not been tested in a two-client session. Existing unrelated
asset203785492 type-mismatch warnings remain in preview Output.

## Replacement / rollback

SprintConfig owns animation ID, fade and reference speed. Replace only with a
permitted R15 clip and verify actual track.Length >0 under the experience owner.
Removing SprintAnimationController from the bootstrap disables this visual layer;
server stamina and sprint controls continue normally. No Studio model contract.
