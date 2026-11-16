# Wooden kingdom walls

Approved 2026-11-16: finish the initial tycoon before shop/gamepasses. One complete
wooden enclosure costs 40 Gold after FarmDropper04. Later stone upgrades, towers,
defenders and decorations are separate tasks; defense is visual for now.

## Behavior and asset contract

PurchaseConfig defines WoodenWalls (Wooden Walls, 40 Gold, requires FarmDropper04).
PurchaseService uses the existing model-unlock path: atomic Gold/ownership update,
owner/living/distance/cooldown validation, one visible next plate, and saved restore.
No remotes, schema migration, service changes, dependencies or Rojo mapping changes.
Saved ownership reveals walls immediately on claim, before the session-only farm start.

Under ServerStorage.KingdomTemplate:
- PurchasePlates.WoodenWalls: anchored touchable plate, descendant PurchaseLabel.
  Existing 4-stud face, black rim and compact hovering label; local (0, 0.4, 92).
- PurchaseUnlocks.WoodenWalls: script-free anchored Model at its final template-relative
  position. 630 static wood parts: stakes with paired wedge tips, two support beams
  per run, and reinforced entrance posts. No external mesh/image assets.

The 16-stud-high enclosure fits X -108…108, Z -140…76. Entrance is 24 studs wide,
centered at X 0 on the front wall. Five runs enclose the interior without a gate
crossbar or moving gate. Farm, spawn and approach remain outside and unchanged.
Walls collide normally; they have no health, damage, NPC or combat behavior.
Static parts trade more rendering instances for an asset-free prototype; no runtime
construction, physics simulation, server loops or connections are added for walls.

## Installation and rollback

Run tools/BuildWoodenWalls.luau once, verbatim in Edit mode in place 77311816657817.
It validates the template and constructs a replacement off-tree. Only after all
checks pass does it move the intact original into
ServerStorage.WoodenWallsBackup_20261116 and install the replacement. It refuses
repeat installation. The recipe is not Rojo-mapped. Save Studio to retain assets.

Rollback: Stop Play and disconnect Rojo while reviewing changes. Archive the current
KingdomTemplate under a new backup folder; move the original KingdomTemplate out of
WoodenWallsBackup_20261116 into ServerStorage. Keep both versions. The optional wall
purchase definition can remain without assets, but the expanded purchase suite
requires wall assets. No existing purchased IDs should be deleted from saved data.

## Verification

Enable only PurchaseConfig.RUN_TESTS_IN_STUDIO in Mock mode on disk, sync and Play.
Expect All producer scheduling checks passed, All farm purchase-service checks passed,
and All wooden-wall purchase checks passed. The suite verifies hidden walls and
prerequisite gating, 39/40-Gold red/green boundary, exact charge, distant and duplicate
rejection, reveal, release cleanup, and restoration without charging or starting farm.
Existing four-source physical production and shared collector checks still run.
The suite restores original player Gold, purchases, position and plot state.

Run the farm suite separately, then reset every test switch to false. Formatting,
Selene, strict Roblox Luau-LSP and a code-only Rojo build must pass.

For isolated durable fixtures, DataLayerTests.RunStorage(true, nil, true) writes a
GUID-prefixed Verify_ key in KingdomTycoon_PlayerData_Test with wall and farm ownership.
After restarting Play, RunStorage(true, returnedKey, true) verifies the persisted
fixture without rewriting it. This storage-only helper is safe outside the normal
bootstrap cache; gameplay service tests must use the normal bootstrap. It never
uses live/player keys. Old RunStorage calls retain their previous behavior.

Hands-on acceptance: earn and buy through Dropper 4, approach Wooden Walls, buy,
walk through entrance and around the farm/collector, die and check walls remain.
Use a second player to verify visitor rejection. Durable fixture reload does not
replace a full Persistent player join/reclaim test. Check 40-Gold pacing by playing.

## Verified integration (2026-11-16)

- Normal-bootstrap Mock purchase suite passed: four producers, 39/40 boundary,
  exact deduction, reveal, duplicate/distance gates, release and saved reclaim.
- Separate farm accounting/service and mock data-layer suites passed.
- Formatting, Selene, strict Roblox Luau-LSP, and code-only build passed.
- Edit preview visually inspected; recipe checks all part corners against reservation.
  Final audit: 630 anchored, script-free wall parts, original archived intact.
- Durable fixture Verify_78cb10de-e5c8-472d-8357-3e24fb974092 wrote and reloaded wall
  ownership across separate Play sessions in the test store. An earlier fixture
  Verify_018e3850-eafa-4a42-976e-1eac5f62a485 used the old helper before Rojo sync
  completed; its read correctly failed the wall assertion. It contains only the
  ordinary Gold-77 fixture. Both non-player fixtures remain in the test store.
- Native visitor/death/walking acceptance, full Persistent player rejoin restoration,
  and purchase pacing remain creator checks; no live store touched.
- Independent code review identified corner seams; side runs extended to 210 studs.
  Final corner overlap, reservation bounds and 24-stud entrance raycasts passed.
- Saved cloud place version 73 in Edit mode, all test switches false, no temporary
  previews or active kingdoms. This is a save, not a publish. No Git push.
