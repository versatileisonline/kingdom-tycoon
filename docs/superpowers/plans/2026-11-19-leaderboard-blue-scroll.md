# Leaderboard blue and scrolling implementation plan

**Goal:** Apply the approved royal-blue leaderboard palette, fix clipped row outlines, and showcase the configured 60-player list.
**Spec:** Creator approved the scoped plan in chat on 2026-11-19, adding the cropped row-border fix. Existing behavior: docs/SERVER_LEADERBOARD.md.
**Architecture:** Retain the existing client view, automatic vertical canvas, controller and authoritative attributes. Add inset space within the scrolling viewport; use local palette/layout constants. No server, schema, asset, Rojo mapping or capacity changes.
**Execution:** In place on dedicated branch fix/leaderboard-blue-scroll to retain the existing Rojo connection. Implement directly; authorization already provided.

## Files
- src/shared/LeaderboardConfig.luau: blue row colors and scrolling inset/bar constants.
- src/client/UI/LeaderboardView.luau: flat royal-blue panel, alternating blue rows, inset row outlines, scrollbar clearance.
- src/client/UI/LeaderboardClientTests.luau: full-capacity sorting/update checks and an explicit engine-backed view test entry point.
- docs/SERVER_LEADERBOARD.md, AGENTS.md sections 10/11: behavior, reproducible test commands and evidence/limits.

## Review focus
- First/last outlined row remains entirely inside the viewport at its scroll endpoint.
- Sixty entries remain reachable with fixed title/headings and vertical-only scrolling.
- Name/numeric truncation does not overlap adjacent columns on narrow screens.
- Score updates, removal and loading state retain one row per player without stale entries.
- Preview data stays client-only and is clearly marked; real saved data remains untouched.

## Task 1: Palette and border regression
- [x] Reproduce the missing top stroke against the existing view (first row y equals viewport y).
- [x] Add view checks for outline clearance, full-capacity canvas and last-row reachability.
- [x] Apply scoped palette and inset changes; run engine checks, formatting/lint and build.
- [x] Commit coherent implementation and tests.

## Task 2: Showcase and documentation
- [x] Test desktop, phone landscape and short viewport; exercise native scrolling, Tab/X and menu exclusivity. Portrait excluded because the game uses LandscapeSensor.
- [x] Showcase 60 simulated entries at top/bottom; record screenshots and accurate limits.
- [x] Update authorized docs and commit; leave a clearly marked temporary Studio preview for review.

## Verification and review record

Commits a0b52c3 and f6a49aa implement the approved UI change, engine checks and
reproducible preview. Top-border regression failed before padding; compact-column
containment failed on A06 before sizing the column from the padded row width.
Both passed afterward. Suites passed desktop1429x974, A06 landscape705x338 and
short-landscape545x338. Native wheel reached rank60 on phone/desktop, native
Ranks/Tab/X and Settings exclusivity passed. Server attribute presentation was
checked and restored. Existing203785492 asset-type warnings are unrelated.

Fresh reviewer findings addressed: compact scrollbar intrusion, persistent preview
label on short viewports, synthetic ID collision with Studio negative IDs, and
fixed-header assertion timing. A fixture cache issue found during QA was resolved
by observing live GUI state instead of requiring a gameplay controller from the
Command Bar. No outstanding review findings. Review/test scope is UI simulations
plus single-client replication, not a60-client network test.
