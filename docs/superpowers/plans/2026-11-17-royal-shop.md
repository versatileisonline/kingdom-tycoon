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
