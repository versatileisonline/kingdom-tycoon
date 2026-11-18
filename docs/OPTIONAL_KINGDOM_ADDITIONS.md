# Optional kingdom additions

## Approved behavior
After RoyalMintDropper08, six optional offers appear alongside the next production
plate. Buy them in any order. They never gate production and provide no income bonus.
Prices: RoyalBanners 250; RoyalLanterns 400; TrainingSword 600; SprintTraining 1000;
HorsePaddock 1900; RoyalFountain 4000 Gold. Ownership uses schema-v1 PurchasedBuildings.
Rebirth clears these purchases; normal saved progress on rejoin remains unchanged.

## Studio asset contract
tools/BuildOptionalAdditions.luau is the approved one-time additive Edit recipe.
It preserves the original template snapshot in
ServerStorage.OptionalAdditionsBackup_20261118, refuses collisions/reinstallation,
and adds only its six named children to KingdomTemplate.PurchasePlates and
PurchaseUnlocks. No Rojo mappings change. Do not restore a whole old template over
the landscaping agent's later changes.

Every plate is an anchored touchable cylinder with descendant PurchaseLabel.
Every matching unlock is an anchored script-free Model. Runtime PurchaseService
owns visibility; models and plates remain hidden until their purchase/unlock stage.
Horse scenery has no Humanoid, collision, touch, query, AI or riding behavior.

Local layout (X,Z), relative to template pivot:
- Banners (27,-30), 14x14; plate (15,-30).
- Lanterns (27,-65), 14x14; plate (15,-65).
- Armory (30,35), 20x18; plate (30,49).
- Sprint training (70,35), 20x18; plate (70,49).
- Paddock (64,-88), 64x40; plate (64,-60); open entrance faces +Z.
- Fountain (64,-20), 26x26; plate (64,0).

LayoutReservations.OptionalAdditionsMin/Max reserve local (8,0,-110)..(100,12,60).
Other agents own grass, ferns and trees; this recipe never edits those objects.
Static geometry adds 128 descendants across six unlocks; two unshadowed point
lights, no NPCs or extra physics actors. The fountain is static glass/stone.

ServerStorage.KingdomTrainingSword is a script-free Tool with Handle, Blade, Guard,
welds, no contact/query/collision, and CanBeDropped=false. EquipmentService owns its
runtime copies. Never insert free-model scripts into this asset.

## Rollback
Archive the six installed plate/model pairs and sword template separately; revert
matching feature code. Preserve backups and saved IDs. Do not replace unrelated
template children or reset player data. The snapshot is reference/recovery material,
not an automatic whole-template rollback.

## Verification ledger
- Optional-offer policy: observed RED before module implementation, then GREEN in
  Studio Edit, including independent offers and production frontier preservation.
- Asset recipe: StyLua and Selene pass. Installed six plate/model pairs and sword;
  Studio readback confirms all IDs. Remaining runtime/visual checks recorded below.
