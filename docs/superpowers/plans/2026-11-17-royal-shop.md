# Royal Shop Implementation Plan

Approved source: conversation and royal shop concept, 2026-11-17.

Implement Collect Now (49), 2× Gold (99), Auto-Collect (149), all permanent passes.
Dedicated royal Shop panel; Collect Now owners alone see remote collection HUD.
2× applies at arrival, old pending balance unchanged; Auto banks once per existing
production tick and upon confirmation, retains failed credits. Server validates
ownership, state and cooldown. Roblox ownership is authoritative; schema stays v1.
Missing live pass IDs disable sales. Studio Mock preview simulates purchases only.

Commits: ownership/config/tests; economy/security/tests; artwork/HUD/tests;
preview/documentation/verification. Keep map and Rojo mappings unchanged.

## Execution ledger
- Branch: feat/royal-shop-gamepasses, created and verified before edits.
- Existing main is clean. Known strict plate-label diagnostics predate this work.
- Use current checkout as approved: active Rojo sync must follow these sources.
- Task 1: complete — ownership RED→GREEN, fresh Studio module tests, lint/build passed; ac343dd.
- Task 2: complete — economy RED→GREEN and fresh engine tests passed; no schema/mapping changes.

- Task 3: complete — royal atlas uploaded83808747914581, native shop purchase and Collect Now click verified; client/menu tests pass; e4e4287.
- Review: fresh reviewer found two preview lifecycle races; corrected and tested (a048bab). No live security/economy issue found.
- Ruling: paid banking must advance tutorial collection only for contributing sites — preserves existing guidance rather than introducing a new tutorial; failing test reproduced and passed after fix (91f0faf).
- Task 4: Studio Mock fixture, regression driver, pass setup and asset docs implemented. Final sequential regression suite passed; handoff pending normal save and test-stage verification.
- Performance: automatic banking reuses production ticks and combines sites; successful automatic deposits do not spam Output. Failed deposits retain balance and use bounded retries.
- External limit: actual Roblox pass IDs are not provided. Live sales stay unavailable; preview never charges Robux. Device/two-player/real-purchase acceptance remains explicit.

- Task 4: complete — normal Edit cloud version114 saved with tests/preview off; final native Mock preview purchase/Auto-Collect checks passed, reset unowned, Shop left open.
- Handoff limitation: Studio MCP exposes only Client/Server during Play, so unsaved Edit preview flag cannot be cleared until stopping. Saved cloud version114 is clean; documented clear-before-normal-session step.
