# Milestone 1.6: Outside farm progression

Code implemented; Studio asset integration and runtime acceptance pending.
The current starter-only template remains supported. No place assets, mappings,
walls, indoor droppers, or HUD visuals were changed by this implementation.

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

## Studio asset contract (separate task)

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
stay fixed; exact geometry and placement belong to the separate layout task.

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

No runtime Studio suites were run during implementation: Studio tool access was
rejected. Formatting, lint, type analysis, compilation, and build are distinct
from physics, native touch, visitor, death, and durable-save acceptance.
