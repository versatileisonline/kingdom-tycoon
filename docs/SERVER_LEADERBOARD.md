# Server leaderboard and pixel typography

Tab or the Ranks HUD button toggles the custom upper-right player list; X closes
it. The default Roblox PlayerList is disabled. Rows show avatar headshot, display
name, Lifetime Gold and Rebirths, ordered by Lifetime Gold descending with UserId
as the stable tie breaker. Your row has a blue/gold highlight and YOU tag. Loading
profiles show ellipses without a rank. Leaving removes the row and pending avatar
results cannot restore it. Failed headshots use a plain dark square. Narrow
viewports use stacked rows at readable font sizes; longer lists scroll.

The panel shares the existing royal blue, gold and dark palette/artwork. The
starter menu's Arcade font is configured in HudConfig and reused across game-owned
screen UI and plate labels. Text was increased two points from the initial pixel
conversion, with subtle outlines for weight. Roblox system UI is unaffected.
Opening the panel closes other gameplay menus and suspends camera lock/sprint.
It stays hidden before Play. No new assets or Rojo mappings are required.

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
