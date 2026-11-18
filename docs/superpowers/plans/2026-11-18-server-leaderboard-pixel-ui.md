# Royal leaderboard and pixel typography implementation

Approved in conversation: custom server-only upper-right Tab player list matching
the generated royal mockup, player portraits, rank, Lifetime Gold and Rebirths;
local highlight. Global rankings deferred. Use starter menu Arcade throughout HUD
and world labels; creator then requested two-point larger/heavier pixel text.

- [x] Centralize font, migrate existing UI/labels, adjust readability; commit separately.
- [x] Schema v2 LifetimeGold, validated v1 migration from banked Gold, atomic shared
  banking increment and presentation attribute; local migration/transaction checks.
- [x] Controller/view/pure state, Tab/X/touch launcher, native list disable,
  avatar lifecycle, menu/camera/sprint integration, compact layout; pure tests.
- [x] Independent review, formatting/lint/build and task documentation.
- [ ] Manual Studio render/multi-client/persistent TEST-store acceptance (automation denied).

No source-owned mapping changes, no Studio model edits, no global data store.
Keep all authorized work in modular commits on feat/server-leaderboard-pixel-ui;
no push. Preserve concurrently authored courtyard changes.
