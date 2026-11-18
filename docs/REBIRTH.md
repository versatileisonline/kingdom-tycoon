# Rebirth — milestone 1.9

A living kingdom owner can confirm rebirth at 100,000 banked Gold. Later targets
are 200,000, 400,000, and so on. Buying every building is not required. The entire
Gold balance, purchases, pending earnings, fractional earnings and physical
production are reset. The player keeps the same plot, permanent passes and saved
Rebirths, returns to the kingdom spawn, and starts the free farm again.

The permanent multiplier is `1 + 0.5 * Rebirths`, multiplied by the 2× Gold pass.
It applies at pit arrival, before manual or automatic banking. Half-Gold carries
between arrivals privately; only whole Gold is banked. Remainders are session-only.
Targets beyond the schema's safe-integer limit are unavailable. Schema v1 stays.

## Implementation and interfaces

Shared RebirthConfig owns targets, bonuses, artwork ID, modal size and copy overrides.
RebirthService owns validation and the runtime KingdomRebirth Request/Result
RemoteEvents. Requests contain expected Rebirths and a positive integer request ID;
results echo both. Clients never supply Gold, bonuses or reset contents. Requests
are rate-limited; stale counts cannot grant another rebirth. Request IDs prevent a
late response from settling a newer UI submission. A 10-second UI timeout allows retry.

PlotService.ResetKingdom(player, commit) reserves the same plot, preflights a clone,
then commits data and uses existing release/claim observers to rebuild. Collection
and purchase interactions are gated during transition. Failed preflight or data
commit leaves the old kingdom intact. Unexpected postcommit reconstruction failure
releases runtime objects and asks the player to rejoin; it does not undo saved reset
progress. This uses existing ProfileStore saving semantics, not an extra synchronous
save guarantee. No map/template, dependency or Rojo mapping changes.

Production caches the rebirth multiplier per kingdom; pass lookup stays dynamic.
No added server frame loop. Rebirth introduces a brief clone-allocation peak during
reset. Existing retained models, connections and ledgers use normal release cleanup.

## Editable art contract

`assets/hud/rebirth-atlas.png` is a transparent 2×2 equal-quadrant atlas, uploaded as
`rbxassetid://98116548422890`. Quadrants in reading order: reward crown/arrows,
reset keep/coins, preserved shield, launcher crown/arrows. Keep each icon inside
its quadrant with padding. Replace the atlas and update RebirthConfig.ART_ATLAS;
no map edits are needed. Built-in image generation produced the selected artwork
from the approved realistic mockup: matte worn brass crown, stone keep/coins,
weathered steel-and-blue shield; transparent background, no text or UI frames.
The Shop art is unchanged. Banner/corners/buttons reuse RoyalStyle and HudConfig.

The UI has three cards, live banked-Gold progress and Cancel/Rebirth controls.
It is mutually exclusive with Shop and Settings and suspends Shift lock. Narrow
screens stack cards in a scroll area. No final separate confirmation is needed:
the window itself explains the reset before the Rebirth action.

## Verification

Use Studio Mock, all other test switches false, and no StudioShopPreview.
Enable only RebirthConfig.RUN_TESTS_IN_STUDIO, sync, Play before claiming.
Expected Output:

- All rebirth economy checks passed
- All rebirth service checks passed
- All rebirth client checks passed

Optional Server Script attribute StudioRebirthRegression=true runs farm, purchase,
first Mint chain, second Mint lane, tutorial, HUD and shop economy checks sequentially.
Expected final line: All rebirth regressions passed. Clear the attribute and set
the test switch false after stopping. The fixtures restore Mock data and release plots.

Manual check: claim, start a farm, reach the configured banked target, open Rebirth,
confirm once. Gold becomes zero, multiplier increases, same plot remains owned,
and Start Farm appears. Double-clicking must never grant two rebirths. Check touch
scrolling, controller navigation and native Shift-lock restoration on target devices.

Persistent rejoin, multiple players, forced postcommit reconstruction failure and
native touch/device acceptance remain separate hands-on checks; do not confuse
Mock suite success with durable live-store verification. Strict analysis retains
the existing 14 unrelated plate-label diagnostics. Existing authored asset
203785492 emits asset-type mismatch messages during Play; rebirth atlas fetch succeeds.
