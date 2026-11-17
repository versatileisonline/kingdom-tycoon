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
- Mint plate clearance (2026-11-17): creator requested moving dropper and upgrader
  purchase rows left on both belts to clear lamp posts. Shift 30 plates four studs
  left; preserve entry plates, collectors, production and prices.
- Second Mint lane (2026-11-17): approved cloning the complete first lane into the
  reserved right-hand space, eight droppers then eight doubling arches after the
  original final upgrader. Approved 12000 opening price and the explicit steady-buy
  curve in docs/SECOND_ROYAL_MINT.md. Subsequently increased base coins to 9 Gold
  (three times first-lane value) for an intentionally generous experimental economy;
  prices stay fixed. Ends at the last arch; floor two is separate. Approved a
  backed-up one-time Studio clone recipe, isolated branch and shared collection.
- Royal HUD refresh (2026-11-17): approved royal blue banner headings, sculpted
  antique gold corners outside dark panels, brass controls and a prominent coin
  badge. Approved custom transparent artwork and its resulting coin/corner/banner
  images before Roblox import. Reuse the coin in HUD, purchase/collector labels
  and Mint faces; farm wheat stays. Combine with the concurrent upgrader work for
  viewing; preserve progression, economics, settings behavior and session defaults.
- Full Mint upgrader chain (2026-11-17): creator accepted prototype and requested
  a gold holographic laser curtain through each opening, then all eight arches.
  Confirmed curve 250/300/400/600/1000/1900/3800/7500, sequential after all droppers.
  Each arch doubles every passing coin once. Extend the belt/collector to clear
  the final arch; preserve the template in a one-time backed-up Edit recipe.
  Finish at a temporary Mock stage with 20,000 Gold to buy/verify the whole chain.
- First Mint upgrader (2026-11-17): approved one playable prototype, priced 250 Gold
  after all eight droppers. Reuse the approved blue/iron/gold arch with amber
  inset, crown emblem and small ×2 label. Passing coins double once 3 -> 6 and become
  brighter gold without physics changes. Build with a backed-up Studio recipe.
  Plan for eight identical arches later; fast escalating prices are preferred
  over long waits. Remaining seven prices are provisional, not live purchases.
- Mint refinement (2026-11-17): fix intermittent coin loss first; move the first
  production lane left and reserve space for a later parallel conveyor. Use fuller
  housed gold droppers, raised to visibly drop coins onto the belt. Add three free
  medieval/kingdom music tracks in rotation. Keep the current prices and rates.
  Horse riding is a separate milestone. Future progression discussed: all eight
  droppers, then eight pass-through upgraders, then conveyor two. Each upgrader
  doubles each passing coin once, so later downstream arches affect more streams.
  Decorative/showcase purchases may begin after Dropper 3; their content, order,
  prices and the upgrader prices remain for separate planning, not this fix.
- Royal Mint (2026-11-17): approved the revised open-air concept: long conveyor,
  stone-paved yard, gold-and-iron presses and royal timber/brass decoration, no
  roof. WoodenWalls unlocks RoyalMint for 60 Gold including the complete yard
  and first press. Eight total presses cost 60/70/90/110/130/150/170/190 Gold;
  each yields 3 Gold every three seconds. Farm and Mint share one uncollected
  balance; either collector collects the total. Only the next purchase is shown.
  Approved a backed-up one-time Studio Edit recipe. Background gate/wall art
  remains inspiration rather than part of this build.
- Plate label revision (2026-11-16): approved centered hovering two-line labels:
  purchase name then configured price with the HUD's gold-colored ●; collector
  Collect: then current amount with the same ●. Supersedes the prior name-only
  purchase text and bare collector amount. Existing prices stay unchanged.
- Wooden walls (2026-11-16): prioritize completing the initial tycoon before
  shop/gamepasses. After FarmDropper04, buy the entire timber palisade for 40 Gold
  within the existing 216 × 216 interior reservation; preserve the outside farm
  and open 24-stud entrance. Approved a one-time backed-up Studio asset recipe.
  Later stone walls, defensive posts/towers, defenders and decorations build on
  this progression; defensive additions are visual for now. Later wall materials
  remain undecided. Indoor production and all later upgrades are separate tasks.
- Milestone 1.7 (2026-11-16): approved a sparse rounded brown/gold HUD template
  inspired by the supplied reference, with a playful but restrained feel. Gold badge
  lower left and Settings upper right. Session-only music/world volume, helper-arrow
  and low-graphics preferences; defaults 25%/100%/on/off. Free Creator Store medieval
  music may be selected by the agent. Replace the large instruction card with brief
  contextual hints. Shift lock uses a circle with four short cardinal ticks while
  active, restoring the native pointer in menus. The creator requested replacing
  the initial custom overlay with Roblox's built-in locked cursor to resolve centering.
  No camera zoom/FOV change. Approved
  feature-branch pushes followed by verified integration and push to main.
