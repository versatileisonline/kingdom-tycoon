# Optional Kingdom Additions Implementation Plan

Goal: Six independent purchases after RoyalMintDropper08, without blocking production.
Architecture: PurchaseService retains transactions and restoration; PurchaseOffers computes
visibility. EquipmentService and SprintService derive abilities from committed ownership.
Server stamina drives owner-only HUD state; clients send only held/released input.
Tech: strict Luau, Roblox, Rojo; schema v1 unchanged.

Approved catalog: RoyalBanners 250, RoyalLanterns 400, TrainingSword 600,
SprintTraining 1000, HorsePaddock 1900, RoyalFountain 4000 Gold.
All require RoyalMintDropper08; no production bonuses, damage, NPC AI or riding.
Shift holds sprint; Left Control toggles lock. Sprint speed 1.5x, capacity 6 seconds,
recovery delay 1 second, refill 4 seconds; exhaustion requires release.
Bar centered 30px below cursor, visible while depleted, fades full.
Rebirth revokes everything purchased; saving/rejoin behavior unchanged.
User authorized additive backed-up Studio recipes. Other agent owns vegetation.

Tasks / modular commits:
- [x] Optional purchase policy, tests, catalog and service integration.
- [x] Additive Studio assets, recipe and asset contract.
- [x] Non-damaging sword service/controller and tests.
- [x] Sprint state/service/controller/view, camera binding and tests.
- [x] Integration/rebirth verification, docs and handoff.

Verification: pure Edit tests, native Mock Play integration tests, lint, formatting,
Rojo build, asset audits and visual inspection. Record actual results below.

Execution ledger:
- Created feat/mint-optional-additions before editing; baseline working tree clean.
- Purchase policy tests observed failing before implementation, then passing.
- Stamina state tests observed failing before implementation, then passing.
- Additive recipe installed six pairs + sword, 124 scenery parts; backup preserved.
- Mock integration, client HUD and client sword-input bridge passed; Mint chain passed.
- Ruling: use measured horizontal root velocity on server, not unreplicated MoveDirection.
- Ruling: bar fixed center+30px with lock off as approved; no free-cursor following.
- Ruling: respect menu agent's later shared branch switch; stage task-only hunks.
- Final menu entry gates statically checked; combined suite needs rerun after restart.
- See docs/OPTIONAL_KINGDOM_ADDITIONS.md for exact logs, handoff and manual limits.
