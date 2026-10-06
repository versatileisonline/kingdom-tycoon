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

# build the place from scratch
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
│   └── Services/
│       └── ExampleService.luau     # startup example; no gameplay
├── client/                         → StarterPlayer.StarterPlayerScripts.Client (LocalScript)
│   ├── init.client.luau            # thin client bootstrap
│   └── Controllers/
│       └── ExampleController.luau  # startup example; no gameplay
└── shared/                         → ReplicatedStorage.Shared (Folder)
    ├── Config.luau                 # shared constants, including MAX_ARMY_SIZE = 10
    ├── Logger.luau                 # typed, scoped Info/Warn logging
    ├── Types.luau                  # startup type contract; future types go here
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
`Ready` only if startup succeeds. Currently each list contains one example.
Modules must keep top-level code and `Init()` free of gameplay side effects;
`Start()` should return promptly. There is no server/client ordering guarantee.

Wally is configured without dependencies. Before the first build/serve, run:

```bash
aftman install
wally install
mkdir -p Packages ServerPackages
```

The generated directories are outside `src/` to keep installed code separate from
authored code. The explicit `mkdir` covers empty dependency sets. Keep `wally.lock`
in version control; never hand-edit code inside package directories.
If Rojo was already connected before initialization, reconnect it to apply the
new empty package folders.
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
previously managed instances. No Studio assets are required by milestone 1.1.

On Play, expect these lines (server/client pairs may interleave):

```text
[KingdomTycoon][ExampleService] Started
[KingdomTycoon][ServerBootstrap] Ready
[KingdomTycoon][ExampleController] Started
[KingdomTycoon][ClientBootstrap] Ready
```

## Roadmap

- [ ] **Layer 1: Core tycoon** (dropper, collector, farms, shop, rebirth, saving, leaderboards)
- [ ] **Layer 2: Open world** (horses, NPCs, outposts, opt-in PvP, bounties)
- [ ] **Layer 3: Armies and defense** (formations, base defense)
- [ ] **Layer 4: Houses and dragons** (alliances, server-wide buffs, cosmetic dragons)

## License

TBD
