# Milestone 1.6: Outside farm progression

Code and four-dropper Studio assets installed. The current starter-only template
remains supported. No mappings, walls, indoor droppers, or HUD visuals changed.
See the installed revision and verification results below.

## Approved behavior

One farm, one decorative farmer, one fixed conveyor, and one shared collector.
Four drop positions must fit the existing farm footprint from the beginning.
The free starter produces one Gold every three seconds. Buy FarmDropper02 for
6 Gold, FarmDropper03 for 12 Gold (requires 02), and FarmDropper04 for 24 Gold
(requires 03). Every added dropper has the same output as the starter.

After each claim, Start Farm activates every owned producer. Buying another
dropper starts its timer immediately; its first bundle arrives after its three
second production interval plus conveyor travel. Ownership persists through
PurchasedBuildings in schema v1. Gold is deducted and ownership recorded in one
DataService update. Farm start remains session-only. Death preserves production
and uncollected earnings; departure discards uncollected earnings. No offline income.

The later progression is all four droppers → initial walls → more valuable indoor
droppers, with higher indoor prices. Target 2–3 minutes from joining to indoor
production; this milestone alone cannot establish that timing. Initial farm prices
imply 18, 18, and 24 seconds of ideal production between purchases, excluding
walking, collection, and wheat travel/loss. Tune only after hands-on checks.

## Studio asset contract

Preserve every existing direct-child starter machinery contract from
KINGDOM_LAYOUT.md, including DropPoint, Conveyor, CollectionPit, CollectPlate,
and EarningsLabel. Do not move these into a new machinery folder.

```text
ServerStorage.KingdomTemplate
  StarterFarm
    DropPoint                         existing free producer
    Conveyor                          fixed size; supports all four drop positions
    CollectionPit                     shared arrival region
    CollectPlate                      shared earnings label and collection
    Producers (Folder; optional until all assets are authored)
      Dropper02 (Model)
        DropPoint (direct anchored BasePart)
        ... producer scenery
      Dropper03 (Model; same contract)
      Dropper04 (Model; same contract)
  PurchasePlates (Folder)
    FarmDropper02 (anchored touchable BasePart)
      ... PurchaseLabel (descendant TextLabel)
    FarmDropper03 (same contract)
    FarmDropper04 (same contract)
```

If Producers exists, supply exactly these three models. Each must be script-free
and anchored, with its DropPoint aimed/positioned to place the existing WheatBundle
on the belt. Check all four trajectories into the same pit without jams or clipping.
Use one farmer for decoration; additional producer models contain no farmer logic.
The conveyor never expands at runtime. Existing footprint and wall reservations
stay fixed; installed geometry is recorded below.

Farm purchase plates do not have matching PurchaseUnlocks models: FarmService owns
their producer models. PurchaseUnlocks is optional for a farm-only template;
ordinary model purchases still require their matching models there. Include the
whole prerequisite plate chain. Keep existing Studio fixtures if desired.
With no Producers and no farm plates, the old starter-only template still works.
Malformed partial assets fail the claim with rollback rather than charging for
missing production. Do not install farm plates before their producer models.

FarmService retains detached locked models and destroys them explicitly on release.
Production follows committed data, not client attributes. Private scheduling gives
each producer its own timer. A shared cap of 12 live bundles and 20-second expiry
bound physics costs per farm, rather than multiplying the cap by four. Due producers
rotate priority when capacity is constrained; missed intervals are skipped. Bundle
ProducerId attributes identify the source for diagnostics only, never award credit.

## Verification

Run `stylua --check src`, `selene src`, strict Luau-LSP analysis with Roblox
definitions, and a code-only `rojo build` to a temporary output path. A code-only
build does not include or back up Studio assets.

After authoring the assets, use a local Studio copy with Mock data. Leave all other
test switches false. Set PurchaseConfig.RUN_TESTS_IN_STUDIO on disk to true, sync,
then Play before claiming. The suite runs from the normal server bootstrap and
restores original Gold, purchase ownership, position, and plot availability.
Expect `All producer scheduling checks passed` and
`All farm purchase-service checks passed`. Reset the switch to false afterward.
Never run the service suite through a plugin/command require with a separate cache.

The suite checks activation gating, prerequisites, insufficient funds, charges,
duplicate rejection, all four sources spawning physical bundles, shared physical
earnings/cap, cleanup, and purchase restoration on reclaim without automatic start.
Existing farm accounting/service tests and plot tests must run separately; the
plot suite checks claim observer registration order. No test switches are enabled
by default. Tests that manipulate Gold must never run concurrently.

Hands-on acceptance still required:

1. A new player sees only the starter on Start Farm. Other producer models stay hidden.
2. Earn and collect Gold; buy 02, 03, 04. Expect one `Purchased FarmDropper02 for
   6 Gold`, `Purchased FarmDropper03 for 12 Gold`, and `Purchased FarmDropper04 for
   24 Gold`. Returning to each removed plate cannot charge again.
3. Confirm all four bundles land, travel, and credit one collector. Compare actual
   timing against ideal rates (20, 40, 60, 80 Gold/minute). Try simultaneous farms
   after the separate multi-plot layout is installed.
4. A funded visitor cannot buy, start, or collect from another player's farm.
   Death preserves all four producers and uncollected earnings. Failed collection
   retains earnings (covered separately by the existing farm suite).
5. Leaving destroys active bundles and detached models. Reclaim requires Start Farm
   again and restores purchased producers with zero uncollected earnings.
