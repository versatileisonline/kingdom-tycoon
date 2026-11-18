# Free R15 sword animation

Replaces the old grip-only tween with a real upper-body SideSwipe animation.
Source: [R15 Sword Animation Pack](https://create.roblox.com/store/asset/3083796281)
by UltraPugs484 (free). The script-free pack references LeftSlash567480700 (1s)
and SideSwipe567479941 (0.5s). SideSwipe is selected to fit the existing0.65s
cooldown. Current animation content loaded successfully in this experience.

EquipmentConfig defines SWING_ANIMATION_ID, ANIMATION_PRIORITY=Action and
ANIMATION_FADE=0.08. EquipmentService creates one track per issued sword on the
existing server Animator and reuses it. It stops/destroys tracks on unequip/death/
ownership removal/plot release/departure/shutdown. Upright REST_GRIP stays fixed.
The existing owner/equipped/living/reset/cooldown checks still authorize each swing.
No damage, hit detection, animation purchase, schema, remotes, or mapping changes.
Only the clip is reused; no third-party scripts are installed or executed.

Inspected clip keys target torso/head/arms, not legs. The current Animate script,
walking, sprint controls and jump animations are retained. Action priority blends
over the body joints it keys. Native walking Core tracks remained active during
the sword animation; a complete physical-key sprint/jump visual acceptance pass
remains a creator check.

## Verification
Config regression observed RED before the animation ID was added.
Native client Tool:Activate round trip confirmed SideSwipe length0.5,
Action priority, nonlooping playback, exactly one track, unchanged upright grip,
unchanged health, cooldown rejection, stopping on unequip and track reuse on reequip.
Expected Output: All free sword animation checks passed.
Run Client Command Bar in an owned-sword Mock preview:
```lua
require(game.Players.LocalPlayer.PlayerScripts.Client.UI.SwordAnimationClientTests).Run()
```
Server-side config helper: Tests.SwordAnimationTests.Config(EquipmentConfig).
Formatting/lint/build pass. Strict analysis retains only existing PlatePresentation
nullable Frame diagnostics, no new diagnostics in modified equipment files.

## Rollback / replacement
Change EquipmentConfig.SWING_ANIMATION_ID to another permitted R15 clip, and verify
loaded track length and visible movement in the published experience owner context.
Do not reintroduce the rotating-grip tween. Free Store availability does not by
itself establish that embedded animation IDs are permitted in every experience.
Imported pack was used only for inspection; runtime loads its referenced clip ID.
