# Stone stronghold

Approved 2026-11-18: 24-stud stone wall bodies (battlements above), continuous
six-stud-clear perimeter circulation, round corner archer lookouts, gate flags and
torches, owner-toggle lethal ward, four archers, eight walkers and two workers.
The earlier ten-character target was explicitly replaced by fourteen.

## Purchases and persistence

Optional sequence after RoyalMintUpgrader08: StoneWalls8000 → ProtectionDoor9000
→ ArcherPosts10000 → KingdomResidents12000 Gold. Only the next chain plate appears;
production and the six earlier independent optional offers remain independent.
PurchaseService retains the authoritative validated transaction. Stone ownership
unparents the runtime wooden enclosure; its saved ID remains owned. Release destroys
the retained wood. Reclaim restores stone without charging; rebirth removes all four.
No schema migration, new purchase remotes, dependencies or Rojo mapping changes.

ProtectionDoorService uses the current kingdom and committed ownership. The owner's
living character can operate the interior ProximityPrompt within10 studs, at most
once/second. Ward starts enabled on purchase/reclaim, survives owner death, and is
session-only. Amber45%-transparent ForceField-material art is noncolliding; it hides
when off. Sign and prompt derive from authoritative state. Touch plus a0.1-second
server character-root box scan detects entrants, never client-selected victims.
Owners and NPCs are exempt. Visitors receive lethal damage regardless of PvP status,
but existing ForceFields preserve spawn protection. No KO, bounty, currency reward
or banked-Gold penalty. This is the explicitly approved defensive exception to the
otherwise opt-in PvP and visual-only defenses rules.

## Asset contract and installation

Studio place77311816657817. Run tools/BuildStoneStronghold.luau in Edit, then
 tools/RefineStoneStronghold.luau exactly once. Both are unmapped Edit companions;
runtime never constructs the complex scenery. Original KingdomTemplate remains
intact under ServerStorage.StoneStrongholdBackup_20261118. Refinement lowers tower
rings to deck height, removes cardinal merlons obstructing connections, equips
script-free medieval props, clones two actual central-castle masonry parts as gate
caps, and adds gate flags/torches. Most geometry is newly authored reference-style
masonry; the central castle is unchanged. Refinement marks StrongholdRefined and
refuses a repeat. Build also refuses installation over existing assets.

Under ServerStorage.KingdomTemplate:
- PurchasePlates: StoneWalls, ProtectionDoor, ArcherPosts, KingdomResidents, cloned
  from RoyalMintDropper02, each with PurchaseLabel. Local positions(30/37/44/51,0.4,60).
- PurchaseUnlocks.StoneWalls: anchored masonry/wall-walk, corner decks, open arched
  gatehouse, two WallAccess trusses. Walls follow the existing enclosure; walkways
  extend toward the plot edges, avoiding production footprints.
- PurchaseUnlocks.ProtectionDoor: Barrier(BasePart), DetectionZone(BasePart),
  ToggleControl containing ProximityPrompt and WardSign.StateLabel(TextLabel).
- PurchaseUnlocks.ArcherPosts: four platform additions and Placements.Archer1–4
  invisible BaseParts giving rig pivots.
- PurchaseUnlocks.KingdomResidents: Placements.Worker1–2, supply crates, and
  Routes.Route01–08 folders with ordered01–03 invisible BasePart waypoint markers.
- ResidentTemplates.Archer/Worker/Villager: script-free R15 Models with Humanoid,
  Animator, HumanoidRootPart and welded props. Every stored part is anchored.
  Runtime clones unanchor moving rigs and retain anchored roots for stationary rigs.

No imported runtime scripts. Template copies under active kingdoms are removed by
KingdomResidentsService; authoritative sources remain in ServerStorage.

## Population and performance

Maximum14 rigs per kingdom: four stationary archers and two stationary workers with
idle animations, eight walkers at6studs/sec. Walkers traverse short authored routes,
pause2seconds, stagger departure, and recover to their own safe first waypoint after
a9-second movement timeout. Humanoid MoveTo completion drives AI, with a bounded
watchdog; no per-frame server AI or continuous pathfinding. Server owns moving NPC
physics. NPC parts cannot activate touch plates. Per-character NoCollisionConstraints
keep player/NPC collisions disabled without changing existing player collision groups;
pairs rebuild on NPC creation and character changes and clean up on removal. Cost
scales with active kingdoms and players; two-kingdom load testing remains required
before increasing server capacity. No economy or combat benefit from inhabitants.

## Verification

In Studio Mock before claiming, set ServerScriptService.Server attribute
StudioStrongholdTests=true and Play. It runs through the normal bootstrap cache,
restores the starting profile and releases its fixture afterward. Optional
StudioStrongholdRegression=true additionally runs farm, purchase and rebirth suites
sequentially. Keep unrelated previews/suites off. Stop and clear both attributes.

Expected Output:
- All stronghold purchase and replacement checks passed
- All protection door checks passed
- All kingdom resident checks passed
- Restoration and rebirth cleanup passed
- All stronghold regressions passed (only with regression attribute)

Observed: exact charges, sequential visibility, duplicate rejection, wooden
replacement, owner toggle/cooldown/immunity,14rig limit/no duplicates, all eight
walkers moving, saved in-session release/reclaim restoration, and actual rebirth
cleanup passed. Farm accounting/service, producer scheduling, centered plate labels,
farm/wooden purchases and rebirth economy/service regression suites passed.
Standalone door-policy tests cover owner, visitor, disabled, NPC and spawn shield.
Formatting, Selene and Rojo build passed. Full Roblox-aware strict LSP analysis was
not available in this session. Existing asset203785492 type warning remains unrelated.

Still hands-on: two real players (visitor death and unauthorized control), continuous
native perimeter traversal, mobile/gamepad prompt UX, durable Persistent rejoin,
long-running route recovery and multi-kingdom performance. A single-player policy
test does not establish multiplayer acceptance. Prices remain provisional approved
values, not pacing-tested results.

## Save and rollback

Assets are installed in the current Studio Edit session. Save the place normally to
retain them; no publish or Git push is part of this work. Recipes reproduce installation.
To roll back, stop Play, disconnect Rojo while reviewing, archive the current template
under a fresh name, and restore the intact original from StoneStrongholdBackup_20261118.
Also revert feature code together: older templates lack the feature's required assets.
Do not delete new saved purchase IDs or downgrade schema. Preserve both templates.
