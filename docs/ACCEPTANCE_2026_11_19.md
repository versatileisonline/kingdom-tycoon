# Layer 1 acceptance — 2026-11-19

## Baseline and execution ledger

- Approved scope: test existing behavior and repair demonstrated defects; no new features, live purchases, plot/capacity changes, push or publish.
- Branch: `chore/layer-1-acceptance-20261119`, based on `b2ec9b1`; initial working tree clean.
- Work in the existing Rojo-connected checkout on its dedicated branch; separate integration task owns the main worktree. Studio access coordinated with that task's player reset.
- Initial Studio: Play, Mock, one plot, capacity 60. Edit attributes: `StudioTutorialPreview=true`, `StudioPreviewFrontier=StoneWalls`, `StudioPreviewGold=50000`.
- Static baseline: `selene src` (0 errors/warnings), `stylua --check src`, and code-only `rojo build default.project.json -o /private/tmp/kingdom-acceptance-20261119.rbxlx` passed.

## Checks

Acceptance is in progress. Historical results are not counted as fresh evidence.

## Known release blockers and limits

- One claimable plot versus capacity 60: simultaneous kingdom ownership and two-kingdom load testing are not established. Adding plots/changing capacity requires a separate decision.
- All three Shop pass IDs are zero. Live purchases and durable real-pass ownership cannot be accepted without pass setup; no Robux purchase is part of this pass.
- Physical mobile/gamepad and full-server load require appropriate devices/clients. Synthetic leaderboard rows do not prove multiplayer behavior.

## Final state

Pending completion of checks and restoration of temporary test settings.
