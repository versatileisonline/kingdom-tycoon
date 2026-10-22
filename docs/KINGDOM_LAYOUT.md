# Full-platform kingdom and front farm

Approved revision, 2026-10-21. The entire 320 × 320 grass platform is now one
player's kingdom plot. Step on Claim Kingdom, then Start Farm — FREE. One player
can own one kingdom at a time. Activation is session-only for milestone 1.4;
the general purchase/dependency system remains 1.5. No walls, kingdom interior,
upgrades, or saved-schema changes are included.

## Layout

Ground center is world (1400, 40, 0). Local +Z is the front/bottom of the reference
screenshot. The template pivot matches the plot Origin at ground height.

| Item | Size / local coordinates |
| --- | --- |
| Owned platform | 320 × 320; X/Z -160…160 |
| Future wall reservation | 216 × 216; X -108…108, Z -140…76 |
| Future gate | Center (0, 0, 76), 24-stud opening |
| Main path | 16 wide, Z 76…160 |
| Farm grounds | 112 × 48; X -136…-24, Z 100…148 |
| Farm branch | 10 wide, X -24…0 at Z 118 |
| Claim plate | 6-stud circle at X 0, Z 148; 6.6-stud black outer rim |
| Start plate | Matching circle at X -16, Z 118 |
| Arrival spawn | X 0, Z 184, on a 28 × 40 approach platform |
| Claimed spawn | X 0, Z 136, before the farm turnoff |

Keep future wooden and stone walls, towers, and gate details inside the reserved
footprint. The farm has a 24-stud clearance from that reservation; fence posts
extend 0.35 studs past the farm ground. Keep the gate/path centerline fixed so
wall upgrades require no farm move.

```text
                    BACK
 +------------------------------------------+
 |    +--------------------------------+    |
 |    |     FUTURE WALLED KINGDOM       |    |
 |    |        Empty for now            |    |
 |    +------------- GATE --------------+    |
 |                     |                    |
 |       Clear strip along wall line         |
 | +----------------+  |                    |
 | | Crops   Crops  |  |                    |
 | | Shed   Farmer  |--[START FARM — FREE]    |
 | |        Dropper |  |                    |
 | +----------------+  |                    |
 |               [CLAIM KINGDOM]             |
 +---------------------|--------------------+
                       ↑
               Arrival approach/spawn
```

The farm has two 24 × 20 crop beds, an open 20 × 16 shed, low fencing with a
12-stud entrance, a static farmer mannequin, and the existing rig moved together
without scaling. CollectPlate uses the same 6-stud circle. WheatBundle was resized to match the
currently resized conveyor. The original source and bundle are preserved.
Crops, shed, and farmer are scenery; there is no NPC AI or extra income source.
The farmer now stands in front of the dropper toward the arrival side, aligned
with DropPoint instead of standing on the left. Its feet and rotation were
preserved. Two additional droppers are planned to the left; they are not built
in this pass, and field/fence clearance must be checked when adding them.

All three plates use SmoothPlastic, a 0.4-stud-thick colored cylinder and a
noninteractive black Outline cylinder underneath. Config.PLATES defines the
6-stud diameter, 0.3-stud rim, and colors. Available is bright green; unavailable
is red. The claim plate is green while unclaimed and red while owned. The free
start plate is green after claim, then disappears with its outline after use.
The collector is red with zero uncollected Gold and green with any positive
balance. Successful collection returns it to red; a failed credit preserves the
balance and green color. Free plates do not require saved Gold. Colors communicate
shared plot/farm availability; ownership and distance are still checked on the
server, so a visitor cannot use a green owner-only plate.

## Asset contract

