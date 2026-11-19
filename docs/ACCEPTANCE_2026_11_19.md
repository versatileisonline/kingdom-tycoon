# Layer 1 acceptance — 2026-11-19

## Baseline and execution ledger

- Approved scope: test existing behavior and repair demonstrated defects; no new features, live purchases, plot/capacity changes, push or publish.
- Branch: `chore/layer-1-acceptance-20261119`, based on `b2ec9b1`; initial working tree clean.
- Work in the existing Rojo-connected checkout on its dedicated branch; separate integration task owns the main worktree. Studio access coordinated with that task's player reset.
- Initial Studio: Play, Mock, one plot, capacity 60. Edit attributes: `StudioTutorialPreview=true`, `StudioPreviewFrontier=StoneWalls`, `StudioPreviewGold=50000`.
- Static baseline: `selene src` (0 errors/warnings), `stylua --check src`, and code-only `rojo build default.project.json -o /private/tmp/kingdom-acceptance-20261119.rbxlx` passed.

## Checks

Fresh checks in this pass (historical results are not counted):

| Result | Evidence and limits |
| --- | --- |
| PASS | Normal Mock server/client bootstrap, schema2 profile load and native Play entry without claiming. |
| PASS | Stronghold purchase/replacement, ward policy/owner toggle/cooldown/immunity,14 residents/eight moving villagers, reclaim and rebirth cleanup. Normal bootstrap `StudioStrongholdTests` plus sequential `StudioStrongholdRegression` completed. |
| PASS | Farm accounting/physical production/failed-collection retention/reclaim, farm purchases, wooden walls and rebirth economy/service suites. Expected intentional overflow warning appeared. |
| PASS | Data layer12 schema cases, snapshot isolation, invalid/throwing/yielding/stale mutations, Mock storage; plot validation/throttle/template rollback/reclaim and entry placement. |
| PASS | First eight-upgrader chain and second Mint lane configuration/ledger/physical integration suites, including timed production checks and failed-credit retention. Tutorial and HUD presentation suites. |
| PASS | Optional offers, stamina, sword grant/server cooldown/client activation bridge, optional purchase restoration, actual rebirth ability/tool removal. Ran the documented Sprint switch so the paired client sword fixture participated. |
| PASS | Shop ownership/economy/service/preview lifecycle simulation through normal bootstrap. No Robux transactions. |
| PASS | HUD, Shop, Rebirth, menu, sprint animation/input and stamina UI checks through normal client bootstrap; desktop60-entry leaderboard state/view checks. |
| PASS | Course state/service checks with explicit courtyard fixture: checkpoint ordering, early-finish rejection, fall recovery without timer restart, finish/retry/menu cancellation. |
| PASS | Three separate Persistent test-store sessions: seed100,000 Gold/500,000 LifetimeGold and purchases; reload exact data, restore stone/14 residents, actual rebirth; reload0 Gold/one rebirth/no purchases/500,000 LifetimeGold. |
| FIXED | `717e614`: Rebirth used camera height despite Core UI insets. A06 had705x338 camera versus705x280 usable GUI, giving panelY=-5. New usable-origin assertion failed before repair. Fit now uses ScreenGui size and listens for changes; phone normal-bootstrap client tests and desktop layout checks passed. |
| FIXED | `7b639b6`: Shop launcher covered the Rebirth panel on phones. Native-open regression failed before repair; both left launchers now hide during other menus and return afterward. Both normal-bootstrap menu suites passed on A06. Corrected the older Rebirth test's740px cutoff to the view's840px cutoff. |

Independent read-only review found no actionable issue in either repair. Final
Selene (zero errors/warnings), full source formatting and Rojo build passed.

### Test context and reproduction

Run each service fixture separately in Mock through the existing bootstrap test
switches documented in the subsystem guides. The wider sequential pass temporarily
appended calls to the source bootstrap (DataLayer, Plot, Entry, MintUpgraderChain,
SecondRoyalMint, Tutorial, HUD); instrumentation was removed and original bootstrap
files restored. No permanent acceptance runner or test configuration was added.
Do not run concurrent Gold-mutating fixtures or use plugin-required service copies.

Two initial harness failures were diagnosed rather than treated as game defects:
plugin-invoked Shop client tests used a different controller cache; normal bootstrap
passed. OptionalAdditions initially lacked its paired client sword activation
fixture; running the documented Sprint switch passed both sides. Rebirth layout
measurement before Play saw a deliberately disabled HUD; enter natively before
measuring. The separate A06 inset failure persisted after entry and was repaired.

Persistent tests used `KingdomTycoon_PlayerData_Test` and an isolated
`Verify_Accept20261119_` player-key prefix, never the normal `Player_` record or live
store. The disposable acceptance record remains for audit; no records were deleted.
This proves current-schema durability, not durable migration of a legacy v1 record.

## Known release blockers and limits

- One claimable plot versus capacity 60: simultaneous kingdom ownership and two-kingdom load testing are not established. Adding plots/changing capacity requires a separate decision.
- All three Shop pass IDs are zero. Live purchases and durable real-pass ownership cannot be accepted without pass setup; no Robux purchase is part of this pass.
- Physical mobile/gamepad and full-server load require appropriate devices/clients. Synthetic leaderboard rows do not prove multiplayer behavior.
- Real multiplayer attempted via Test → Server and Clients: a separate server
  instance started with zero players; Add Clients was disabled in the accessible
  Studio window. End Session closed the empty session. Visitor death/unauthorized
  ward control, foreign purchase/start/collect rejection, cross-client headshots/
  ranking, join/leave replication and multi-kingdom load remain NOT TESTED.
- Native continuous wall traversal, death/respawn combinations, long-running NPC
  route recovery, interrupted-save/fault-injected rebirth reconstruction and
  broader real-player economy pacing remain NOT TESTED. Short service checks do
  not establish these outcomes.
- Existing asset203785492 type-mismatch warnings recur. No matching Sound or
  Animation instance was found in Client/Server and no source reference exists
  under src/tools. Origin remains unresolved; no authored assets were removed.
- Simulator testing covers supported landscape A06 and desktop; physical touch,
  gamepad and device performance remain unverified. The game uses LandscapeSensor.

## Final state

Restored original bootstraps/configs, all test switches false, empty Server/Shared
test attributes, default simulator, Mock mode and `Player_` key prefix. Verified
normal native entry with0 Gold,0 Rebirths,0 LifetimeGold, no owned plot and no active
kingdoms. Studio left in this clean Play session for the creator. Current template
is script-free. No scene/template changes, cloud save, publish or Git push.

Release acceptance remains partial because of the explicit limits above. Next
human decisions are installed plot count/server capacity and real pass setup;
neither was changed. Arrange a functioning two-client session and physical-device
checks before declaring multiplayer/device readiness.