- Purchase presentation refinement (2026-11-15): approved progressive disclosure
  for all purchase progression: only the next purchase plate appears; buying
  removes it and reveals the next, red when unaffordable and green when affordable.
  Hide future unowned producers; keep purchased ones. Hide claim/start plates after
  use. Use smaller 4-stud plates and small bold text-only labels hovering over each
  plate's center, with no background box or surface text. Name paid farm purchases
  Dropper 2/3/4, with one light introductory arrow only over Dropper 2. Collector
  label is Collect followed by its amount on a new line. This supersedes earlier
  verbose name/price/reason purchase labels; prices and server validation stay unchanged.
- Milestone 1.6 visual integration (2026-11-15): explicitly requested implementing
  and saving the previously specified four-dropper farm visuals in the cloud
  Kingdom Tycoon place. Reuse the existing machinery and plate style, retain one
  decorative farmer, shared collector, fixed farm boundary and wall reservations.
  Archive the original template before applying the one-time Studio Edit recipe.
- Milestone 1.6 outside farm (2026-11-15): approved one farm with one decorative
  farmer and a fixed conveyor sized for four droppers from the outset. Start with
  one free producer; buy FarmDropper02, 03, and 04 sequentially for 6, 12, and
  24 Gold. Each produces one Gold every three seconds into one shared collector.
  Keep the free Start Farm interaction on every claim; restore owned droppers
  without repurchase. Extend the existing farm system rather than building a
  general production engine. All four droppers precede initial walls, then more
  valuable indoor production with higher prices. Target 2–3 minutes to the first
  indoor dropper, subject to later pricing and playtesting. This supersedes the
  earlier two-additional-dropper note. Walls, indoor production, and visual/layout
  changes are separate tasks; farm activation and uncollected earnings retain
  their existing session-only behavior.
- Milestone 1.4 plate/farmer refinement (2026-10-21): requested smaller matching
  circular plates with black outlines, bright green when available and red when
  unavailable. Collector color follows uncollected earnings (zero red, positive
  green). Keep the farmer directly in front of the dropper, with two additional
  droppers planned to its left in a later pass. No extra producers or purchases
  are implemented by this visual revision.
- Milestone 1.4 layout revision (2026-10-21): explicitly approved the entire
  320 × 320 demonstration meadow as one player's kingdom plot, with full-size
  plots duplicated later. One kingdom per player remains. Reserve 216 × 216
  for future wooden/stone walls and an empty interior, with a 112 × 48 farm at
  the front outside those walls and a path to the centered future gate.
  Touch a floor plate to claim, then a separate free Start Farm plate to reveal
  the farm and start production. This supersedes hold-E claiming and immediate
  farm activation on claim. Farm start is session-only in this milestone;
  general purchases/upgrades remain deferred. Approved Studio implementation of
  this layout with the original scene archived for reversal; no walls/interior
  construction or Rojo mapping changes.
- Milestone 1.4 (2026-10-21): approved interpreting the dropper loop as a free
  starter farm activated on claim: physical wheat bundles travel by conveyor to
  a pit, which credits session-only uncollected Gold. Initial tuning is one
  bundle every three seconds, worth one Gold. The living owner collects the full
  balance on a plate through DataService; failed updates preserve earnings.
  Death preserves earnings; departure discards uncollected Gold and bundles.
  No offline production. Purchases, upgrades, Royal Mint unlocking, and general
  currency HUD remain later milestones.
- Milestone 1.4: retain the existing farm footprint while building the loop;
  the developer enlarged the kingdom, with plot/baseplate layout adjustments
  deferred. Explicitly authorized the agent to create the farm assets in Studio
  and return the edited template to ServerStorage, preserving its scale and art.
  Runtime code only clones templates; the one-time asset recipe is not Rojo-mapped.
- Milestone 1.4: approved Left Shift third-person camera lock, initially unlocked,
  with typing-safe toggling and normal controls restored on unlock. Bring native
  visible five-second arrival/kingdom respawn protection forward into this milestone;
  custom shield HUD and combat systems remain deferred. Hands-on Play verification
  remains with the developer.
- Milestone 1.3 (2026-10-20): use manual entrance claiming, four plots for the
  first demonstration, and session-only plot locations. Saved progression stays
  independent of land assignment. Players respawn in their claimed kingdom;
  departure releases the plot and removes its runtime template.
- Milestone 1.3: approved one-time Studio editing commands to build the starter
  scene and template as an exception to the no-script-generated-map rule. Runtime
  code only clones the Studio template. Preserve the existing castle/landscape;
  the demonstration grounds are a separate area. The farm footprint is visual
  only; production, purchasing, and the general HUD remain future milestones.
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
