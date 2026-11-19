# Server leaderboard and pixel typography

Tab or the Ranks HUD button toggles the custom upper-right player list; X closes
it. The default Roblox PlayerList is disabled. Rows show avatar headshot, display
name, Lifetime Gold and Rebirths, ordered by Lifetime Gold descending with UserId
as the stable tie breaker. Your row has a blue/gold highlight and YOU tag. Loading
profiles show ellipses without a rank. Leaving removes the row and pending avatar
results cannot restore it. Failed headshots use a plain dark square. Narrow
viewports use stacked rows at readable font sizes; longer lists scroll.

The panel uses the existing royal-blue HUD fill, alternating blue rows, a lighter
blue local-player highlight and gold trim/artwork. The
starter menu's Arcade font is configured in HudConfig and reused across game-owned
screen UI and plate labels. Text was increased two points from the initial pixel
conversion, with subtle outlines for weight. Roblox system UI is unaffected.
Opening the panel closes other gameplay menus and suspends camera lock/sprint.
It stays hidden before Play. Rojo mappings remain unchanged.

## Blue panel and full-server QA (2026-11-19)

The creator approved replacing the black panel with royal blue and fixing the
cropped top of the highlighted row's gold border. The old dark gradient multiplied
the dark base color; it is removed from this panel. A three-design-pixel inset
keeps the outward-extending two-pixel UIStroke inside the clipped scrolling
viewport at both ends. A six-pixel gold scrollbar has its own reserved lane;
compact Gold/Rebirths columns fit inside the padded row. Constants are in
LeaderboardConfig. Other menus and gameplay are unchanged.

The connected place reported `Players.MaxPlayers = 60`; capacity was not changed.
Sixty entries produce an approximately3314-pixel rendered vertical canvas.
Desktop panel736x451 has a267-pixel list window (four complete rows plus part of
another). Samsung Galaxy A06 landscape reported705x338, with an88-pixel list
window (one complete row plus part of another). A640x360 simulator override
reported545x338 and passed the same layout checks. Title and column headings stay
fixed while rows scroll. The game uses LandscapeSensor, so portrait was excluded.
Simulation was reset to the default viewport afterward.

Run the existing pure suite with the opt-in LeaderboardConfig test switch, or run
these explicit checks in the **Client Command Bar during Studio Play**:

```luau
local player = game:GetService("Players").LocalPlayer
local ui = player.PlayerScripts.Client.UI
local tests = require(ui.LeaderboardClientTests)
tests.Run(require(ui.LeaderboardState))
tests.RunView(require(ui.LeaderboardView), require(ui.LeaderboardState), player.PlayerGui, 60)
```

Expect `[LeaderboardClientTests] All checks passed` and
`[LeaderboardViewTests] All 60-entry layout checks passed`. RunView creates and
destroys an isolated view, including on assertion failure. It checks top/left
outline clearance, vertical overflow, last-row reachability, compact column
containment, fixed headings, scroll preservation during reranking, name/rebirth
updates, highlighted last-row clearance, departure, loading, one-row canvas
clamping and empty-list cleanup. Pure checks cover60-entry ranking, ties, loading,
immutable sorting and exact large-number formatting.

For the hands-on showcase, enter the game and open Ranks, then run the contents
of `tools/PreviewLeaderboard.luau` in the Client Command Bar. This unmapped recipe
uses the actual View/State modules with60 simulated entries (or the current
MaxPlayers), a long name and large values. Its banner always says PREVIEW,
including short screens. X removes only the preview, revealing the real board;
Tab closes the real board and removes the preview. Re-run the recipe to reopen.
No fake Players, saved data writes, persistent attributes or preview bootstraps
are installed. Synthetic IDs are below both zero and the local ID, avoiding
Studio multiplayer's negative test IDs. The fixture observes the real GUI rather
than requiring controllers: Command Bar and normal scripts can have separate
require caches. All preview-owned connections disconnect on removal.

Verification passed: Studio engine suites on desktop, A06 and short landscape;
native wheel to rank60 on desktop/phone; native Ranks, Tab, X and Settings
exclusivity; a temporary server LifetimeGold/Rebirths attribute update reached the
real client row and was restored without data-service writes. Formatting, Selene
(zero errors/warnings), code-only Rojo build and diff checks passed. Independent
review caught compact-column overflow and preview identity/labeling issues, fixed
before final QA. The border and compact-column regressions were reproduced before
their fixes. Existing asset203785492 type warnings remain outside this UI task.

These are60-entry UI simulations plus single-client replication checks, **not a
60-client network/load test**. Real multi-client join/leave, per-player headshots
and cross-client score propagation remain acceptance checks. Only one plot is
installed despite the configured60-player capacity; align capacity with available
plots before a public multiplayer playtest (see MAIN_MENU.md).

Studio was left in the existing entered50,000-Gold Mock Stone Walls preview,
with the temporary60-player board open at the top. No cloud save, publish or push
was performed by this task. Local capture artifacts were written to
`/private/tmp/kingdom-leaderboard-qa/` (desktop/phone top and bottom).

Follow-up integration/reset (2026-11-19): creator approved the visuals and asked
for local main integration and a fresh player. Only the three leaderboard commits
were integrated; inherited stronghold work remains separate. Main formatting,
Selene and Rojo build passed, and its four leaderboard source/fixture files match
the Studio-tested branch. Cleared StudioTutorialPreview, StudioPreviewFrontier and
StudioPreviewGold in Edit, restarted Mock Play and verified native menu entry:
Gold0, Rebirths0, no claimed plot and no synthetic leaderboard overlay. Persistent
saves were not erased. Studio was handed to the acceptance-testing agent, with
the fresh-player state communicated. No push, cloud save or publish.

