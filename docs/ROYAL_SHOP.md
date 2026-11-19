# Royal Shop — milestone 1.8

## Launcher trim and Gold badge refinement (2026-11-18)

Shop and Rebirth launchers reuse the Settings/Ranks gold corner artwork at 30px.
Their captions are separate labels, keeping corner placement independent of text
padding. The existing 184x56 size, 22px lettering and 42px icons remain. Shared
LauncherGap is 24px so the exterior ornaments clear one another.
The bottom-left Gold badge now uses HudConfig.COLORS.Raised (`183E65`), matching
the royal-blue launcher fill; its dark gradient was removed. Currency text,
icons, ownership, collection, and Shop/Rebirth window backgrounds stay unchanged.
No new asset, Rojo mapping, server or schema changes.

Check a fresh Play: both left launchers should have four gold corners without
covering their text/icons; the bottom-left amount should sit on royal blue.
Shop/Rebirth should still open and close normally; unowned Gold remains display
only, and Collect Now owners retain their existing collection control.

Verification: formatting, Selene (zero errors/warnings), code-only Rojo build
and diff checks passed. A temporary client preview in the ongoing sprint session
confirmed the intended appearance and color `183E65`, with four corners on each
launcher and a 24px stack gap. The source was edited only on disk; preview changes
were runtime UI properties/instances. No Play restart or native menu input was
performed during the other task's animation checks. Fresh Play remains the
source/bootstrap acceptance check; expect normal `ClientBootstrap ... Ready`
without HUD/Shop/Rebirth errors. No new frame work or connections; eight static
corner ImageLabels reuse the existing asset. Creator subsequently approved main
integration/push and documentation refresh; no Roblox publish was requested.

Approved: royal three-card mockup, permanent Collect Now 49 Robux, 2× Gold 99,
Auto-Collect 149. Rebirth and server leaderboards are implemented separately; see
[Rebirth](REBIRTH.md) and [Server leaderboard](SERVER_LEADERBOARD.md). Cosmetics
and rideable horses remain later work.

## Player behavior

Shop opens from the dedicated HUD button and replaces Settings; both suspend
shift lock. Desktop shows three cards; narrow viewports scroll vertically.
Owned cards cannot be bought again. Unknown ownership and unavailable products
never enable a live purchase. Refresh retries ownership and product information.

Collect Now owners use the existing bottom-left Gold badge as their collection
button. A gold Collect label appears before the existing coin icon and pending
Gold total, centered together with a tight 4-pixel gap. Nonowners retain the
original display-only badge. It collects their own active kingdom's shared
earnings from anywhere while alive, and disables at zero pending earnings,
unavailable data, or death. There is no separate collection button.
Auto-Collect banks once after each production tick, even during death; no extra
server loop or per-token data update is added. If both passes are owned, the
manual button remains, normally disabled because automatic banking has emptied
pending earnings. Floor collectors remain usable by everyone.

2× Gold applies once as a valid bundle/coin arrives in its pit, after all Mint
arches. It does not alter existing pending Gold. Travelling coins receive the
benefit if the pass is confirmed before arrival. Both floor and remote collection
bank the resulting amount without another multiplier. Successful remote/automatic
banking advances collection guidance only for sites that contributed pending
earnings; failed banking retains those source markers. Auto-Collect confirmation
also banks already-pending earnings. A failed DataService update retains the
balance, with a bounded automatic retry interval. Pending Gold still discards on
kingdom release/departure, as before; there is no offline production.

## Architecture and interfaces

ShopConfig contains the three allowed offer keys, pass IDs, constants and art.
EntitlementService queries Roblox ownership and handles Roblox's server-side
purchase-finished event. Its registry rejects obsolete lookup generations,
preserves confirmed permanent ownership through network failure, and discards
state on leave. Client attributes are presentation only and cannot grant passes.
No saved profile/schema change is needed: Roblox owns pass entitlements.

FarmService.TryCollectAnywhere(player) returns (success, amount). It validates
confirmed CollectNow ownership, active started kingdom, live character/root,
and a server cooldown. Floor and remote collection share one private banking
function. SessionEarnings accepts an optional multiplier provider used at credit.

Runtime ReplicatedStorage.KingdomShop contains CollectNow, CollectResult and
RefreshOwnership RemoteEvents. CollectNow and RefreshOwnership accept no payload;
extra/malformed arguments are rejected. Requests are rate-limited per player.
CollectResult reports the authoritative success and amount. No client-supplied
price, balance, player or kingdom is trusted. Remotes are runtime-owned and
cleaned up on shutdown; Rojo mappings and Studio map/template assets are unchanged.

## Artwork contract

assets/hud/shop-atlas.png is a transparent, four-cell square atlas, generated
with the built-in ImageGen tool and uploaded as rbxassetid://83808747914581.
Order: top-left Shop, top-right Collect Now, bottom-left 2× Gold, bottom-right
Auto-Collect. ShopView crops equal quadrants using clipped frames and normalized
image positioning, independent of Roblox texture resizing. Existing HudConfig
coin, banner and corner assets are reused. No new map assets are required.

Prompt: transparent square 2×2 atlas; four isolated, centered medieval Roblox UI
illustrations with empty margins, no text/numbers/grid. Royal blue and antique
gold dimensional art: market stall, crown coin with pointing glove, two overlapping
crown coins with ribbon sparkle, coin dropping into chest with curved arrow.

## Live pass setup

