# Royal Mint Studio assets

`tools/BuildRoyalMint.luau` is the approved one-time **Edit-mode** installation
recipe for the open-air Mint concept. It is not a runtime script or Rojo mapping.
The recipe is prepared and statically checked; installation and visual acceptance
require the connected Kingdom Tycoon place, not a code-only Rojo build.

## Installation and preservation

1. Open place `77311816657817`, stop Play, and ensure `ActiveKingdoms` is empty.
2. Sync the matching source through Rojo; review its diff. No map mapping changes
   are required. The existing farm, walls, template pivot, and outside landscape
   stay intact.
3. Execute `tools/BuildRoyalMint.luau` verbatim once in Studio Edit mode. It
   validates the existing purchase/style assets, builds a detached template clone,
   audits its Mint, and only then installs the replacement. Construction failure
   destroys only newly created detached objects.
4. Expect `Royal Mint asset checks passed (... authored parts, eight presses,
   96-stud belt)` followed by `Installed RoyalMint; original template retained...`.
5. Save the Studio place to retain geometry. Rojo builds contain code only.

The original template is moved intact into
`ServerStorage.RoyalMintBackup_20261117.KingdomTemplate`. The recipe refuses an
existing backup, Mint, coin template, or conflicting Mint purchase plate; it never
reruns over edited assets. The recipe does not publish, enable API access, or
change any player data.

## Asset contract

```text
ServerStorage
  RoyalMintCoin (single archivable, script-free Part; Cylinder)
  KingdomTemplate (existing pivot and PrimaryPart preserved)
    PurchaseUnlocks
      WoodenWalls (existing, unchanged)
      RoyalMint (anchored, script-free Model)
        Conveyor (direct BasePart)
        CollectionPit (direct BasePart; invisible, noncolliding, queryable)
        CollectPlate (direct touch plate)
          ... EarningsLabel (descendant TextLabel)
        Scenery (Model; pavers, frame, trough, lights, sign)
        Producers (Folder)
          Dropper01 ... Dropper08 (Models)
            DropPoint (direct invisible anchored Part; also PrimaryPart)
            ... fixed gold/iron press geometry
    PurchasePlates
      RoyalMint (BasePart; descendant PurchaseLabel)
      RoyalMintDropper02 ... RoyalMintDropper08 (same contract)
```

The entire Mint model unlocks with `RoyalMint`; producer 1 uses that same saved
purchase ID. Subsequent producer IDs are `RoyalMintDropper02` through `08`.
Production code retains unowned producer models outside Workspace and reveals
only owned ones. PurchaseService similarly retains future plates and shows only
the next action. The installed template contains all eight presses for authoring;
the runtime clone applies progressive disclosure. No ghost slots or visible
future models are part of the player experience.

The purchase labels use the existing plate presentation module. Labels show the
configured name and price, including the HUD gold dot. The collector is labeled
`Collect Total` and uses `EarningsLabel`. Runtime code publishes the shared
farm/Mint total and affordability colors. The other collector shows the same
balance, and either plate collects it all.

## Geometry

Coordinates below are local to the preserved KingdomTemplate pivot. The full yard
is **48 × 128**, centered at `(-64, 0, -12)`, spanning X −88…−40 and Z −76…52.
It remains inside the existing wooden enclosure and leaves the central gate route
clear. This task adds no decorated gate, replacement walls, roof, or surrounding
buildings from the concept background.

| Item | Local geometry |
| --- | --- |
| Conveyor | Center `(-64, 3.1, -16)`, size `6 × 0.8 × 96`; LookVector +Z |
| Drop points | `(-64, 6.6, -58 + 12 × index)`, index 0…7 |
| Press centers | X −73; same eight Z positions |
| Collection pit | Center `(-64, 3.2, 35)`, size `7 × 4 × 6` |
| Collector plate | Center `(-64, 0.8, 46)` |
| Initial purchase | Center `(-28, 0.4, 60)`, beside the entry route |
| Later purchase plates | X −46, Y 0.8, aligned with their press station |

The conveyor ends at Z 32; its pit starts at Z 32, so moving coins enter the
query volume without a gap. Runtime must give coin clones server physics
ownership, enable production only for active owned stations, and apply conveyor
velocity in its LookVector direction. Coins are single cylinders of size
`0.3 × 1.6 × 1.6`. DropPoint's Z-axis quarter-turn makes the cylinder lie flat
when the runtime assigns `bundle.CFrame = DropPoint.CFrame`. The authored template
coin is anchored; only spawned runtime clones are unanchored.

The Mint creates **425 authored parts**, including the invisible markers/pit,
plus the cloned collector face/rim. Purchase plates are outside that count.
`RoyalMint.AuthoredPartCount` records the created count; actual total BaseParts
also includes the cloned collector assets. All eight presses are static art, not
NPCs or animated rigs. There are eight small, non-shadow-casting PointLights;
client low graphics can hide their emissive styling only if supported separately.
No per-frame behavior is installed by this recipe.

The production budget is 32 physical Mint coins plus the existing farm's 12
bundles per player. At speed 8, the upstream 90-stud trip is approximately 11.25
seconds before physical settling, below the proposed 20-second lifetime. Verify
this with actual physics: conveyor contact, congestion, coin orientation, and
collision behavior can change transit time.

## Acceptance and rollback

Inspect the visible yard in Edit mode before saving: long belt, eight gold/iron
presses, stable stone paving, blue-and-gold crown sign, lanterns, and clear service
and entrance routes. In Play, unowned presses must disappear immediately. Buy the
Mint and all seven upgrades, verifying each new press appears beside the same
belt. Check native walking, upstream coin arrival, collector overlap, legible
centered labels, shared collection/reset, death, ownership restoration, and
release cleanup. A generated concept is the visual direction, not pixel-exact
Studio acceptance.

For rollback, stop Play and preserve the current Mint-bearing template **and**
`RoyalMintCoin` by moving them into a new clearly named rollback archive folder;
then move the intact original template from `RoyalMintBackup_20261117` back to
ServerStorage. Do not delete edited assets or the backup. Revert the corresponding
source feature commits when rolling back code. Saved Mint ownership IDs must not
be erased. Existing farm-only templates remain supported by the runtime. The
backup folder intentionally prevents a second installation without inspection.
