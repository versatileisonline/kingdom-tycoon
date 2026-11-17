# Eight Mint upgraders and gold holograms

`tools/ExpandMintUpgraders.luau` is the approved one-time **Studio Edit-mode**
expansion of the accepted first arch into eight sequential upgraders. It adds a
translucent gold laser curtain to every arch and makes the downstream conveyor
clearance needed for the last station. It supersedes the future-layout caveat in
`MINT_UPGRADER_ASSETS.md`: this recipe includes that small forward extension.

## Installation and preservation

Use place `77311816657817` with the accepted `RoyalMintUpgrader01` prototype,
its matching purchase plate, and the raised housed-press Mint already installed.
Stop Play and ensure `ActiveKingdoms` is empty. Sync the matching runtime source
through Rojo and review its diff; no mappings change.

Execute the recipe verbatim in Edit mode. It refuses an existing
`MintUpgraderChainBackup_20261117`, existing upgrader 02–08 model or plate, an
existing first-arch GoldHologram, or unexpected conveyor/pit/collector geometry.
The recipe builds and audits a detached full-template clone before swapping.
Construction failure destroys only that new clone. On success, the intact
original KingdomTemplate is moved into
**ServerStorage.MintUpgraderChainBackup_20261117**, then the new template is
installed. The coin template and all earlier backups remain untouched.

Expected Output:

- `Mint upgrader chain asset checks passed (8 arches, 100-stud belt, gold holograms)`
- `Installed eight Mint upgraders; original template retained in ServerStorage.MintUpgraderChainBackup_20261117`

Save the Studio place after visual/runtime acceptance. The recipe never publishes,
changes player data, or edits scripts in Studio. A Rojo code-only build does not
save the map assets.

## Asset contract

```text
ServerStorage.KingdomTemplate
  PurchaseUnlocks
    RoyalMint (existing model, conveyor/pit/collector extended below)
    RoyalMintUpgrader01 ... RoyalMintUpgrader08 (anchored, script-free Models)
      UpgradeZone (direct invisible, noncolliding, queryable Part; PrimaryPart)
        MultiplierLabel (existing small ×2 BillboardGui)
      GoldHologram (direct visual-only Neon Part)
      ... accepted blue/iron/gold arch artwork
  PurchasePlates
    RoyalMintUpgrader01 ... RoyalMintUpgrader08
      ... PurchaseLabel
```

The existing first arch stays at its current position. Seven clones retain its
look and direct UpgradeZone contract, translated **12 studs** between stations.
Every clone sets its own `UpgraderId` attribute to its purchase ID. Each arch has
**41 anchored parts** including the new curtain, recorded in `AuthoredPartCount`;
all eight contain 328 parts total. Purchase plates are separate. Their labels and
prices are:

| Purchase | Label | Gold | Local center Z |
| --- | --- | ---: | ---: |
| RoyalMintUpgrader01 | Upgrader 1 | 250 | −52 |
| RoyalMintUpgrader02 | Upgrader 2 | 300 | −40 |
| RoyalMintUpgrader03 | Upgrader 3 | 400 | −28 |
| RoyalMintUpgrader04 | Upgrader 4 | 600 | −16 |
| RoyalMintUpgrader05 | Upgrader 5 | 1000 | −4 |
| RoyalMintUpgrader06 | Upgrader 6 | 1900 | 8 |
| RoyalMintUpgrader07 | Upgrader 7 | 3800 | 20 |
| RoyalMintUpgrader08 | Upgrader 8 | 7500 | 32 |

All purchase plates use local X −64, Y 0.8 and the matching station Z. The existing
first plate remains in place; new plates clone its styling and use the shared
price/gold-dot presentation. Runtime PurchaseService hides unowned models and
all but the next purchase action, then removes the used plate. The full template
contains future assets solely for authoring and restoration.

## Gold curtain and trigger geometry

The direct **GoldHologram** Part at each station is centered at local
`(-80, 6.8, stationZ)` with size **10.4 × 6.3 × 0.12**. Its gold Neon material and
**0.65 transparency** form a thin holographic curtain filling the arch opening,
with small margins above the belt and below the lintel. It is anchored,
noncolliding, untouchable, unqueryable, and does not cast a shadow. It carries no
`MintCoinGuide` attribute. It adds no animation loop or new PointLight.

The existing small amber pillar lights and blue/gold crown artwork stay intact.
Cloning the accepted art results in 16 low-range, non-shadow-casting PointLights
for all eight arches. No new moving physics bodies, NPCs, rigs, emitters, or
additional production lanes are created.

Actual eligibility remains the server's **UpgradeZone**: size **8 × 4 × 4**,
center `(-80, 5.5, stationZ)`, LookVector **+Z**. The curtain is visual; it cannot
grant value or change the one-time-per-zone accounting rule. Registered coins
must pass through the real server query volume. Each arch stays within X
−88…−72 and its station's Z ±2, checked against every rotated part corner.

## Downstream belt and collection clearance

The upstream conveyor start remains at local **Z −64**. Conveyor, both timber
frames, and both guide rails extend from **96 to 100 studs**, moving their centers
from Z −16 to **−14**. Their downstream end becomes **Z 36**. Heights, widths,
rotations, and existing `MintCoinGuide` attributes remain unchanged.

The pit and all seven trough decoration parts move **four studs forward**:
CollectionPit center becomes `(-80, 3.2, 39)`, size remains 9 × 4 × 6, and its
upstream face is Z 36, exactly matching the new belt end. The final arch's zone
ends at Z 34, leaving two studs before collection.

CollectPlate and its outline move **3.5 studs** to local **Z 49.5**. The 4.4-stud
rim ends at Z 51.7, inside the existing yard edge at Z 52. Billboards continue to
adorn the same moved plate. The ground, outside farm, droppers/drop points,
lanterns, sign, walls, gate route, and coin template are unchanged. The Mint's
`BeltLength` attribute becomes 100. Rotation-aware corner audits cover the entire
Mint, including the collector rim, after these moves.

## Verification and rollback

In Edit mode, check the gold curtain appearance, arch spacing, dropper clearance,
visible coin passage, eighth-arch/pit separation, and access to the moved
collector. In Play, verify only purchased arches appear, the next plate advances
one at a time, and both collection labels retain their shared total/reset.
Verify actual upstream coin transit through all owned zones, one upgrade per zone
per coin, downstream coins receiving only the arches they encounter, saved-owned
arch restoration, and release cleanup. Run the normal bootstrap Mint/upgrader
suites in Mock mode separately from other suites and reset every test switch.
Static asset checks do not establish native physics, value stacking, or visual
acceptance.

For rollback, stop Play and archive the active expanded template intact in a new
clearly named folder. Restore the original KingdomTemplate from
`MintUpgraderChainBackup_20261117` to ServerStorage. Keep the coin template and
all prior archives untouched. Revert matching chain runtime/config changes
together with the assets, preserving saved purchase IDs. Do not remove a backup
to bypass installation guards or rerun over edited source geometry.