## Compact launcher and panel refinement (2026-11-18)

Ranks now sits directly left of Settings with a 24px gap, matching royal blue
fill, rounded corners and gold ornaments. Its 132x52 button contains an 18px
Arcade caption and a 36px trophy. The view reuses Settings' position so delayed
GuiService inset initialization cannot place the buttons on different rows.
Desktop panel scale is 0.92: approximately736x451 instead of800x490. Existing
desktop columns and narrow row reflow remain; panels below300 design pixels
hide optional subtitle/footer and tighten headings to preserve a full row.

Asset contract: `assets/hud/leaderboard-trophy.png` is a single1254x1254 RGBA
image mapped by `LeaderboardConfig.LAUNCHER_ART` to `rbxassetid://130383942041603`.
The centered gold trophy with crown emblem and royal-blue pedestal has transparent
padding and no text. Replacement art must preserve alpha and a readable36px
silhouette; the full image uses ScaleType.Fit, without atlas cropping. Generated
with the built-in image tool; final prompt is recorded in
`docs/superpowers/plans/2026-11-18-leaderboard-launcher-polish.md`.
Rollback these client/config changes together; no schema/server rollback needed.

Verification: formatting, Selene (zero errors/warnings) and code-only Rojo build
passed. Fresh Mock Play confirmed startup gating, matching launcher position/fill,
loaded trophy, exact132x52 button and736x450.8 panel. Native Ranks click, Tab open,
X close and Settings exclusivity passed. Galaxy A06 simulator with640x360 override
(reported viewport545x338) displayed a full player/Gold/Rebirths row; simulator
was reset to default. Studio Output retained `LeaderboardController ... Ready
(Tab toggles server leaderboard)` and `ClientBootstrap ... Ready`, with no client
errors in the inspected log. Independent review found no actionable issues.
Physical-device and multiplayer acceptance remain manual. Studio was returned to
Edit and handed to the concurrent sprint task; no cloud save, publish or push.

## Lifetime earnings and compatibility

Schema v2 adds LifetimeGold. New saves start at zero; valid v1 saves initialize it
from current banked Gold, retaining their other progress. Past spending cannot be
reconstructed. Invalid/future saves still fail closed. Physical collection,
Collect Now and Auto-Collect use the same banking transaction and add the final
multiplied amount to both balances. Pending Gold and development grants do not
count. Purchases/rebirth do not decrease lifetime earnings. Overflow or rejected
updates preserve pending earnings and both saved balances.

Do not roll back to schema-v1 code after saving v2 profiles: it intentionally
rejects newer schemas. Roll back UI separately or retain v2 support in any server
rollback. Existing running servers need a fresh session to use the new schema.
No OrderedDataStore or global ranking writes occur.

## Verification

- `stylua --check src`, `selene src`, and `rojo build -o /private/tmp/kingdom-leaderboard-check.rbxlx`.
- Studio Mock: Config.DATA.RUN_TESTS_IN_STUDIO runs schema/migration tests;
  LeaderboardConfig.RUN_TESTS_IN_STUDIO runs pure sorting/formatting tests. Run
  farm and rebirth service suites separately using their existing switches.
- Output should include `LeaderboardController ... Ready (Tab toggles server leaderboard)`
  and `[LeaderboardClientTests] All checks passed` when enabled; normal bootstrap
  Ready messages should remain present. Disable test switches afterward.
- With two Studio clients, collect Gold and confirm both clients update the row;
  spend/rebirth and confirm lifetime total stays. Check join/leave, portraits,
  Tab/X, typing, startup menu, Settings/Shop/Rebirth exclusivity and R-lock/sprint.
- Inspect all menus, badge and world plates for text clipping on desktop and a
  narrow viewport. Test saved v1 migration/rejoin in the TEST store only.

Local verification passed schema migration/copy/equality/invalid data, collection
transaction failure/duplicate/overflow/multiplier checks, sorting/loading/tie and
formatting tests, formatting, Selene and Rojo build. Independent code review found
and prompted fixes for runtime Gold font sizing and narrow-screen scaling.
Automated Studio tools were denied by approval policy during implementation;
rendering, multi-client input and persistent test-store rejoin remain manual
acceptance checks. Another agent reported schema-v2 Mock startup and the
LeaderboardController Ready message during its authorized courtyard preview.

## Left HUD and authored world signs refinement

Shop/Rebirth launchers now use 22px Arcade text with a matching-color text stroke
for heavier letters, expanded 184×56 buttons, and a 10px gap. Gold uses a larger
16–26px sizing range and Collect uses 21px. Existing royal colors/art stay.
WorldTypographyController styles SurfaceGui/BillboardGui TextLabels under
ActiveKingdoms, KingdomMap and Plots using HudConfig.FONT, including Sword Stand,
training and paddock signs. It handles later clones/streaming through descendant
events and restores original FontFaces during cleanup; no template edits needed.

Verify after a fresh Play: Shop/Rebirth/Gold text should be visibly larger/heavier,
buttons should not overlap, and Sword Stand/medieval signs should use Arcade.
Output should retain ClientBootstrap Ready without WorldTypographyController errors.

Live client preview verification (2026-11-18): property readback confirmed both
launchers at 22px/184×56 and eleven world labels switched to Arcade. Studio screen
capture showed Shop/Rebirth fitting their buttons and Sword Stand/Medieval Practice
signs using the matching font. No Play restart was performed during the concurrent
animation session. A fresh Play is still needed to verify the new controller's
clone/stream lifecycle and persistent runtime Gold sizing end to end.
