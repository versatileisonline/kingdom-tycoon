# Kingdom Tycoon: Game Design Document

> Status: DRAFT v0.1. Paste this at the start of every AI coding session. Update the Decision Log as things change.

## 1. Pitch
A medieval knight tycoon with a Game of Thrones feel. Players build a kingdom with droppers, farms, and walls, rebirth for multipliers, then ride horses across a large open world to other kingdoms for outposts, loot, and opt-in PvP. Later: small guard armies, base defense, houses (alliances), and cosmetic dragons.

**Design pillars**
1. Satisfying, addictive early loop (numbers go up, something to buy every 10-30 seconds).
2. A reason to leave your base (outposts, loot, bounties).
3. Fair: no pay-to-win, no overthrowing other players' bases.
4. Clean, readable UI (zoomed-out readable, clear purpose labels).

## 2. Goals beyond the game (portfolio)
- Professional workflow: Rojo + VS Code + Git, typed Luau, README, architecture diagram.
- Robust data: session-locked saving (ProfileStore), data versioning and migrations.
- Server-authoritative: validate every purchase, attack, and toggle on the server.
- Global leaderboards (OrderedDataStore): KOs, rebirths, gold.
- Cross-server features later (MessagingService / MemoryStore).
- Analytics: D1/D7 retention, session length, funnel drop-off. Report only real numbers.
- Documented performance work (NPC and army caps, client-side visuals).

## 3. Technical rules for AI-generated code
- Luau only. Use `task.wait()`, `task.spawn()`, `task.delay()`; never `wait()`, `spawn()`, `delay()`.
- Server-authoritative. Clients send requests, the server validates. Never trust client values.
- Modular: ModuleScripts for services/controllers, thin entry scripts.
- Use `--!strict` type annotations where practical.
- No deprecated APIs. If unsure an API is current, say so.
- Explain briefly what each file does and where it goes in the Rojo tree.
- One system per prompt; do not rewrite unrelated files.

## 4. Roadmap

### Layer 1: Core tycoon (first release)
| # | Milestone | Notes |
|---|-----------|-------|
| 1.1 | Project setup | Rojo, Git, folder structure, README |
| 1.2 | Data layer | ProfileStore, schema + version field, autosave, leave-save |
| 1.3 | Plot system | Assign/claim plot, spawn kingdom template, cleanup on leave |
| 1.4 | Dropper loop | Dropper spawns gold, conveyor, collector converts to currency |
| 1.5 | Purchase buttons | Floor buttons with dependency tree; green = affordable, red = not; labels readable zoomed out |
| 1.6 | Farms | Early passive gold; upgrades |
| 1.7 | HUD + settings | Currency display, helper arrow (toggle), low-graphics mode, medieval music |
| 1.8 | Shop + gamepasses | 2x gold, auto-collect, cosmetics; server-validated receipts |
| 1.9 | Rebirth | See section 5; UI explains purpose and shows multiplier |
| 1.10 | Leaderboards | Tab: KOs, rebirths, gold; global OrderedDataStore boards |
| 1.11 | Polish + playtest | Analytics events, exploit pass, 20-50 playtesters |

### Layer 2: Open world
Large map with multiple kingdoms, horses, roaming NPCs, opt-in PvP (2-minute toggle cooldown), spawn protection, bounty system, capturable outposts.

### Layer 3: Armies and defense
Small guard formations (follow, line, ring; formation shown on left of screen), basic base defense.

### Layer 4: Houses and dragons
Houses (alliances), outpost control with server-wide buffs, cosmetic dragons.

## 5. Systems

### Economy and rebirth
- Rebirth resets the current kingdom (buildings, gold) but grants a permanent multiplier.
- Starting model: cost grows ~2-3x per rebirth; multiplier +0.5x per rebirth. Tune in a spreadsheet from playtest data.
- Optional later: persistent "Royal Favor" currency for permanent upgrades.
- Rebirth UI must state what resets, what persists, and the multiplier.

### PvP
- Opt-in toggle with 2-minute cooldown; server-enforced.
- High risk/high reward in PvP zones (bonus gold, rare drops).
- Players lose only gold they are carrying, never banked gold.
- Spawn protection; bounty system on repeat killers.
- Cannot attack or overthrow another player's home kingdom.

### Combat (Layer 2)
Regular knights use swords. Server validates hits.

### Armies (Layer 3)
- Cap 10 soldiers per player.
- Simple server AI; consider client-side visuals.
- Formations: line or ring around the player.

### Houses (Layer 4)
- Hold outposts for server-wide buffs.
- Buff starts at 5-10% (not 20%); earned, not purchased; economic or modest combat.

### Dragons (Layer 4)
- Cosmetic only: colors, breath effects. No combat advantage.
- Possibly bought with an outpost currency earned by participation (not wealth). Level-banded outposts to protect newer players.

### NPCs
Roaming ambient NPCs; counts capped per server for performance.

## 6. UX and presentation
- Floor icons with header labels stating purpose.
- Green = purchasable, red = not; legible when zoomed out.
- Leaderboard tab: KOs, rebirths, gold, (army size later).
- Helper arrow toggle in settings; low-graphics mode in settings.
- Medieval music.

## 7. Monetization rules
- Allowed: 2x gold, auto-collect, cosmetics (dragons, skins, trails).
- Not allowed: damage boosts or any PvP-power purchases.

## 8. Open decisions
- [ ] Final game name
- [ ] Outpost currency name and exact uses
- [ ] Alliance buff type and size
- [ ] Rebirth numbers (needs playtesting)
- [ ] Level bands for outposts
- [ ] Which analytics tool/events to log

## 9. Decision Log
- Build in four releasable layers.
- Dragons are cosmetic only.
- No damage-boost gamepass.
- No overthrowing other players' kingdoms.
- Use Rojo + Git workflow.
- Army cap is 10 soldiers per player.
- Milestone 1.1: keep the existing init-script layout, use explicitly ordered
  Init/Start services and controllers, and retain the unused Hello template.
- Milestone 1.1: keep Wally-generated Packages and ServerPackages at the repo root;
  add no gameplay dependencies yet. Retain Aftman and pin formatting/lint tools.
- Milestone 1.1: leave Workspace and Lighting under Studio ownership by removing
  the template Workspace/Baseplate mapping and Lighting property overrides;
  preserve the existing SoundService setting.
- Milestone 1.2: persist progress automatically with ProfileStore now, rather than
  adding a manual save button or deferring saving. Initial schema version is 1,
  with zero Gold, zero Rebirths, and an empty PurchasedBuildings dictionary.
- Milestone 1.2: Studio defaults to in-memory mock data; opt-in persistent testing
  uses a separate test store, never live player data. Invalid/future data and load
  failures stop access rather than silently resetting progress.
- Approved early-loop direction (future milestones, not implemented in 1.2):
  plot claim provides a free starter farm producer; one outside farm and its
  required upgrades unlock the Royal Mint inside the kingdom. Collectors display
  unclaimed earnings and reset on collection; physical props are removed after
  their value reaches the collector. Walls progress from wooden to stone;
  defenses come later.
