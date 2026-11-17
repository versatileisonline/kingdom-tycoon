# First Royal Mint upgrader asset

`tools/BuildMintUpgrader.luau` is the approved one-time **Studio Edit-mode** recipe
for the first upgrader prototype. It adds one royal-blue, iron, and gold arch with
a crown-and-coin medallion, amber pillar insets, and a small background-free `×2`
label. It does not author the later seven arches or change the existing Mint,
coin template, conveyor, rails, droppers, pit, or collector.

## Installation and backup

Use place `77311816657817` after the raised housed-press Mint revision is installed.
Stop Play and ensure `ActiveKingdoms` is empty. Sync the matching runtime source
from disk through Rojo, reviewing its diff; no Rojo mappings change.

Execute the recipe verbatim in Edit mode. It requires the Mint's `Revision`
attribute to be `RaisedHousedPresses` and refuses an existing upgrader model,
plate, or `MintUpgraderBackup_20261117`. It constructs a detached clone of the full
KingdomTemplate, adds only the upgrader and purchase plate to that clone, and
checks its parts and reserved bounds. A construction failure destroys only that
new clone. After checks pass, it moves the intact original KingdomTemplate into
**ServerStorage.MintUpgraderBackup_20261117**, then installs the replacement.
The existing coin and all earlier backups remain untouched.

Expected Output:

- `Mint upgrader asset checks passed (40 anchored parts, first arch only)`
- `Installed RoyalMintUpgrader01; original template retained in ServerStorage.MintUpgraderBackup_20261117`

Save the Studio place after runtime and visual acceptance. The recipe never
publishes, edits scripts in Studio, or changes player data. A code-only Rojo build
does not save these Studio-owned assets.

## Contract

```text
ServerStorage
  KingdomTemplate
    PurchaseUnlocks
      RoyalMint (existing, unchanged)
      RoyalMintUpgrader01 (new anchored, script-free Model)
        UpgradeZone (direct invisible Part; PrimaryPart)
          MultiplierLabel (BillboardGui)
            MultiplierText (TextLabel; ×2)
        ... fixed iron/blue/gold arch parts
    PurchasePlates
      RoyalMintUpgrader01 (touchable BasePart; descendant PurchaseLabel)
```

PurchaseService owns parenting the whole `RoyalMintUpgrader01` model. It is hidden
until owned, and its purchase plate follows the existing single-next-action
policy. The authored label is `Upgrader 1` with **250 Gold**, using the shared
plate presentation and gold dot. Authoritative purchase config and runtime
accounting determine availability and value effects; the image, label, and
attributes cannot grant income.

`UpgradeZone` is anchored, fully transparent, **noncolliding**, and queryable.
Its local center is **`(-80, 5.5, -52)`**, size **`8 × 4 × 4`**, with LookVector
**+Z**, matching conveyor flow. Its lower face is Y 3.5, spanning settled coins
whose centers are approximately Y 3.75. The trigger's name and direct-child
placement are the runtime contract. Detection must not rely on decorative touch
events. The arch contains no scripts and no `MintCoinGuide` attributes; runtime
Mint coin collision rules ignore its default-group art.

## Geometry and appearance

The arch crosses the belt halfway between the first two droppers, at local
**Z −52**. Pillars are centered at **X −86 and −74**, outside rails at X −84.5
and −75.5. Pillar bodies are 1.2 studs wide/deep, leaving a **10.8-stud clear
opening** for the belt/rails. Feet are 2.3 studs wide and only 1.8 studs deep;
their back edges at Z −52.9 clear the first dropper plinth's front edge at Z −53.
The lintel is centered at Y 10.8 with its lower face at Y 10, comfortably above
the coin path. All arch geometry fits X −88…−72 and Z −54…−50, confirmed by
rotation-aware corner checks.

Solid blue-black pillars carry royal-blue face panels, gold corner trim and
collars, and restrained amber emissive insets. The gold-trimmed blue lintel bears
a raised coin medallion and crown. Two small PointLights have range 6, brightness
0.35, and shadows disabled. The `×2` BillboardGui uses 14px GothamBold text,
a transparent background, a short display distance, and no giant information
card. It appears above the emblem, outside the walking/coin passage.

The arch has **40 anchored parts**, recorded in `AuthoredPartCount`, plus the
separately cloned purchase plate face/rim. It adds no NPC, animated rig, per-frame
loop, physics body, new coin guide, or additional producer. The purchase plate is
at **`(-64, 0.8, -52)`**, in the service aisle, with the same style as Mint plates.

Potential later arch centers are **Z −52, −40, −28, −16, −4, 8, 20, 32**. This
recipe builds only the first. The final proposed center at Z 32 needs a separate
belt/collector forward-extension design and acceptance before implementation;
do not place a final upgrader on top of the current pit or expose future plates.

## Verification and rollback

In Edit mode, inspect the arch silhouette, medallion, glow, clear belt/rail
passage, and first-dropper clearance. In Play before purchase, neither arch nor
future plate should be exposed. After the server accepts its configured purchase,
only this arch appears, its plate disappears, and registered eligible coins
passing through the zone receive the runtime's one-time value effect. Verify
upstream/downstream coins, repeated contacts, saved-ownership restoration, and
shared collection separately through the normal bootstrap suite. This asset
recipe alone does not establish accounting or native physics acceptance.

For rollback, stop Play and move the active upgrader-bearing template intact into
a new clearly named archive. Restore the intact KingdomTemplate from
`MintUpgraderBackup_20261117` to ServerStorage. Keep the coin template and all
backups intact. Revert the matching upgrader runtime feature together with asset
rollback, preserving saved ownership IDs. Do not delete edited assets or remove
the backup to bypass the one-time installation guard.
