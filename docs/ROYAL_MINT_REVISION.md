# Royal Mint: wider yard and raised housed presses

These revisions supersede the narrow-yard geometry in `ROYAL_MINT_ASSETS.md`.
It preserves the eight existing purchases and their prices/output, shared
Collect Total behavior, wooden walls, outside farm, template pivot, and kingdom
entry route. Horses, upgraders, a second production lane, and additional purchase
plates are outside this revision.

## Installation and preservation

`tools/ReviseRoyalMint.luau` is an approved one-time Studio **Edit-mode** recipe,
not runtime source and not Rojo-mapped. The initial Mint must already be installed.
Stop Play, ensure ActiveKingdoms is empty, and use place `77311816657817`.

The recipe builds and validates a detached replacement clone first. It replaces
only the cloned Mint model and its cloned purchase plates. It never destroys the
original template, original coin, original Mint, original source recipe, or prior
backup. On success it archives the full original KingdomTemplate and
RoyalMintCoin intact under **ServerStorage.RoyalMintRevisionBackup_20261117**,
then installs the revised template and coin clone. It refuses a second revision
when that backup already exists. Construction failure destroys only newly created
replacement objects and leaves the active source untouched.

Expected Output:

- `Royal Mint revision asset checks passed (... authored parts, eight presses, 96-stud belt)`
- `Revised RoyalMint; original template and coin retained in ServerStorage.RoyalMintRevisionBackup_20261117`

Save the Studio place after visual/runtime acceptance. A Rojo code-only build does
not save Studio-owned geometry. This recipe never publishes or changes player data.

## Updated asset contract

Names and hierarchy remain compatible with the installed Mint:

```text
ServerStorage
  RoyalMintCoin (single script-free cylinder Part, 0.5 × 1.6 × 1.6)
  KingdomTemplate
    PurchaseUnlocks.RoyalMint
      Conveyor (direct BasePart; MintCoinGuide = true)
      CollectionPit (direct invisible, noncolliding query Part)
      CollectPlate (direct BasePart; descendant EarningsLabel)
      Scenery
        BeltRail (two Parts; MintCoinGuide = true)
        ... fixed stone/timber/gold decoration
      Producers.Dropper01 ... Dropper08
        DropPoint (direct invisible marker and PrimaryPart)
        ... housed press artwork
    PurchasePlates
      RoyalMint, RoyalMintDropper02 ... RoyalMintDropper08
        ... PurchaseLabel
```

Every static Mint part is anchored and script-free. Exactly three parts carry
`MintCoinGuide=true`: the conveyor and paired tall rails. Runtime collision setup
must use this attribute to make spawned coins collide with those guides, while
ignoring decorative machinery, avatars, other coins, and unrelated world parts.
The recipe authors the tag but does not register or alter collision groups.
The pit remains queryable and noncolliding: overlap accounting owns arrival.

Coin template thickness increases from 0.3 to **0.5 studs**. The recipe retains
its existing color/material and clones it before modification. Runtime unanchors
each spawned coin, gives it server physics ownership, and positions it using the
DropPoint CFrame. DropPoint retains the Z-axis quarter-turn that lies the cylinder
flat; the follow-up height revision raises it for a clearly visible fall onto the belt. Decorative
nozzle art must not be included in the guide collision group.

## Geometry and visual direction

All coordinates are local to the unchanged KingdomTemplate pivot.

| Item | Revised geometry |
| --- | --- |
| Paved yard | **88 × 128**, center `(-56, 0, -12)`; X −100…−12, Z −76…52 |
| Conveyor | Center `(-80, 2.5, -16)`, size **8 × 2 × 96**, LookVector +Z; top Y 3.5 |
| Paired rails | X −84.5 / −75.5, center Y 4.4, Z −16; size 0.6 × 1.8 × 96 |
| Eight machine centers | X −89; Z −58, −46, −34, −22, −10, 2, 14, 26 |
| Eight drop points | X −80, Y **7.1** after height revision; matching station Z |
| Collection pit | Center `(-80, 3.2, 35)`, size **9 × 4 × 6** |
| Collector plate | `(-80, 0.8, 46)` |
| Initial purchase plate | `(-28, 0.4, 60)`; unchanged |
| Later purchase plates | X **−64**, Y 0.8; matching station Z |

The belt remains 96 studs long and now sits on the yard's left side. Wider stone
paving to its right is deliberately empty: it reserves space for possible future
expansion without introducing a second conveyor, future upgrades, ghost models,
or extra purchase actions. Lanterns stay at the outer yard boundaries. The crown
sign moves left of the collector and keeps its approach clear.

Each dropper now has a substantial enclosed blue-black iron body, gold corner
armour/bands, a broad heavy brass hopper, a crown-on-coin face emblem, rivets,
flywheel, and a short brass/iron discharge nozzle. This replaces the sparse
open-frame press silhouette. There is no roof over the production yard. The blue,
gold, timber, and stone palette remains consistent with the approved reference.

The wide-yard recipe creates **617 authored parts** plus the cloned collector face/rim;
`AuthoredPartCount` records the generated count. The height revision adds 24 support parts for **641 authored parts**. The exact overall BasePart count
also includes cloned collector parts. The expanded paving contributes 176 shallow
pavers; the added static geometry uses no NPCs, rigs, or frame-loop animations.
Eight low-range PointLights retain shadow casting disabled. The recipe checks
all eight corners of every Mint BasePart against the yard bounds, checks all
parts are anchored/script-free, and requires exactly three collidable guides.