```text
Workspace
  KingdomMap (Model)
    ArrivalApproach (anchored Part)
    ArrivalSpawn (enabled neutral SpawnLocation; Duration = 5)
  Plots (Folder)
    Plot01 (Model; unique PlotId = "Plot01"; PrimaryPart = Origin)
      Origin (anchored, invisible, noncolliding Part)
      Ground (anchored 320 × 2 × 320 Part)
      PlateauRock
      ClaimMarker (anchored floor Part; CanTouch = true)
        Outline (anchored black cylinder; no collision/touch/query)
        ClaimLabelGui
          ClaimLabel (TextLabel)
      ... original perimeter trees
  ActiveKingdoms (Folder; empty in Edit mode)
ServerStorage
  KingdomTemplate (archivable, anchored, script-free Model)
    TemplateRoot (PrimaryPart; invisible, noncolliding)
    SpawnPoint (enabled neutral SpawnLocation; Duration = 5)
    Paths (Model)
    OwnerSign
      OwnerLabelGui
        OwnerLabel (TextLabel)
    FarmStartPlate (direct anchored Part; CanTouch = true)
      Outline (matching noninteractive black cylinder)
      StartLabelGui
        StartLabel (TextLabel)
    LayoutReservations (Folder; local design attributes)
    StarterFarm (direct Model)
      DropPoint (direct anchored, invisible, noncolliding Part)
      Conveyor (direct anchored, collidable Part)
      CollectionPit (direct anchored, noncolliding Part)
      CollectPlate (direct anchored Part; descendant EarningsLabel)
        Outline (matching noninteractive black cylinder)
      ... existing working rig parts
      Scenery (Model; fields, farmer, shed, fences, farm ground)
  WheatBundle (single archivable, script-free BasePart)
  KingdomLayoutBackup_20261021 (Folder; original assets)
    KingdomMap
    Plots
    KingdomTemplate
    WheatBundle
```

Required farm Parts stay direct children of StarterFarm; do not add a Machinery
folder around them. EarningsLabel and OwnerLabel may be nested. Conveyor's
LookVector points toward CollectionPit. Preserve invisible drop/pit settings.
LayoutReservations stores WallCenter, WallFootprint, GateCenter, GateWidth,
FarmCenter, and FarmFootprint; these attributes reserve space without building
visible walls or implementing unlock logic.

## Runtime lifecycle

