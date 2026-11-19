# Kingdom Tycoon

A medieval knight tycoon for Roblox. Build a kingdom with droppers, farms, and walls, rebirth for permanent multipliers, then (in later layers) ride horses across a large open world to outposts, opt-in PvP, guard armies, houses, and cosmetic dragons.

> **Status:** Layer 1 (core tycoon) in development. See the [roadmap](#roadmap).

## Highlights (engineering goals)

These are the goals this project is built around. Items are checked off only when implemented.

- [x] Rojo + VS Code + Git workflow (code as files, not just inside Studio)
- [x] Typed Luau with a modular service/controller architecture
- [x] Session-locked data saving (ProfileStore) with schema v2 and a v1 migration
- [x] Server-authoritative purchases, collection, rebirths, sprint and practice-course validation
- [ ] Server-authoritative combat (Layer 2; the current training sword does no damage)
- [ ] Global leaderboards via OrderedDataStore (KOs, rebirths, gold)
- [ ] Analytics: retention, session length, funnel drop-off
- [ ] Documented performance work (NPC and army caps)

## Game design

The full design lives in [GAME_DESIGN.md](GAME_DESIGN.md): pillars, layer plan, economy and rebirth model, PvP rules, and monetization rules (no pay-to-win).

## Getting started

**Requirements:** [Roblox Studio](https://create.roblox.com/), [VS Code](https://code.visualstudio.com/) with the Rojo extension, [Aftman](https://github.com/LPGhatguy/aftman), and the Rojo plugin installed in Studio.

```bash
# install pinned tools (Rojo, etc.) from aftman.toml
aftman install
wally install
mkdir -p Packages ServerPackages

# code-only build; this is not an export/backup of the Studio-built map
rojo build -o "kingdom_tycoon.rbxlx"
```

Open `kingdom_tycoon.rbxlx` in Roblox Studio, then start the sync server:

```bash
rojo serve
```

In Studio, open the Rojo plugin and click **Connect**. Edit scripts in VS Code; changes sync into Studio live.

More help: [Rojo documentation](https://rojo.space/docs).

## Project structure

Current Layer 1 implementation includes Play/Settings entry, touch claim and farm
start, four farm droppers, timber walls, two Mint lanes with eight droppers and
eight doubling arches each, shared collection, three permanent Shop offers,
same-plot rebirth, optional courtyard purchases and a timed practice course.
The custom server leaderboard ranks Lifetime Gold and shows Rebirths; global
rankings remain deferred. The UI uses Arcade lettering, royal-blue launchers and
gold trim. Ranks sits beside Settings; the Gold badge now shares their blue fill.

Current system guides:

- [Startup menu](docs/MAIN_MENU.md), [rebirth](docs/REBIRTH.md), and [server leaderboard/schema v2](docs/SERVER_LEADERBOARD.md).
- [Optional purchases and sprint controls](docs/OPTIONAL_KINGDOM_ADDITIONS.md), [medieval courtyard/course](docs/MEDIEVAL_COURTYARD.md), and [landscaping](docs/PLOT_LANDSCAPING.md).
- [Sword animation](docs/SWORD_ANIMATION.md) and [sprint animation](docs/SPRINT_ANIMATION.md).

Royal Shop setup and testing: [docs/ROYAL_SHOP.md](docs/ROYAL_SHOP.md).

Latest continuation notes: [docs/SESSION_HANDOFF.md](docs/SESSION_HANDOFF.md).
First-action tutorial: [docs/TUTORIAL_GUIDANCE.md](docs/TUTORIAL_GUIDANCE.md).
Second Mint conveyor: [docs/SECOND_ROYAL_MINT.md](docs/SECOND_ROYAL_MINT.md).

Current eight-arch Mint chain: [docs/MINT_UPGRADER_CHAIN.md](docs/MINT_UPGRADER_CHAIN.md).

First Mint upgrader prototype: [docs/MINT_UPGRADER.md](docs/MINT_UPGRADER.md).

Royal Mint progression and verification: [docs/ROYAL_MINT.md](docs/ROYAL_MINT.md).
Current raised-dropper assets: [docs/ROYAL_MINT_REVISION.md](docs/ROYAL_MINT_REVISION.md).
Three-track music rotation: [docs/MUSIC_PLAYLIST.md](docs/MUSIC_PLAYLIST.md).

Wooden wall asset contract and verification: [docs/WOODEN_WALLS.md](docs/WOODEN_WALLS.md).

```text
src/
├── server/                         → ServerScriptService.Server (Script)
│   ├── init.server.luau            # thin server bootstrap
│   ├── Data/
│   │   ├── DataSchema.luau         # defaults, validation, detached copies
│   │   └── DataMigrations.luau     # versioned preparation; sequential migration registry
│   ├── Services/
│   │   ├── PresentationService.luau # Gold/readiness/Lifetime Gold presentation
│   │   ├── DataService.luau        # server-only player sessions and validated updates
│   │   ├── EntryService.luau       # startup Play validation and character entry
│   │   ├── PlotService.luau        # server-authoritative claims, template clones, respawns, cleanup
│   │   ├── FarmService.luau        # wheat production, pit accounting, owner gold collection, cleanup
│   │   ├── TrainingCourseService.luau # server-owned timed practice and recovery
│   │   ├── PurchaseService.luau    # owner-only purchase plates and saved unlocks
│   │   ├── EntitlementService.luau # server-owned Roblox pass entitlements
│   │   ├── ShopService.luau        # pass lookup and validated collection requests
│   │   ├── RebirthService.luau     # validated same-plot reset and multiplier
│   │   ├── EquipmentService.luau   # non-damaging sword and validated swing
│   │   ├── SprintService.luau      # authoritative stamina/speed and sprint state
│   │   └── ExampleService.luau     # startup example; no gameplay
│   ├── Plots/
│   │   └── PlotRegistry.luau       # non-yielding session ownership and exclusivity
│   ├── Farms/
│   │   ├── ProducerScheduler.luau  # bounded multi-dropper timers and fair capacity sharing
│   │   ├── SessionEarnings.luau    # shared farm/Mint session balance and collection
│   │   └── FarmLedger.luau         # private session earnings, cap, expiry, exactly-once bundle credit
│   └── Tests/
│       ├── DataLayerTests.luau     # opt-in Studio checks; never runs in published servers
│       ├── PlotServiceTests.luau   # ownership, validation, rollback, clone/release/reclaim checks
│       ├── ProductionTests.luau    # pure scheduler checks
│       ├── PurchaseServiceTests.luau # opt-in authored farm progression checks
│       └── FarmServiceTests.luau   # standalone accounting and opt-in physical collection checks
├── client/                         → StarterPlayer.StarterPlayerScripts.Client (LocalScript)
│   ├── UI/                        # HUD, Settings, Shop, Rebirth, menu and stamina views
│   ├── Movement/                  # sprint input, animation gating and helpers
│   ├── UI/LeaderboardView.luau    # compact custom server Tab rankings and portraits
│   ├── UI/LeaderboardState.luau   # stable lifetime Gold sorting and formatting
│   ├── init.client.luau            # thin client bootstrap
│   └── Controllers/
│       ├── PlotController.luau     # claim guidance and server feedback; no authority
│       ├── HudController.luau       # compact Gold display and Settings view
│       ├── SettingsController.luau  # session preferences and menu exclusivity
│       ├── ShopController.luau      # pass UI and validated collection requests
│       ├── RebirthController.luau   # reset confirmation and multiplier UI
│       ├── LeaderboardController.luau # connected-player rankings and headshots
│       ├── EquipmentController.luau # sword input and animation presentation
│       ├── SprintController.luau    # sprint requests and stamina HUD
│       ├── SprintAnimationController.luau # sprint locomotion visual layer
│       ├── TrainingCourseController.luau # timer/checkpoint presentation
│       ├── WorldTypographyController.luau # Arcade font on authored signs
│       ├── AudioController.luau     # music/world volume
│       ├── GraphicsController.luau  # reversible local quality reduction
│       ├── PurchaseGuidanceController.luau # affordable first-action gold tutorial trail
│       ├── MainMenuController.luau # startup menu and Play/Settings presentation
│       ├── CameraController.luau   # R camera lock, restoration, respawn handling
│       └── ExampleController.luau  # startup example; no gameplay
└── shared/                         → ReplicatedStorage.Shared (Folder)
    ├── HudConfig.luau              # royal HUD palette, trim, defaults and music
    ├── ShopConfig.luau             # three offers, permanent pass IDs (unset)
    ├── RebirthConfig.luau          # targets, multipliers and reset presentation
    ├── LeaderboardConfig.luau      # compact launcher, trophy and panel sizing
    ├── MainMenuConfig.luau         # entry menu copy and presentation
    ├── EquipmentConfig.luau        # sword controls, grip and free animation
    ├── SprintConfig.luau           # speed/stamina, Shift timing and animation
    ├── TrainingCourseConfig.luau   # checkpoint and recovery limits
    ├── TutorialConfig.luau         # first-action progression and arrow trail
    ├── Config.luau                 # shared constants, including MAX_ARMY_SIZE = 10
    ├── FarmConfig.luau             # starter farm tuning and opt-in test switch
    ├── MintConfig.luau             # eight Mint producers, coin value and physics caps
    ├── PurchaseConfig.luau         # prices, prerequisites, and purchase plate settings
    ├── PlatePresentation.luau      # compact plates and centered hovering text labels
    ├── Logger.luau                 # typed, scoped Info/Warn logging
    ├── Types.luau                  # Lifecycle and PlayerData type contracts
    └── Hello.luau                  # retained template module; unused
Packages/                          → ReplicatedStorage.Packages (generated, ignored)
ServerPackages/                    → ServerScriptService.ServerPackages (generated, ignored)
tools/BuildPlotScene.luau            # one-time Edit-mode scene builder; not synced or run in-game
tools/BuildStarterFarm.luau          # approved one-time farm asset recipe; preserves existing art
tools/BuildKingdomLayout.luau        # full-platform revision; archives the original scene
tools/RefineFarmPlates.luau          # circular plate style and front farmer; archives prior assets
docs/KINGDOM_LAYOUT.md              # current plot/farm contract, activation, copying and verification
docs/MILESTONE_1_3.md                # plot contract, architecture, and verification
docs/MILESTONE_1_4.md                # farm contract, camera/spawn behavior, tests and acceptance
tools/BuildFourDropperFarm.luau      # one-time four-slot farm revision; archives original template
docs/MILESTONE_1_6.md                # four-droppers, shared collection, installed geometry and checks
```

`init.*` makes each source directory a script with child folders rather than a plain
Folder. Studio copies the client bootstrap and its children into each player's
`PlayerScripts` when they join. Shared code is replicated to clients; server code
and server-only packages stay on the server.

Each bootstrap requires an explicit ordered list of services/controllers, calls
all `Init()` functions, then all `Start()` functions in the same order, and logs
`Ready` only if startup succeeds. The ordered lists in
[src/server/init.server.luau](src/server/init.server.luau) and
[src/client/init.client.luau](src/client/init.client.luau) are authoritative.
DataService initializes before gameplay services; Settings initializes before
client menus and movement. Player profiles load asynchronously, so
server `Ready` does not mean a particular player's data is ready.
Modules must keep top-level code and `Init()` free of gameplay side effects;
`Start()` should return promptly. There is no server/client ordering guarantee.

Wally pins server-only ProfileStore 1.0.3. Before the first build/serve, run:

```bash
aftman install
wally install
mkdir -p Packages ServerPackages
```

The generated directories are outside `src/` to keep installed code separate from
authored code. The explicit `mkdir` covers empty dependency sets. Keep `wally.lock`
in version control; never hand-edit code inside package directories.
If Rojo was already connected before initialization, reconnect it to apply the
package folders. If reconnecting still omits ServerPackages, restart `rojo serve`
after `wally install` and reconnect to the fresh server.
See [AGENTS.md section 11](AGENTS.md#11-commands) for exact macOS tool installation,
formatting, linting, build, and sync commands. A fresh `rojo build` creates a
code-only place; it does not include the Studio-built map or lighting.

**Sync ownership:** Workspace (including the former template Baseplate) and
Lighting are not mapped. Unknown instances at the DataModel and mapped service
boundaries are preserved. The named `Server`, `Client`, `Shared`, `Packages`, and
`ServerPackages` containers and their descendants are source-owned: matching
content can be overwritten/replaced and unknown descendants removed. Keep
Studio-authored assets outside those containers. SoundService still maps
`RespectFilteringEnabled = true`, so sync can overwrite a different Studio value.
Save a copy of an existing place and review the Rojo sync diff before applying;
removing mappings during an existing sync may produce removal operations for
previously managed instances. No Studio assets are required by milestones 1.1–1.2.

On Play, expect these lines (server/client pairs may interleave):

```text
[KingdomTycoon][DataService] Started (Mock, store KingdomTycoon_PlayerData_Test)
[KingdomTycoon][ExampleService] Started
[KingdomTycoon][ServerBootstrap] Ready
[KingdomTycoon][ExampleController] Started
[KingdomTycoon][ClientBootstrap] Ready
[KingdomTycoon][DataService] Profile loaded for <userId> (schema 2, Mock)
```

### Data layer (milestone 1.2)

Current player data: `SchemaVersion = 2`, `Gold = 0`, `LifetimeGold = 0`,
`Rebirths = 0`, `PurchasedBuildings = {}` (building ID → boolean). Valid v1 saves
migrate by initializing LifetimeGold from banked Gold; prior spending cannot be
reconstructed. Successful banking increments both balances atomically. Purchases
and rebirth preserve LifetimeGold. DataService remains the only gameplay data
access path; PresentationService exposes selected read-only attributes to clients.
See [the server leaderboard guide](docs/SERVER_LEADERBOARD.md) for migration and
rollback limits. Rebirth/Shop/Sprint remotes are runtime-created and server-validated.
See [the farm contract and verification guide](docs/MILESTONE_1_4.md) for assets,
production, collection, camera lock, five-second spawn shields, and test instructions.

Only server services should call `DataService.GetSnapshot(player)` or
`DataService.Update(player, function(draft) ... end)`. Snapshots are detached;
updates validate a detached draft and commit only if the callback succeeds,
does not yield, and the profile/revision remains active. Both return a reason
when data is unavailable or rejected. Never retain or expose ProfileStore profiles.
Future gameplay services must wait for a successful snapshot before acting.

ProfileStore holds a **session lock** so competing servers cannot normally edit
the same player simultaneously. It handles periodic autosaves (its default
300-second interval), final saves, retries, and lock release. DataService ends
sessions on player departure/shutdown and blocks further updates when ownership
ends. Load failure or unexpected session loss removes the player rather than
letting them play with temporary progress. Save outages can still lose recent
progress: shutdown waits up to 25 seconds and reports unconfirmed saves honestly.

`Config.DATA.STUDIO_MODE` defaults to `"Mock"` (in-memory; resets between Play
sessions). `"Persistent"` in Studio always uses `KingdomTycoon_PlayerData_Test`.
Published servers always use `KingdomTycoon_PlayerData`, regardless of Studio
mode. Persistent mode refuses ProfileStore's unavailable-API fallback. Never
point Studio at the live store. ProfileStore may emit an API-access warning even
in Mock mode while probing availability; mock tests do not require enabling access.

Schema versions belong to **each saved player record**, not a single database-wide
flag. On a future schema change, increment the current version, add a sequential
N → N+1 step to DataMigrations, update Types/defaults/validation, and test with
representative old records. Players migrate when their records load. The current
registry includes v1 → v2; missing, corrupt, newer, or unsupported data is rejected,
not silently reset. Migration preparation operates on a copy. Do not deploy
schema-v1-only code after v2 records have been saved.

Persistent loading performs one extra raw DataStore read to reject malformed
ProfileStore envelopes before its repair path, then validates the locked profile.
That preflight is not atomic with locking; it is not protection against concurrent
external data edits. The extra read/join and snapshot/draft copying are deliberate
safety costs. No per-frame server loops were added.

Verification:

1. Keep Studio mode `"Mock"`, set `RUN_TESTS_IN_STUDIO = true` in Config on disk,
   sync, and press Play. Expect schema/default/migration checks, service isolation and
   mutation checks, mock storage verification, and `All mock data-layer checks passed`.
   Tests restore the original player data after their mutations.
2. Stop Play. Expect `Final save confirmed for <userId> (Mock)`. This confirms a
   mock write, not a durable Roblox DataStore write. Restore the test switch to false.
3. For an optional durable fixture test, use a published **test place** with
   Studio API access enabled. In the Server command bar during Play, run
   `require(game.ServerScriptService.Server.Tests.DataLayerTests).RunStorage(true)`.
   Record its `Verify_...` key, stop/restart Play, then call
   `RunStorage(true, "Verify_...")` with that exact key. The second call is read-only.
   These fixtures write Gold 77 only under unique non-player keys in the test store;
   they remain there. Do not use real player keys for fixtures.
4. To check the actual player persistent-load path, switch Studio mode to
   `"Persistent"` with the test switch false, then Play → Stop → Play. Check load
   and final-save messages say Persistent. Restore `"Mock"` afterward. A successful
   cross-session fixture check is required before treating persistence as verified.

Run the full suite through the bootstrap switch, not a command-bar/MCP require:
command/plugin contexts can have separate ModuleScript caches and therefore see
an uninitialized DataService. Schema-only and standalone fixture checks do not
depend on that running service context.

## Roadmap

- [ ] **Layer 1: Core tycoon** (dropper, collector, farms, shop, rebirth, saving, leaderboards)
  - [x] 1.1 Project setup
  - [x] 1.2 Data layer (mock runtime and durable persistence verified)
  - [x] 1.3 Plot system ([full-platform touch claim, release, and reclaim verified in Studio](docs/KINGDOM_LAYOUT.md))
  - [x] 1.4 Starter farm/dropper loop ([solo and multiplayer Play acceptance verified in Mock mode](docs/KINGDOM_LAYOUT.md))
  - [x] 1.5 Purchase buttons (installed farm/Mint/optional unlocks; progressive plates verified in Mock)
  - [ ] 1.6 Farms ([four-dropper assets installed and saved; purchase/farm suites passed; broader acceptance pending](docs/MILESTONE_1_6.md))
  - [ ] 1.7 HUD + settings ([implemented; focused cursor/touch acceptance pending](docs/MILESTONE_1_7.md))
  - [ ] 1.8 Shop + gamepasses ([three-pass implementation; real pass setup and live purchase acceptance pending](docs/ROYAL_SHOP.md))
  - [ ] 1.9 Rebirth ([implemented; durable rejoin/device acceptance pending](docs/REBIRTH.md))
  - [ ] 1.10 Leaderboards ([server Tab panel and Lifetime Gold implemented; global rankings deferred](docs/SERVER_LEADERBOARD.md))
  - [ ] 1.11 Polish + playtest (analytics, exploit pass and broader playtesting pending)
- [ ] **Layer 2: Open world** (horses, NPCs, outposts, opt-in PvP, bounties)
- [ ] **Layer 3: Armies and defense** (formations, base defense)
- [ ] **Layer 4: Houses and dragons** (alliances, server-wide buffs, cosmetic dragons)

## License

TBD

Second Royal Mint lane: [asset contract, economy and verification](docs/SECOND_ROYAL_MINT.md).
