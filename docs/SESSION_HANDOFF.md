# Kingdom Tycoon session handoff — 2026-11-18

Read AGENTS.md and GAME_DESIGN.md first. The creator approved merging the latest
HUD changes into **main**, pushing main, and refreshing project documentation.
Repository: `/Users/bryantorres/projects/roblox_projects/kingdom_tycoon`.

## Current implementation

- Startup menu: Kingdom Awaits, Play and Settings. Server-validated entry chooses
  a free plot without claiming/reserving it. Players touch Claim, then Start Farm.
- Production: four farm droppers, timber walls, two Royal Mint lanes with eight
  droppers and eight doubling arches each, shared pending earnings, progressive
  red/green purchase plates and owner-only first-action guidance.
- Optional purchases: banners, lanterns, non-damaging training sword, sprint,
  decorative paddock and fountain. The medieval courtyard includes a purchased
  timed practice course with ordered checkpoints and server fall recovery.
- Shop: permanent Collect Now49, 2× Gold99 and Auto-Collect149 Robux. Pass IDs are
  still unset, so real purchases show Unavailable. Confirm entitlements on server.
  Collect Now owners see **pending UncollectedGold**, matching all collectors,
  in the bottom-left badge; nonowners see banked Gold. Keep this distinction.
- Rebirth: banked-Gold threshold starts at100,000 and doubles; +0.5x per rebirth,
  stacked multiplicatively with the Gold pass. Same plot resets to Start Farm;
  Gold/buildings/pending production reset, passes and LifetimeGold persist.
- Leaderboard: connected server players only, Lifetime Gold ranking, Rebirths,
  headshots and local-row highlight. Tab/Ranks/X controls; global rankings deferred.
- Presentation: shared Arcade lettering on HUD and authored signs; shuffled
  three-track music; royal-blue buttons with gold trim. Ranks sits left of Settings
  with a trophy icon. Its132x52 launcher opens a92%-scale panel (about736x451).
  Short viewports reserve room for a complete player row. Shop/Rebirth now share
  the gold corner artwork, with a24px stack gap. The Gold badge is royal blue.
- Controls: R camera lock; hold Left Shift to sprint, double-tap within0.3s to lock;
  Shift again, stopping, exhaustion or interruptions cancel it. Sprint speed24,
  normal16, six-second stamina. Sword is decorative/training only, without damage.
- Woodland landscaping:16 tall exposed-trunk pines and326 decorative parts;
  prior forest variants are backed up. These assets remain Studio-owned.

Guides: [Shop](ROYAL_SHOP.md), [rebirth](REBIRTH.md),
[leaderboard/schema](SERVER_LEADERBOARD.md), [entry](MAIN_MENU.md),
[optional purchases](OPTIONAL_KINGDOM_ADDITIONS.md),
[courtyard/course](MEDIEVAL_COURTYARD.md), [landscaping](PLOT_LANDSCAPING.md),
[sword](SWORD_ANIMATION.md), [sprint](SPRINT_ANIMATION.md),
[music](MUSIC_PLAYLIST.md), [Mint lane two](SECOND_ROYAL_MINT.md).

## Data and integration

Current schema is **v2**: Gold, LifetimeGold, Rebirths and PurchasedBuildings.
Valid v1 saves initialize LifetimeGold from banked Gold; past spending cannot be
reconstructed. Banking increments both balances atomically; purchases/rebirth do
not reduce lifetime earnings. Never deploy schema-v1-only code over saved v2 data.
DataService owns all authoritative player data. Presentation attributes are
read-only UI signals, never client authority.

The latest remote main already included woodland landscaping and the Shop preview
entry fix. HUD integration preserves those changes and applies the two approved
HUD commits on top, avoiding older duplicate feature history. The preview fix
waits for KingdomEntered before claiming a plot, so Play can find free land.
Source-controlled recipes/documentation preserve asset contracts; Git/Rojo builds
do not contain the live map, templates, terrain or cloud place history.

## Studio ownership and verification

Place77311816657817, experience10769565462. Another task currently owns Studio for
an Evade-style R15 sprint animation replacement. Do not stop/restart Play, change
camera/input, save, or clear preview flags without coordinating with that task.
Its newer animation work is separate from this HUD/documentation integration.
The committed fallback remains described in SPRINT_ANIMATION.md until the sprint
replacement is independently committed. An uncommitted shared SprintConfig sync
may be present; preserve it and do not stage it in unrelated commits.

This integration authorizes **Git push**, not a Roblox publish or cloud save.
Do not treat any historical version number or fixture in older notes as current
Studio state. Inspect the active place/mode, data mode, preview flags and owner
before starting a new acceptance session. Default config is Mock and test switches
are false; runtime fixtures are temporary and do not establish live purchases.

Recent verification:

- Leaderboard: fresh Mock desktop and short-viewport checks, trophy load, exact
  launcher/panel dimensions, native Ranks/Tab/X and Settings exclusivity passed.
  Default device viewport was restored before handing Studio to the sprint task.
- Shop/Rebirth trim and Gold badge: source formatting/lint/build and runtime-only
  appearance preview passed. No restart/native menu input during concurrent sprint
  testing; fresh-Play source/bootstrap acceptance remains pending.
- Earlier subsystem suites cover data migration, collection/rebirth arithmetic,
  purchases, Mint ledgers/production, tutorial, Shop behavior, entry and course.
  See each guide for the actual test context and remaining manual acceptance.
- Full strict type analysis was not rerun for this documentation refresh. Existing
  PlatePresentation/CurrencyRow nullable diagnostics and asset203785492 warnings
  were previously recorded; do not describe the entire project as strict-clean.

For the next normal Play, expect `ServerBootstrap ... Ready`,
`ClientBootstrap ... Ready`, `LeaderboardController ... Ready (Tab toggles server
leaderboard)` and a profile load reporting schema2. Confirm all four launchers,
blue Gold badge, Shop/Rebirth open/close, and owner/nonowner collection behavior.
Full service suites must run through normal bootstrap test switches, not a plugin
require with a different ModuleScript cache. Enable one suite at a time in Mock;
restore switches/previews afterward. See AGENTS section11 and the system guides.

## Remaining acceptance and preferences

Layer1 stays in progress. Remaining work includes real pass IDs/purchases/rejoin,
server leaderboard multiplayer and durable v1 migration acceptance, device/touch
checks, economy pacing, analytics/exploit review and broader player testing.
Global rankings, rideable horses, combat, open-world systems, armies and houses
remain separately scoped. Do not resolve GAME_DESIGN open decisions implicitly.

Use small Conventional Commits, preserve unrelated work, keep one Studio owner,
and prefer short hands-on feedback. The creator wants approved work committed and
integrated into main; this session explicitly authorizes the main push. Future
unapproved features still require their own scope/plan and approval.
