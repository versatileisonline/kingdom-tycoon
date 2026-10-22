# Milestone 1.4: Starter farm and gold collection

> Layout revision (2026-10-21): see [KINGDOM_LAYOUT.md](KINGDOM_LAYOUT.md) for the
> current contract and acceptance checks. The farm now starts on a separate free
> plate after claim. The former footprint, immediate activation, and four-plot
> layout below describe the original implementation.

Claim a kingdom to activate its free starter farm. Every three seconds a wheat
bundle drops onto the conveyor. The pit consumes registered bundles for one Gold
each, held in session memory until the living owner steps onto the gold plate.
The plate reads `Collect Gold — [amount]`. Collection transfers the full balance
through DataService; a rejected update retains it. Committed Gold follows the
existing ProfileStore autosave and final-save lifecycle; collection itself does
not force an immediate durable write. Studio defaults to Mock, which resets
between Play sessions.

Death preserves the farm and uncollected Gold. Departure, explicit plot release,
and shutdown discard uncollected Gold and remaining bundles. Reclaiming starts at
zero. There is no offline production or catch-up burst after a delayed tick.
Purchase buttons, upgrades, Royal Mint unlocking, and the currency HUD are deferred.

## Architecture

- `FarmConfig` holds production, value, physics cap, expiry, tick, collection
  distance, cooldown, and the optional test switch.
- `PlotService.GetKingdom` returns the assigned server-side clone.
  `ObserveKingdoms` supplies synchronous claim/release callbacks and an unsubscribe
  function. Callbacks must not yield. Release notification precedes destruction;
  claim callback errors roll back the claim and notify cleanup observers.
- `FarmService` attaches behavior to each clone, keeps one private `FarmLedger`
  per owner, and disconnects its plate listener on release. It subscribes before
  gameplay can interleave with startup and checks existing assignments too.
- `FarmLedger` registers each token once, consumes it before awarding credit,
  bounds integer balances, and resets earnings only after a successful commit.
- A single timed server task checks farms every 0.25 seconds. Pit overlap queries
  include only that farm's bundle folder, then validate private registration and
  expiry. Unregistered objects and another farm's bundles award nothing.
- Each farm has at most 12 physical bundles; after 20 seconds they expire without
  credit. The server owns their physics via `SetNetworkOwner(nil)` rather than
  allowing nearby clients to simulate their motion. This costs server physics
  time, deliberately bounded to 48 bundles across the current four plots.
- Collection checks the live owner, current server assignment, distance from the
  plate's oriented bounds, and a one-second cooldown. Visitors touching it do
  nothing. DataService updates never yield, so balance transfer cannot interleave
  with another collection. No client request remotes or schema changes are added.
- `UncollectedGold` and `ActiveBundleCount` on the farm are replicated read-only
  presentation/debugging state. They never supply accounting values.

## Studio asset contract

```text
ServerStorage
  KingdomTemplate (existing archivable Model; anchored, script-free)
    StarterFarm (Model)
      DropPoint (anchored BasePart, invisible, noncolliding)
      Conveyor (anchored, collidable BasePart)
      CollectionPit (anchored, noncolliding BasePart)
      CollectPlate (anchored, collidable BasePart; CanTouch = true)
        EarningsGui (BillboardGui or SurfaceGui)
          EarningsLabel (TextLabel)
      ... anchored script-free scenery
    SpawnPoint (existing enabled, neutral SpawnLocation; Duration = 5)
  WheatBundle (archivable single BasePart or MeshPart; no scripts/other parts)
Workspace
  KingdomMap
    ArrivalSpawn (existing SpawnLocation; Duration = 5)
```

Required named parts are direct children of StarterFarm; EarningsLabel may be
nested. DropPoint's center is the spawn CFrame for each bundle. Place it above
the belt's starting end with clearance for the bundle's full size. Conveyor's
local **negative Z / LookVector** points toward the pit. FarmService sets its
`AssemblyLinearVelocity` to eight studs/second in that direction; the anchored
surface carries movable bundles. The pit must cover the full belt exit and have
enough volume to catch bundles during a timed query. The supplied tray and rims
keep bundles inside that volume. The gold plate sits beside the pit within reach
of the owner. FarmService configures runtime bundles as unanchored, collidable,
queryable, and server-owned; the separate template stays in ServerStorage.

`tools/BuildStarterFarm.luau` is the explicitly approved one-time Edit-mode recipe.
It fills an empty StarterFarm using the existing FarmFootprint's position,
rotation, and size. It refuses an occupied farm or existing WheatBundle rather
than replacing them. It also sets both spawn durations to five seconds. It is
not a runtime script and is not mapped by Rojo. Do not rerun it on the completed
assets. The pre-existing farm footprint and kingdom art are preserved.

