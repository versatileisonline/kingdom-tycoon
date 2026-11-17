# Royal Mint progression

The [2026-11-17 revision](ROYAL_MINT_REVISION.md) supersedes the original yard,
dropper and coin geometry below. It reserves a second lane, raises the housed
droppers and isolates coin collisions. Purchase prices and production stay the same.

Approved open-air concept: [reference image](ROYAL_MINT_CONCEPT.png).
Asset contract, one-time installation and rollback: [asset notes](ROYAL_MINT_ASSETS.md).

## Player experience

Wooden Walls unlocks the 60-Gold Royal Mint purchase. It reveals the entire paved
production yard, 96-stud conveyor, collector and first gold-and-iron press.
Seven more presses cost 70, 90, 110, 130, 150, 170 and 190 Gold. Every press
produces one physical coin worth three Gold every three seconds. These prices
are initial tuning. Only the next plate is visible; unowned presses stay hidden.
The background walls/gate in the reference are not part of this task.

Farm and Mint arrivals contribute to one private session earnings account.
Both collection plates show Collect Total and the same amount. Either plate
credits all earnings in a single DataService.Update; failed credits retain them.
Death preserves earnings, departure discards them. Purchases and collected Gold
persist via the existing schema-v1 PurchasedBuildings dictionary. On each claim,
owned Mint scenery restores; the existing free Start Farm plate activates both
sites. No separate Mint activation, offline earnings or additional currencies.

## Source and performance

FarmService owns per-player production with independent site schedulers, bundle
ledgers and overlap filters. SessionEarnings owns the shared balance and
collection. FarmLedger's optional account dependency preserves its legacy
constructor and isolated cleanup. PurchaseService alone parents the whole Mint;
FarmService retains/unparents future producer models and explicitly destroys them
on release. TryCollect(player, siteId?) defaults to StarterFarm; RoyalMint selects
the owner's active Mint collector. This is a server-only API, not a remote.

MintConfig owns eight producer IDs and production settings. PurchaseConfig owns
prices/dependencies and an optional typed ProductionSite selector. No schema,
Rojo mappings, package changes or request remotes are needed.

The existing 0.25-second timed loop handles both sites. Farm cap stays 12;
Mint cap is 32, expiry 20 seconds, belt speed 8 studs/second. Total maximum is
44 movable bundles per fully upgraded player. A 96-stud belt takes about
12 seconds end to end before allowing for falling/contact. Server-owned coin
physics protects arrival credit. Mint coins use KingdomMintCoins; only the belt
and MintCoinGuide-tagged rails use KingdomMintTrack. Coins ignore players,
machine scenery and one another; pit overlap queries use the track group. Actual transit is covered by the Mint suite.
The Mint adds 425 authored static parts plus its cloned collector plate/rim,
and eight lantern lights without shadows. No NPCs or server frame loop.

## Verification

Use Studio Mock mode with all other test switches false. Enable only
MintConfig.RUN_TESTS_IN_STUDIO, sync through Rojo and Play before claiming.
Expect `All shared session earnings checks passed` and
`All Royal Mint checks passed`. Reset the switch afterward.

The suite restores original Gold and purchased IDs. It tests sequential prices,
hidden/duplicate/underfunded rejection, real coin transit from each of eight
presses, shared amounts, collection at either plate, overflow failure retention,
release/reclaim and pre-start inactivity. The expected overflow warning reads
`Collection retained ... Gold would exceed safe integer range`.

Run farm, purchase and data suites separately using their existing switches.
Expected messages include `All farm-service checks passed`,
`All farm purchase-service checks passed`, and `All mock data-layer checks passed`.
Run StyLua, Selene, Roblox Luau-LSP and a code-only Rojo build.

Hands-on acceptance: walk through the Mint and central gate route, inspect the
appearance and zoomed-out labels, try purchases with a second player, and assess
upgrade pacing. Automated checks do not establish native touch or visual approval.
Persistent player rejoin is separate from same-session Mock restoration.

## Implementation evidence — 2026-11-17

Normal-bootstrap Mock RoyalMintTests passed, including real coin arrivals from
all eight producer IDs within their lifetime. Shared balances collected from both
locations; overflow preserved funds; all purchases restored on reclaim without
pre-start production. Existing purchase/plate/scheduler, farm accounting/service,
and mock data-layer suites passed separately. An old wall-chain terminal assertion
was updated to expect the new Mint frontier. The Mint test waits away from plates
during cooldowns to avoid legitimate native touches racing its explicit calls.

StyLua, Selene (zero errors/warnings), strict Roblox Luau-LSP and code-only build
passed. Independent source review found no important bugs; its production-test
coverage concern was resolved with per-producer physical transit assertions.
Rotation-aware corner audit confirmed all 427 Mint parts fit the yard; all eight
presses and static parts are anchored/script-free. Edit preview inspected in the
existing kingdom context. Original source template remains in the backup folder.

Saved cloud place version **80** in Edit mode, all test switches false, no temporary
previews or runtime kingdoms. No publish/push. Persistent player rejoin, native
multiplayer touches, creator visual/walking acceptance and pacing remain unverified.
Existing Studio warnings for unrelated audio asset 203785492 and an Assistant
plugin version mismatch appeared during testing; project suites completed.