PlotService resolves the character from a plate touch and reuses server checks
for data readiness, living character, distance, cooldown, plot availability, and
one-kingdom ownership. Owned plots ignore further touches using the private
registry. The reusable plate keeps CanTouch true: toggling it off can remove
Roblox's touch transmitter. No ProximityPrompt is required. See the
[CanTouch reference](https://create.roblox.com/docs/reference/engine/classes/BasePart#CanTouch).

On claim, FarmService prepares a private farm record and detaches StarterFarm
from the clone before gameplay yields. That record retains the unparented Model;
no farm visuals, collision, or production are present in Workspace. Inactive
farms skip all production and overlap queries.

Only the owner can start that farm. TryStart checks current assignment, data
readiness, living character, distance from the start plate, cooldown, and inactive
state. Without yielding, it marks the farm started, restores its parent, starts
production/collection, disconnects activation, and hides/disables the plate and
label. Repeated touches create no extra producers. No Gold is deducted.
StarterFarmStarted attributes on the player/kingdom supply guidance only;
the private farm record decides activation.

Existing tuning remains one bundle every three seconds, one Gold per arrival,
12-bundle cap, 20-second expiry, and owner-only collection via DataService.Update.
Death preserves activation and earnings. Release disconnects pending/active
listeners, destroys the retained Model even if never started, clears earnings
and activation state. Reclaim requires a fresh start. Activation is not yet a
saved purchase, and there is no offline production.

## Editing, copying, and rollback

`tools/BuildKingdomLayout.luau` is the approved one-time Edit-mode recipe. It
requires the old scene and refuses a second run when its backup exists. It builds
replacements before archiving originals without deletion. The source's edited
scale/pivot are retained in the backup. The unrelated castle, terrain, and scene
folders are unchanged. No Rojo mappings changed.

`tools/RefineFarmPlates.luau` is the subsequent one-time plate/farmer refinement.
It preserves the prior template and ClaimMarker in
ServerStorage.PlateRefinementBackup_20261021, refuses a second run, preserves each
plate's surface height, and returns KingdomTemplate to ServerStorage before Play.
It does not move the working conveyor, pit, or drop point. This refinement adds
one static outline Part per plate and no new runtime loop/connections.

The stored farm is intentionally invisible in Edit mode. To decorate it, move
the stored KingdomTemplate temporarily to Workspace while not playing, then
return it to ServerStorage before Play. Preserve TemplateRoot's pivot and move
StarterFarm as a whole Model. Do not leave an extra visible preview in Workspace.
Edit scripts on disk and sync through Rojo.

The installation has one full-size plot. After verifying it, duplicate the entire
Workspace.Plots.Plot01 Model, move it as a unit, and give both its name and PlotId
a unique value (e.g. Plot02). Origin is its PrimaryPart, so ground, trees, and
claim plate move together. Start with 360–400 studs between centers and verify
terrain/access. Reuse the single KingdomTemplate; it is positioned relative to
each Origin when claimed. Place counts are read dynamically.

For rollback, stop Play and archive replacements separately first. Restore the
backup's KingdomMap and Plots to Workspace, its KingdomTemplate to the recorded
OriginalTemplateParent, and WheatBundle to ServerStorage. Old behavior also
requires reverting this revision's source changes: the old prompt layout is not
the new touch-plate contract. Never overwrite existing names or delete backups.

Save the Studio place to retain the new assets and backup. Rojo builds export
code only, not the Studio map.

## Verification

Keep Mock mode and all test switches false for hands-on acceptance:

1. Play: arrive facing the claim plate; no farm or kingdom interior is visible.
   PlotService should print `Ready (1 plots)`.
2. Claim: expect `Claimed Plot01 for <userId>` and
   `Starter farm awaiting activation for <userId>`. The start plate appears.
   Wait over three seconds: no wheat, Gold, or activation log yet.
3. Start: expect `Activated starter farm for <userId>` once. The farm appears
   and the start plate/label disappear. Repeated touches cannot duplicate it.
4. See wheat enter the pit and its displayed total rise. Step on the collector:
   expect `Collected <amount> Gold for <userId>` and the display resets.
   Check red at zero, green above zero, then red after collecting. All plates
   should be matching small circles with black rims. Starting the farm must hide
   both the green face and its black outline. Claim changes green to red, and
   departure restores green. Color changes add no per-tick Output messages.
5. Reset: respawn near the entrance with five seconds of native protection;
   farm activation and uncollected earnings persist.
6. Two clients: only one can claim this plot. Visitors cannot start the owner's
   farm or collect earnings. Owner departure releases it; a new claim requires
   a fresh farm start. Also test departure before activation.
7. Stop: expect `Final save confirmed for <userId> (Mock)` and Edit mode.

The optional FarmConfig.RUN_TESTS_IN_STUDIO suite now checks no auto-start,
distant start rejection, release before activation, one-time activation,
production, collection/failure retention, and fresh reclaim. Run it before manual
claiming, with data/plot suites disabled. It restores original Gold/position and
prints `All farm accounting checks passed` and `All farm-service checks passed`,
plus an intentional retained-collection warning. Reset the switch afterward.
PlotServiceTests also uses the plate contract. Native touches and multiplayer
acceptance still require hands-on Play; these checks are not claimed as run.

Performance: scenery is static, with no farmer AI or server frame loop. Each
started farm keeps its existing 12-bundle physics cap. Pending farms retain one
bounded Model in server memory without production or overlap queries.

Agent verification: installed hierarchy, anchoring/script-free template, farm
bounds, belt direction, bundle fit, spawn facing, and original backup passed.
StyLua, Selene (zero errors/warnings), strict Luau-LSP with Roblox definitions,
the code-only Rojo build, module loading, and Edit-mode accounting checks passed.
Rojo sync was confirmed. Studio was left in Edit mode with no preview copy,
Mock mode and all test switches unchanged. Full Play suites were not run.

Suggested commit: `feat: redesign full-size kingdom plot with farm activation plate`.
