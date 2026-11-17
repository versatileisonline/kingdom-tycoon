# Royal Mint implementation plan

Approved in conversation 2026-11-17; reference: ../../ROYAL_MINT_CONCEPT.png.

Goal: open-air Mint with eight sequential droppers and shared farm/Mint collection.
Prices: 60/70/90/110/130/150/170/190 Gold. Each press yields 3 Gold every 3 seconds.
One next plate only. First purchase after WoodenWalls reveals yard + producer 1.
Owned scenery restores on claim; existing free farm activation starts production.
Session earnings survive death/failed updates, disappear on departure; purchases persist.

1. Shared SessionEarnings account injected optionally into FarmLedger; retain legacy API.
   Test mixed values, duplicate arrivals, failed/successful collection, overflow and cleanup.
2. Extend FarmService to two bounded sites; preserve public farm calls and add optional site ID
   for collection. PurchaseService retains model parenting, typed Mint purchase routing.
   Mint cap32/lifetime20/speed8; farm cap12 unchanged; one timed loop, no new remotes/schema.
3. Backed-up one-time Edit recipe and asset contract: yard48x128 center(-64,0,-12),96 belt,
   8 stations12 apart. RoyalMint unlock direct Conveyor/CollectionPit/CollectPlate;
   Producers.Dropper01..08 each direct DropPoint; ServerStorage.RoyalMintCoin single part.
4. Normal-bootstrap Mock suites for purchases/shared collection/restoration/cleanup;
   formatting/lint/strict Roblox analysis/build. Native visual and transit acceptance.
5. Independent whole-branch review; docs, small modular commits, save Edit place, tests false.

No push/publish. No background wall/gate changes. Source lives on feat/royal-mint.

## Execution record

Completed on feat/royal-mint: shared account, production/purchases, backed-up
assets, normal-bootstrap suites and documentation. Independent review clean after
adding actual coin transit checks for every Mint producer. Tests: new Mint/shared
account; existing purchase, farm and data suites separately. Format/lint/strict
Roblox types/build pass. Source template preserved; 427 anchored script-free Mint
parts and all corners fit. Saved cloud place version80 in Edit with tests false.
Native visual/walking/multiplayer/pacing and Persistent rejoin acceptance remain.
Ruling: work in the existing checkout on the approved dedicated feature branch
so the active Rojo session continues syncing the intended source.
