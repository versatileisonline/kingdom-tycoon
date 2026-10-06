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

_To be filled in after milestone 1.1 (folder structure and bootstrap pattern)._

## Roadmap

- [ ] **Layer 1: Core tycoon** (dropper, collector, farms, shop, rebirth, saving, leaderboards)
- [ ] **Layer 2: Open world** (horses, NPCs, outposts, opt-in PvP, bounties)
- [ ] **Layer 3: Armies and defense** (formations, base defense)
- [ ] **Layer 4: Houses and dragons** (alliances, server-wide buffs, cosmetic dragons)

## License

TBD