6. Verify durable ownership/Gold across separate Persistent test-store sessions;
   Mock reclaim does not prove durable saving. Restore Mock afterward. Published
   servers use the live store automatically; no live-store testing was performed.
7. Recheck ordinary Studio model purchases and the starter-only template separately.

The original code-only implementation could not access Studio. The later visual
integration ran the purchase suite through the normal bootstrap successfully.
Visitor, death, multiple simultaneously owned plots, and durable-save acceptance
remain separate checks.


## Installed visual revision (2026-11-15)

Installed in cloud-backed Kingdom Tycoon, place 77311816657817 / experience
10769565462. One-time `tools/BuildFourDropperFarm.luau` clones the existing
machinery, builds the replacement off-tree, validates it, and archives the intact
original template under ServerStorage.FarmProgressionBackup_20261115. It refuses
repeat installation, existing producer layouts, or existing purchase plates.
The recipe is not Rojo-mapped and never runs during gameplay.

All coordinates below are local to KingdomTemplate's unchanged pivot:

- Conveyor: original width/height, fixed length 32, center Z 124 (Z 108–140).
- Foundation: original width/height, length 40, aligned with the belt at Z 124.
- Four drop points: original X approximately -42.271, Z 137, 129, 121, 113.
- Existing shared pit moves to Z 106.2. Rails and legs support the full belt.
- One decorative farmer stays in front at Z 145, aligned with the starter.
- Purchase plates: X -30, Z 134 / 124 / 114, with the existing circular black-rim
  style, name/price, and availability labels. Shared collect plate: X -30, Z 104.
- Crop beds, shed, fencing, claim/start plates, wall reservations, and the rest of
  the map are preserved. The entire farm remains within its 112 × 48 reservation.

Viewport inspection of a temporary all-droppers preview passed. The preview was
removed before Play. Bounds/anchoring checks passed for all 212 farm parts. Runtime
purchase-suite Output confirmed all three charges (6/12/24), four-source spawning,
shared physical earnings/cap, cleanup, and reclaim restoration. Data mode was Mock;
no live player data was tested. A pre-existing content-type warning references
rbxassetid://203785492; resolving unrelated scene assets is outside this revision.

Rollback: stop Play, archive the revised template separately, then restore the
original KingdomTemplate from FarmProgressionBackup_20261115 to ServerStorage.
Do not delete the backup or overwrite a same-named model. The current runtime code
supports that original starter-only template. Place saving is required independently
of Git commits, since Rojo builds do not include map assets.


The existing farm accounting and full farm-service suite also passed through the
normal bootstrap on the revised belt, including activation, physical collection,
failed-credit retention, cleanup, and reclaim. Stop confirmed the final Mock save.
Both switches were restored to false and synced before saving. The place was saved
to Roblox (TeamCreate), version **57**; it was not published. Studio was left in Edit
mode with no preview or active kingdom clones. Geometry/docs/recipe changes are
committed separately on feat/farm-dropper-progression; no Git push performed.


## Compact progression guidance (2026-11-15)

Only the next unfinished configured purchase plate is in Workspace. Before farm
activation, no paid farm plate is offered. After starting, only Dropper 2 appears;
it is red below 6 Gold and green at 6 or more. Buying it removes its plate and
reveals Dropper 3, then Dropper 4. Purchased models remain; future unowned models
remain hidden. General model purchases use the same single-next-action rule in
PurchaseConfig order. There are no price, missing-prerequisite, or instruction
paragraphs on plate labels.

All interaction plates now have 4-stud colored faces and 4.4-stud black rims.
`PlatePresentation` styles their labels as 14px GothamBold in a 128 × 40
BillboardGui at a centered world offset (0, 2, 0). White text has a light outline
for contrast and no background. These are hovering labels, not writing on the
plate surface. Dropper labels say only Dropper 2 / Dropper 3 / Dropper 4. The
shared collector displays `Collect` and the amount on a second line. A 24px,
partly transparent client-only arrow points down to the owner's Dropper 2 plate;
it disappears after that purchase and does not move to later purchases.

The used claim plate, rim, and label hide until the plot is released. Farm start
already hides its face/rim/label on activation. Collectors remain usable. Retained
future plates have no Workspace presence and fail server purchase validation.
All retained plates/models/connections are cleaned on release. Arrow updates are
event-driven and respawn-safe, with streaming removal handled explicitly.

`tools/RefinePurchaseGuidance.luau` is the one-time Edit styling recipe; it archives
the source template and claim plate in ServerStorage.PlateGuidanceBackup_20261115.
Do not rerun after that backup exists. Earlier farm machinery/backups remain intact.
Runtime styling also covers other plots and generic model purchases without changing
Rojo mappings. The client arrow controller is mapped automatically under Client.Controllers.

The expanded purchase suite checks claim/start disappearance, only-next visibility,
red/green affordability, compact label names/style, future purchase rejection,
plate consumption, and claim restoration, alongside all previous accounting and
producer checks. Test switches must return to false before saving.


Refinement verification: expanded purchase suite passed in Mock mode with hovering
bold labels and next-only visibility. Native touch checks also passed: claim/start
hide, collect 10 earned Gold with `Collect\n10`, buy Dropper 2, show only Dropper 3,
and remove the introductory arrow. Death before the first purchase preserved the
arrow and the running farm. Client inspection confirmed centered (0, 2, 0) label
offsets, 14px GothamBold, transparent backgrounds, and first-purchase-only guidance.

Refined place saved to Roblox (TeamCreate), version **61**, with tests disabled,
Mock mode, Edit mode, and no temporary clones. No publishing or Git push occurred.