The connected Kingdom Tycoon template was returned from Workspace to
ServerStorage with its edited scale (approximately 1.7466) and pivot preserved.
It is approximately 154 studs wide; neighboring plot centers are only 140 studs
apart. Resizing/repositioning the four plots and surrounding baseplate remains
the layout pass. Expect possible overlapping kingdoms until that is done; the
farm does not change plot spacing or shrink the user's kingdom.

Save the Studio place to preserve these assets. Rojo builds export code only;
`default.project.json` and existing ownership boundaries are unchanged.

## Camera and spawn protection

`CameraController` starts unlocked. Left Shift toggles centered mouse lock,
shoulder camera offset, and character facing along the camera's horizontal view.
It restores the previous offset, mouse behavior, and AutoRotate when unlocked,
suspended, or destroyed. The preference survives character respawns; old character
references are cleared. Typing, the Roblox menu, loss of window focus, sitting,
death, and nonstandard camera modes suspend the lock. Shift presses while typing
do not toggle it. PlotService disables native mouse-lock toggling per player so
two Shift handlers do not fight each other. The controller's sole per-frame work
is client-side and runs after the native camera update.

Both existing spawns use native five-second visible ForceFields. PlotService
sets Duration at startup so cloned kingdom spawns inherit it. This applies on
spawning, not on walking over a spawn or claiming land. The native shield protects
damage through `Humanoid:TakeDamage()`; it does not prevent direct Health writes.
A custom shield HUD and combat rules remain deferred.

## Verification

Repository checks: StyLua, Selene, strict Luau-LSP analysis with Roblox definitions,
and a code-only Rojo build. Accounting checks may run alone in Studio Edit mode:

```lua
require(game.ServerScriptService.Server.Tests.FarmServiceTests).RunAccounting()
```

They test duplicate/unregistered arrivals, exact expiry, independent balances,
bundle caps, failed/successful/repeated collection, cleanup, and bounded balances.
They use standalone tokens and never access player data or start Play.

For the optional full suite, keep `Config.DATA.STUDIO_MODE = "Mock"`, enable
`FarmConfig.RUN_TESTS_IN_STUDIO` on disk, leave both existing data/plot test switches
false, sync, then Play before claiming manually. The suite moves the first player,
claims Plot01, waits for actual physical production, exercises distant collection,
forces a rejected update at the maximum Gold value, checks retention, collects,
checks cooldown and exact Gold increase, releases, and reclaims. It restores the
original Gold and position and releases its kingdom even after an assertion.
An intentional `Collection retained` warning is expected. It does not write live
data. Run through the bootstrap switch; command/plugin requires have a separate
service cache and cannot test the running DataService reliably.

Expected completion messages:

```text
[KingdomTycoon][FarmServiceTests] All farm accounting checks passed (...)
[KingdomTycoon][FarmServiceTests] All farm-service checks passed (...)
```

Restore the farm test switch to false after the suite. Hands-on acceptance stays
with the developer:

1. Play and claim. See `Activated starter farm for <userId>`, one bundle every
   three seconds, bundles disappear at the pit, and the plate total grows.
   Initial travel time means the first credit follows the first drop.
2. Step on the plate. See `Collected <amount> Gold for <userId>` and the displayed
   balance reset. Step off/on repeatedly; no Gold duplicates. Saved schema remains 1.
3. Let earnings accumulate, reset your character, and confirm courtyard respawn,
   five seconds of visible protection, and preserved earnings.
4. With two local clients, claim separate farms. Confirm independent totals and
   production. A visitor stepping on another player's plate cannot collect it.
5. In the Server Explorer, inspect each runtime farm's `ActiveBundles` and
   `ActiveBundleCount` (never more than 12). Temporarily obstruct a runtime belt:
   expired/stuck bundles disappear after 20 seconds without Gold. Do not edit the
   stored template for this test; Stop discards the runtime obstruction.
6. Disconnect an owner. See `Cleaned up farm for <userId> (uncollected Gold
   discarded)`, the plot release, and DataService's final-save message. Reclaim
   the released plot and confirm a fresh zero balance.
7. Test Left Shift on/off, camera movement and character facing, typing/chat,
   menu opening, window refocus, and respawn with the toggle enabled. Confirm
   normal unlocked controls return when disabled. Arrival respawns also have a
   five-second shield.

No per-bundle Output logging is emitted.

## Status

Assets installed in the approved Kingdom Tycoon place; accounting tests passed
in Edit mode without player data access. StyLua, Selene, strict Luau-LSP analysis,
the Rojo build, and installed asset-contract checks pass. Production, physical collection,
multiplayer isolation, camera behavior, and actual shield timing still need the
developer's hands-on Play verification. All test switches remain false and
Studio remains in Edit mode.

Suggested commit: `feat: add starter farm production and gold collection`.