## Verification and rollback

Before saving, inspect the full yard and individual housed presses in Edit mode.
In Play, verify the runtime hides unowned presses and later plates, all eight
raised coin streams visibly fall onto and stay on the thick belt, and the first station's longest
trip reaches the pit before expiry. The pit starts at Z 32 exactly where the
belt ends and covers the belt's full width. Verify both Collect Total plates,
walking access beside the rails and collector, restoration, death, and release.
Run the Mint suite and existing farm/purchase suites separately in Mock mode;
reset every test switch afterward. Static checks do not establish native physics
or visual acceptance.

For rollback, stop Play and move the revised active template and coin into a new
clearly named archive folder. Move the intact template and coin from
`RoyalMintRevisionBackup_20261117` back to ServerStorage. Preserve all archives
and owned purchase IDs. Revert matching runtime collision changes together with
this geometry revision. Do not rerun the recipe over edited assets or remove its
backup merely to bypass its guard.


## Follow-up: visible coin fall

After the wide-yard revision is installed, execute
`tools/RaiseRoyalMintDroppers.luau` once in **Edit mode**. It requires the Mint's
`Revision` attribute to be `WideYardHousedPresses`, the existing eight housed
presses, and original DropPoints at local Y 4.1. It refuses existing
`ServerStorage.RoyalMintHeightBackup_20261117` or unexpected heights, preventing
accidental replacement of a manually edited setup.

This separate recipe clones the active KingdomTemplate, raises every BasePart in
each press by **three studs** except its existing `MachinePlinth`, and adds a
solid stone pedestal with iron foot and gold cap. The pedestal rises from Y 1.1
to 4.1, joining the floor plinth to the raised iron bed; the machinery does not
float. Each press gains three anchored support parts, 24 in total. The nozzle,
housing, hopper, flywheel, and DropPoint all move together. DropPoint ends at
**Y 7.1** above belt top Y 3.5, giving approximately **3.35 studs of visible free
fall below the 0.5-stud-thick coin**. No towers or roofs are introduced.

After detached construction, anchored/script-free checks, unchanged floor-plinth
checks, and rotation-aware yard-corner audits pass, the recipe archives the entire
original template intact under `RoyalMintHeightBackup_20261117` and installs the
replacement. It sets `RoyalMint.Revision` to `RaisedHousedPresses` and increments
`AuthoredPartCount` by 24. The prior wide-yard and initial Mint archives stay
untouched. Conveyor/rail CFrames, guide attributes, the coin template, prices,
rates, ownership IDs, and collection behavior are unchanged.

Expect `Raised Royal Mint asset checks passed (8 presses, +24 support parts,
DropPoint Y 7.1)` and `Raised Royal Mint droppers; original template retained...`
in Output. Run the Mint transit suite and inspect native coin falling and full
upstream travel before saving. Static checks alone do not establish physics
acceptance. For height-only rollback, preserve the raised active template in a
new archive and restore the intact template from `RoyalMintHeightBackup_20261117`;
leave the active coin and all earlier backups intact.

## Coin collision contract

Runtime reserves KingdomMintCoins and KingdomMintTrack. On server startup,
existing groups cannot collide with Mint coins except the track group; coins also
ignore each other. FarmService assigns the track group only to the Conveyor and
parts tagged with the MintCoinGuide boolean attribute, and assigns coins to the
coin group before parenting them. Pit OverlapParams.CollisionGroup uses the track
group, so isolated coins remain detectable. These masks affect no farm bundles.
Any future dynamically registered collision groups should preserve this contract.

The raised outlet keeps a visible 3.35-stud gap beneath a spawned coin. It does
not rely on a near-belt spawn to hide instability. The sustained test observes
all eight streams with the owner standing on the belt, rejects coins outside the
lane, checks multiple real arrivals per producer, and distinguishes a valid fall
inside CollectionPit from a loss. Original reported below-belt coins were located
well before the collector; allowing only the collector volume does not hide them.

## Integration evidence — 2026-11-17

Both recipes installed in the approved place. Final authoring model contains
643 anchored, script-free BaseParts; all eight corners of every part fit the
expanded yard. Both backup archives exist. Raised-outlet assertions and the full
normal-bootstrap Mock Mint suite pass: real arrivals from each producer, at least
four observed arrivals from each during sustained production, no escapes or lost
expiry, shared collection/failure retention, ownership restoration and cleanup.
Owner-on-belt isolation is exercised throughout the 36-second sustained phase.
The initial strict belt-only assertion was corrected after diagnostics showed a
valid coin inside the pit (1.93 studs from center) awaiting the next overlap tick.

Separate existing farm, purchase and HUD suites pass. Formatting, lint, strict
Roblox Luau-LSP and code-only build pass. Independent source review found no
important bugs. Edit visual preview inspected; creator acceptance remains open.
Saved cloud version **85**, Edit mode, all tests disabled, no temporary previews
or runtime kingdoms. No publish or Git push. Prices, base coin value, production
interval and data schema are unchanged. Future upgraders/second conveyor and
horse riding are not installed by this revision.