Create three permanent passes for experience 10769565462 in Creator Hub and set
Collect Now / 2× Gold / Auto-Collect to 49 / 99 / 149 Robux. Put their actual pass
IDs in ShopConfig.OFFERS. Current IDs are intentionally zero: live purchases
show Unavailable until configured. Prices shown in live UI come from
MarketplaceService:GetProductInfoAsync, including the applicable Roblox price;
PreviewPrice is only for the simulated shop. No repeatable developer products
or ProcessReceipt handler are involved.

Real Roblox purchase completion, ownership on a fresh rejoin, and regional price
presentation still require testing with configured passes. Studio simulation is
not evidence that payment processing has been tested.

## Automated checks

Acceptance repair (2026-11-19): Shop/Rebirth launchers hide while another menu
is open, preventing the Shop button from covering the Rebirth cards on phones.
They return when the other menu closes. The overlap assertion failed before the
repair; both normal-bootstrap client menu suites passed afterward on Galaxy A06
landscape. Existing observers own the visibility updates; no new connections,
remotes, data or asset changes. Enter via Play before live GUI layout checks.

Only in Studio Mock, enable ShopConfig.RUN_TESTS_IN_STUDIO on disk and set the
Server Script attribute StudioShopPreview=true in Edit before Play. Run before
claiming. Expect:

- All shop ownership checks passed
- All shop economy checks passed
- All shop client checks passed
- All shop and pass checks passed

The overflow test intentionally logs one retained-collection warning.
Set StudioShopRegression=true on Server before Play to run existing farm,
purchase, first Mint chain, second Mint lane, tutorial and HUD suites sequentially
after the shop suite. Expect All shop regression checks passed. Other suites'
config switches must remain false. Reset all attributes/switches afterward.

## Hands-on preview

With all test switches false, set Server.StudioShopPreview=true in Edit and Play.
ShopPreview claims Plot01, activates the farm and first Mint's eight droppers,
sets 25,000 Mock Gold, and opens Shop with every pass unowned. Expect:
`[KingdomTycoon][ShopPreview] Shop preview ready (Studio Mock)`.

The shop clearly says STUDIO PREVIEW / No Robux charged. Purchase buttons grant
session-only simulated ownership. Reset preview clears all simulated passes so
you can test independently. It does not reverse already banked Gold. Test:

1. Buy Collect Now: the Gold badge gains Collect; close Shop and click that badge to collect earnings.
2. Reset, buy 2× Gold: new arrivals earn double; old pending Gold stays unchanged.
3. Reset, buy Auto-Collect: pending balance banks, then Gold increases without
   touching a plate. Buy both collection passes to see their combined state.
4. Verify Settings/Shop exclusivity, Escape/close, shift-lock suspension, respawn,
   and touch scrolling on your devices.

Preview grants require BOTH Studio and Mock, plus explicit StudioShopPreview.
They never write ownership to profiles. Disabling the preview attribute immediately
rejects cached mock grants and reinitializes ownership presentation. Re-enable
starts unowned. Set the flag in Edit for normal use; the preview-only purchase
remote is created during bootstrap, not dynamically added later.

Stop Play to discard the fixture. Clear StudioShopPreview/StudioShopRegression
before saving the normal place. The handoff saves a normal Edit version first (cloud version 114), then enables
the preview flag for hands-on Play. Studio MCP cannot edit the Edit DataModel
while Play runs, so the current unsaved Edit flag remains enabled for repeat
testing. After stopping, clear StudioShopPreview before saving or starting a
normal session; cloud version 114 already has it disabled.

## Verification record

- Pure ownership/economy RED→GREEN tests and fresh Studio module tests passed.
- Normal-bootstrap Mock shop/client suite passed; real production and exact
  remote collection, duplicate rejection, automatic banking and failure retention.
- Native preview purchase and HUD Collect Now click banked earnings; malformed
  amount payload was rejected without banking.
- Desktop panel inspected; button gradient issue corrected and artwork loaded.
- Final regression/static results and cloud-save version are recorded in AGENTS.md.
- Full device/touch and multi-player pass acceptance remain hands-on checks.


Final verification: sequential farm, purchase, first Mint chain, second Mint,
tutorial and HUD regression suites passed. Formatting, zero-warning Selene and
Rojo build pass. Strict analysis has the same 14 unique pre-existing plate-label
diagnostics and no new shop diagnostics. Cloud version114 saved normal Edit state,
all test switches false, no preview flag/runtime kingdoms. Final Mock preview
native purchases confirmed owner controls and Auto-Collect banking; passes reset
unowned and Shop left open for creator testing. No live publish or Git push.


Presentation revision (2026-11-18): Royal Shop title is anchored to the blue
ribbon; offer grid has stroke clearance on every edge. Paid collection now uses
the existing Gold badge with a centered Collect / coin / pending Gold row.
No server collection, prices, ownership or persistence behavior changed.


Refinement verification (2026-11-18): normal-bootstrap shop client and service
checks passed, including visible card-border clearance and owner-only badge.
Native preview purchase changed the badge to a button; clicking it credited108
Gold. Owned row checks confirm4px gaps, horizontal centering and vertical icon
centering; nonowners retain the original display. Normal Edit cloud version119
saved with previews/tests disabled. Fresh scoped review found no important issues;
format/lint/build pass, strict diagnostics remain the same14 pre-existing ones.


Collect amount correction (2026-11-18): CollectNow owners see UncollectedGold,
the exact shared pending balance published to every Collect Total plate. A
successful collection displays0; new arrivals then increase all totals together.
Nonowners still see their normal Gold balance. HudState.DisplayGold owns this
selection; HudController observes ownership/pending changes as well as data
readiness. Pure regression checks cover owner/nonowner, zero reset, new arrivals,
unclaimed/unready states and reverting ownership. Native collection observed0,
then HUD/farm/Mint all7 after fresh arrivals. No server accounting change.
