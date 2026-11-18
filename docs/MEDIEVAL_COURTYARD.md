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
