# Kingdom Tycoon session handoff — 2026-11-18

Read AGENTS.md and GAME_DESIGN.md first. Continue from **main** in
`/Users/bryantorres/projects/roblox_projects/kingdom_tycoon`.

## Completed this session

Royal Shop and HUD refinements merged into main in9908040, preserving the modular
feature/fix/test commits. Feature branch: feat/royal-shop-gamepasses.

- Three permanent offers: Collect Now49, 2× Gold99, Auto-Collect149 Robux.
- Dedicated royal Shop panel; title centered within the blue ribbon, all three
  offer borders inset to prevent scrolling-area clipping. Transparent four-cell
  illustration atlas assets/hud/shop-atlas.png maps to83808747914581.
- Collect Now ownership converts the existing bottom-left Gold badge into a
  button. Tight centered row: gold Collect text, coin, pending amount. No separate
  CollectNowButton. Nonowners retain the original display-only Gold badge.
- Important final clarification: owned Collect amount is **UncollectedGold**,
  exactly the same shared total as floor Collect Total plates. Collection resets
  it to0; new arrivals increase all totals together. Do not change it back to saved
  Gold for CollectNow owners. HudState.DisplayGold owns the selection.
- 2× applies once when a bundle/coin arrives at its pit, after Mint arch upgrades;
  old pending earnings are unchanged. Auto-Collect banks all sites together after
  each production tick, retains failed credits and uses bounded retries. No extra
  production loop. Successful automatic deposits do not spam Output.
- Remote/automatic banking advances tutorial collection only for sites that
  contributed pending earnings. Floor collectors retain exact-site semantics.
- Roblox owns pass entitlements; server validation/rate limits remain authoritative.
  Lookup generations reject stale responses. Studio preview mode changes invalidate
  simulated grants. No schema, map/template or Rojo mapping changes.
- Fixed RoyalStyle hover Tween creation/Play expression; a separate local Tween
  avoids accidentally calling the returned Instance.

Previous accepted systems remain: four farm droppers, wooden walls, two Royal
Mint lanes with eight droppers/eight arches each, shared collection, progressive
purchase plates, animated first-action tutorial and royal HUD/settings/music.
Details: SECOND_ROYAL_MINT.md, TUTORIAL_GUIDANCE.md, ROYAL_SHOP.md.

## Studio state and testing

Place77311816657817, experience10769565462. Normal Edit state last saved as cloud
**version121**, with test switches and preview flag disabled. This is a save,
not a live publish. Assets are Studio-owned and absent from code-only Rojo builds.

Studio currently remains in **Play**, in an explicitly requested **Mock** shop
fixture: claimed Plot01, four farm/eight first-lane Mint droppers, initial25,000
Gold, CollectNow simulated ownership enabled. Last readback confirmed owned
Collect display0/pending0. Creator may continue interacting; inspect state before
resetting. No Robux charged and no real ownership/profile grants are saved.

The unsaved Edit Server.StudioShopPreview flag remains enabled for repeat tests.
Studio MCP exposes only Client/Server while playing, so clear the flag after Stop
before saving or starting a normal session. Cloud version121 is already clean.
Do not save/publish the fixture as actual progression.

To reopen: Studio Mock, all config test switches false, set Server attribute
StudioShopPreview=true in Edit, then Play. Expect:
`[KingdomTycoon][ShopPreview] Shop preview ready (Studio Mock)`.
Shop starts open with all passes unowned; preview purchase buttons grant session
benefits. Reset preview clears simulated ownership, not previously banked Gold.
The fixture ends at RoyalMintUpgrader01 with all eight first-lane droppers bought.

## Verification and limits

Fresh merged-main formatting, Selene (zero warnings/errors), code-only Rojo build,
pure HUD-state, ownership-registry and economy/ledger tests passed. Source/assets
are identical to the verified feature tip after merge.

During implementation, normal-bootstrap Mock shop service/client suites passed;
sequential existing farm, purchase, first Mint chain, second Mint lane, tutorial
and HUD suites passed. Fresh reviews found no unresolved important issues.
Native preview purchases and clicking the actual Gold badge banked earnings.
Final correction observed reset to0, then HUD/farm/Mint totals all7 on new arrivals.
Owned/unowned layout tests check4px spacing, horizontal center, vertical coin
center, title anchoring and full offer-border clearance.

Strict analysis retains the same14 unique pre-existing PlatePresentation/
CurrencyRow diagnostics; there are no new shop/HUD errors. Do not call global
strict analysis clean. Existing asset-type warning203785492 and Assistant
plugin-version warning also remain. Overflow tests intentionally reject a credit.

Live pass IDs are still **0** in ShopConfig: actual sales intentionally show
Unavailable. Create/configure the three Roblox passes and provide their IDs
before enabling live purchases. Real purchase completion/rejoin, two-player pass
isolation and full touch/device acceptance remain unverified. These limits are
not established by the Mock preview. No ProcessReceipt is required for these
permanent passes; no repeatable developer products were implemented.

Service suites run through the normal bootstrap, never by requiring live services
from plugin contexts (separate module caches). Fresh cloned config checks need the
clone parented beside its original so relative requires work; destroy it afterward.

## Next work and preferences

No additional feature implementation is approved. Creator wants shop/gamepasses,
rebirth, global leaderboards and horses prioritized for a substantial first demo;
rebirth is the next Layer1 gameplay milestone to plan. Horse is a separately scoped
feature brought forward from Layer2; do not build the whole open world implicitly.
Do not resolve open rebirth numbers or analytics decisions without asking.

Creator prefers hands-on visual testing and short feedback. Avoid repeated
screenshots/computer control unless needed. Keep one Studio owner. Continue with
small modular Conventional Commits, dedicated branch for the next milestone,
plan before non-trivial edits, and never push without an explicit request.
