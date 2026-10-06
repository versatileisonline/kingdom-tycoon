# Kingdom Tycoon

A medieval knight tycoon for Roblox. Build a kingdom with droppers, farms, and walls, rebirth for permanent multipliers, then (in later layers) ride horses across a large open world to outposts, opt-in PvP, guard armies, houses, and cosmetic dragons.

> **Status:** Layer 1 (core tycoon) in development. See the [roadmap](#roadmap).

## Highlights (engineering goals)

These are the goals this project is built around. Items are checked off only when implemented.

- [x] Rojo + VS Code + Git workflow (code as files, not just inside Studio)
- [ ] Typed Luau with a modular service/controller architecture
- [ ] Session-locked data saving (ProfileStore) with versioned schema and migrations
- [ ] Server-authoritative purchases, rebirths, and combat validation
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

```text
src/
├── server/                         → ServerScriptService.Server (Script)
│   ├── init.server.luau            # thin server bootstrap
│   ├── Data/
│   │   ├── DataSchema.luau         # defaults, validation, detached copies
│   │   └── DataMigrations.luau     # versioned preparation; sequential migration registry
│   ├── Services/
│   │   ├── DataService.luau        # server-only player sessions and validated updates
│   │   └── ExampleService.luau     # startup example; no gameplay
│   └── Tests/
│       └── DataLayerTests.luau     # opt-in Studio checks; never runs in published servers
├── client/                         → StarterPlayer.StarterPlayerScripts.Client (LocalScript)
│   ├── init.client.luau            # thin client bootstrap
│   └── Controllers/
│       └── ExampleController.luau  # startup example; no gameplay
└── shared/                         → ReplicatedStorage.Shared (Folder)
    ├── Config.luau                 # shared constants, including MAX_ARMY_SIZE = 10
    ├── Logger.luau                 # typed, scoped Info/Warn logging
    ├── Types.luau                  # Lifecycle and PlayerData type contracts
    └── Hello.luau                  # retained template module; unused
Packages/                          → ReplicatedStorage.Packages (generated, ignored)
ServerPackages/                    → ServerScriptService.ServerPackages (generated, ignored)
```

`init.*` makes each source directory a script with child folders rather than a plain
Folder. Studio copies the client bootstrap and its children into each player's
`PlayerScripts` when they join. Shared code is replicated to clients; server code
and server-only packages stay on the server.

Each bootstrap requires an explicit ordered list of services/controllers, calls
all `Init()` functions, then all `Start()` functions in the same order, and logs
`Ready` only if startup succeeds. Server order is DataService, then ExampleService;
the client contains ExampleController. Player profiles load asynchronously, so
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
[KingdomTycoon][DataService] Profile loaded for <userId> (schema 1, Mock)
```

### Data layer (milestone 1.2)

Initial player data: `SchemaVersion = 1`, `Gold = 0`, `Rebirths = 0`,
`PurchasedBuildings = {}` (building ID → boolean). No currency earnings,
purchases, plots, UI, or data remotes are implemented yet.

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
representative old records. Players migrate when their records load. Version 1
has no historical migration steps; missing, corrupt, newer, or unsupported data
is rejected, not silently reset. Migration preparation operates on a copy.

Persistent loading performs one extra raw DataStore read to reject malformed
ProfileStore envelopes before its repair path, then validates the locked profile.
That preflight is not atomic with locking; it is not protection against concurrent
external data edits. The extra read/join and snapshot/draft copying are deliberate
safety costs. No per-frame server loops were added.

Verification:

1. Keep Studio mode `"Mock"`, set `RUN_TESTS_IN_STUDIO = true` in Config on disk,
   sync, and press Play. Expect schema checks (11 cases), service isolation and
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
  - [x] 1.2 Data layer (mock runtime verified; durable persistence check pending)
- [ ] **Layer 2: Open world** (horses, NPCs, outposts, opt-in PvP, bounties)
- [ ] **Layer 3: Armies and defense** (formations, base defense)
- [ ] **Layer 4: Houses and dragons** (alliances, server-wide buffs, cosmetic dragons)

## License

TBD
