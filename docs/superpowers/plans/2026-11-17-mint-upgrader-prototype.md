# First Mint upgrader prototype

Approved in conversation; reference: [concept](../../MINT_UPGRADER_CONCEPT.png).

Goal: one durable 250-Gold arch after RoyalMintDropper08. Forward-passing coins
upgrade once from 3 to 6 Gold and become brighter without size/material/physics
changes. Ownership restores through the existing purchased-buildings dictionary.
No new remotes, schema migration, dependencies or Rojo mappings.

1. Extend FarmLedger with private per-token values/applied IDs. Add tested
   ApplyUpgrade and GetValue operations; preserve constructor/account semantics.
2. Add forward swept-box crossing checks, processed before collection in the
   existing production tick. Baseline coin positions when ownership changes;
   reject retroactive passage, duplicates, expired tokens and unsafe values.
3. Add one purchase/config entry. PurchaseService owns whole-model parenting;
   FarmService validates retained asset availability and owns coin effects.
4. Backed-up Edit recipe: one blue/iron/gold arch, amber inset, crown emblem and
   small ×2 label. Direct UpgradeZone centered(-80,5.5,-52), size8x4x4; posts outside
   rails. Preserve original template. Only the first model and plate are installed.
5. Test ledger/crossing/purchase/real streams/collection/restoration. Run existing
   Mint containment, farm, purchase and HUD suites separately, static checks and
   an independent source review. Save Edit with tests off; modular commits.

Future: same model and code support eight arches. Only one live entry now.
The full curve 250/300/400/600/1000/1900/3800/7500 is provisional; last arch needs
short forward belt/collector extension. Decorations, conveyor two and horses are
separate. Branch feat/mint-upgrader-prototype; no push/publish.

## Execution record

Completed: ledger, swept crossings, one live purchase, backed-up asset, normal
bootstrap integration tests and docs. Existing Mint/farm/purchase/HUD suites pass
separately. Static checks and independent source review pass. Corrected test-only
cooldown ordering without changing production throttling. Saved cloud 89, Edit,
all tests off. Native creator/multiplayer and Persistent rejoin acceptance remain.
