# Medieval courtyard and practice obby

## Approved design
Improve the existing six optional additions, preserving prices/unlock order and the
exact cloned red/green dropper purchase plates with black rims. Standing equipped
sword points upward; existing swing/cooldown remains non-damaging.
Sword stand follows the creator's supplied reference: timber counter, tall side
posts, gold Sword Stand sign, displayed blades, and a static clone of the existing
StarterFarm.Scenery.Farmer behind the counter.
Paddock keeps its enclosure, shelter and entrance; two recognizable low-poly
horses replace primitive silhouettes, with six bound hay bales and a timber trough.
Fountain moves near local (10,-32), with plaza benches and planters. Banners move
to (40,-8) to clear it.
SprintTraining becomes a low medieval obby: hay steps, spruce firewood crossing,
a narrow beam and plank platforms. Sprint still unlocks immediately on purchase.
No changes to the other agent's Shift hold/double-tap sprint or R camera behavior.

## Asset contract / installation
First install the original optional additions and plate repair. Prepare an approved
script-free Model named ServerStorage.MedievalHorseTemplate, then run the authored
tools/ReworkMedievalCourtyard.luau in Edit. It refuses reinstallation and archives
the affected originals in ServerStorage.MedievalCourtyardBackup_20261118.
Only TrainingSword, HorsePaddock, RoyalFountain, RoyalBanners, SprintTraining and
their affected plate positions are revised. Vegetation and production are untouched.
For a new installation run BuildOptionalAdditions, RepairOptionalPurchasePlates if
needed, then ReworkMedievalCourtyard. Runtime code only clones these Studio assets.

SprintTraining.PrimaryPart is its invisible Origin at local (70,0,35), and
FallRootY=4.2 is measured relative to that pivot. CourseZones contains anchored,
invisible, noncolliding Start, Checkpoint1..3, Finish, Bounds parts. Zone volumes
must contain the standing HumanoidRootPart over each corresponding platform.
Ground-level root contact must be below FallRootY. Platforms remain above it.
Start faces -Z; checkpoints2/3 face +Z for recovery.
Course footprint32x40; start (64,49), checkpoints (64,23)/(76,23)/(76,44),
finish (76,51). Sprint purchase plate moves to (70,61).
Fountain plaza36x36, center (10,-32), plate (10,-9); banners plate (28,-8).
All coordinates relative to the kingdom's existing pivot. No mappings change.

Rollback: archive only the revised model/plate pairs and sword; restore matching
originals from the backup without restoring a whole old template. Preserve all
other agents' changes. Revert course registration/config/runtime alongside assets.

## Runtime and security
TrainingCourseService validates living ownership, SprintTraining purchase, current
kingdom/reset/entry state, and actual root position. No client coordinates,
checkpoint indices, times or rewards are accepted.
The server polls authored zones every0.1seconds, tracks ordered checkpoints,
and recovers falls to the last earned checkpoint while elapsed time continues.
A ground check precedes checkpoint awards. Recovery is limited to once/0.8seconds.
Finish requires all3checkpoints. Server-owned CourseActive/Started/Checkpoint/
Best/Result attributes drive client-only timing UI.
Menu cancellation uses KingdomTrainingCourse.Menu with exactly one boolean;
it can only cancel the sender's run. Opens cancel immediately, closes are retained.
Death, seating, leaving bounds, modal menus or120seconds cancel the run.
Best survives death/cancel but clears on kingdom release/rebirth or departure.
No saved schema, economy rewards, NPC AI, PvP or riding is added.

Performance: bounded10Hz checks per claimed kingdom; no per-frame server callback.
Static scenery/horse meshes add rendering cost; triangle/part counts and actual
verification are recorded below once installed.

## Studio verification
Normal Mock only. For hands-on scenery, set Server attribute
StudioCourtyardPreview=true before Play, then press Play at the startup menu.
Expect Medieval courtyard preview ready (Studio Mock; all scenery, sword and
training owned). It supplies100000Gold, restores first-Mint prerequisites,
starts production, and grants all optional models for inspection.
StudioGrantGold uses the existing TutorialPreview grant listener.
Clear preview attributes after stopping; never save them as production defaults.

Enable only TrainingCourseConfig.RUN_TESTS_IN_STUDIO alongside this explicit
preview for course integration checks. Expect:
- All medieval course state checks passed
- All medieval course service checks passed

The engine suite exercises start, early finish rejection, checkpoint order,
ground-level checkpoint rejection, fall return without timer reset, finish, retry
and menu cancellation retaining best. Reset the test switch afterward.
Manually traverse every jump using normal jump/sprint settings; check native
falls, checkpoint facing, sign visibility, equipped sword orientation, stand/horse
appearance, plaza walking clearance, purchase restoration and rebirth cleanup.

## Verification and saved assets (2026-11-18)
Generated horse model asset90054557348148 is stored as MedievalHorseTemplate.
It contains7mesh parts; each clone is anchored/noninteractive, with no scripts.
The generated front-right-leg texture71593976060416 failed runtime loading; use
the matching left-front-leg texture100252241141730 on that leg. The base generation
and all other textures are retained. Rework recipe applies the same fallback.
tools/PolishMedievalCourtyard.luau is a repeat-safe companion for the installed
revision: vendor faces customers, course sign has timber supports, texture fallback.
Saved courtyard asset revision to cloud version150 with test switches false and
preview attributes cleared. No publishing/pushing performed by this task.

Observed normal Mock Play:
- All medieval course state checks passed.
- All medieval course service checks passed, including ordered checkpoints,
  early-finish rejection, ground contact not advancing checkpoint, fall recovery
  preserving start time, finish/session-best, retry and menu cancellation.
- Actual R15 equipped sword Blade.UpVector.Y exceeded0.999 at rest and after a
  client Tool:Activate() round trip (SwingSerial incremented). Initial snapshots
  before the equip pose settled were misleading; settled orientation is upright.
- Close-up stand, paddock and course screenshots reviewed. Farmer was corrected
  to face the customer using the authored eyes' +Z direction.
- Full src Selene, StyLua and Rojo build passed. Strict Luau-LSP has only existing
  nullable Frame diagnostics in PlatePresentation; no new course-file diagnostics.
- Independent review found menu-close and ground-checkpoint edge cases; both fixed.
- Sprint commit ec1104f and acceptance notes5476321 were preserved. No edits to
  sprint/camera modules, tuning or current bindings (R camera, Shift sprint).
- Main shared checkout was switched by the leaderboard agent; task-only hunks
  committed there without staging the leaderboard/pixel UI work.
- Backup has both model and plate originals with matching IDs; select original
  by class (Model versus BasePart), never blindly restore a same-name child.
- Still requires creator acceptance: all jumps at normal movement settings,
  visual scale/spacing, touch/gamepad/narrow windows, and multiplayer/rebirth
  course reset. Automated integration teleports between zones to isolate logic.
