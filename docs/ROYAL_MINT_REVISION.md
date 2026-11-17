# Royal Mint: wider yard and housed presses

This revision supersedes the narrow-yard geometry in `ROYAL_MINT_ASSETS.md`.
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
flat; its smaller free fall places the coin just above the belt. Decorative
nozzle art must not be included in the guide collision group.

## Geometry and visual direction

All coordinates are local to the unchanged KingdomTemplate pivot.

| Item | Revised geometry |
| --- | --- |
| Paved yard | **88 × 128**, center `(-56, 0, -12)`; X −100…−12, Z −76…52 |
| Conveyor | Center `(-80, 2.5, -16)`, size **8 × 2 × 96**, LookVector +Z; top Y 3.5 |
| Paired rails | X −84.5 / −75.5, center Y 4.4, Z −16; size 0.6 × 1.8 × 96 |
| Eight machine centers | X −89; Z −58, −46, −34, −22, −10, 2, 14, 26 |
| Eight drop points | X −80, Y **4.1**; matching station Z |
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

The recipe creates **617 authored parts** plus the cloned collector face/rim;
`AuthoredPartCount` records the generated count. The exact overall BasePart count
also includes cloned collector parts. The expanded paving contributes 176 shallow
pavers; the added static geometry uses no NPCs, rigs, or frame-loop animations.
Eight low-range PointLights retain shadow casting disabled. The recipe checks
all eight corners of every Mint BasePart against the yard bounds, checks all
parts are anchored/script-free, and requires exactly three collidable guides.

## Verification and rollback

Before saving, inspect the full yard and individual housed presses in Edit mode.
In Play, verify the runtime hides unowned presses and later plates, all eight
low-release coin streams stay on the thick belt, and the first station's longest
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
