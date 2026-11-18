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
- [ ] Optional purchase policy, tests, catalog and service integration.
- [ ] Additive Studio assets, recipe and asset contract.
- [ ] Non-damaging sword service/controller and tests.
- [ ] Sprint state/service/controller/view, camera binding and tests.
- [ ] Integration/rebirth verification, docs and handoff.

Verification: pure Edit tests, native Mock Play integration tests, lint, formatting,
Rojo build, asset audits and visual inspection. Record actual results below.
