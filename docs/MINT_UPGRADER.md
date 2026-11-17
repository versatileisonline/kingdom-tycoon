# First Royal Mint upgrader

Historical prototype notes. The [full eight-arch chain](MINT_UPGRADER_CHAIN.md)
now supersedes the one-live-arch scope and purchase-baseline implementation below.

Approved visual: [concept](MINT_UPGRADER_CONCEPT.png). Studio construction,
preservation and rollback: [asset contract](MINT_UPGRADER_ASSETS.md).

## Behavior

Buy all eight Mint droppers, then purchase Upgrader 1 for 250 Gold. Its arch sits
just downstream of the first dropper. Every coin crossing the owned arch forward
gets its private value doubled once:3->6. Other dropper streams start downstream
and remain worth 3. Upgraded coins become brighter gold; size, material, collision,
spawn rate and physics stay unchanged. The small ×2 arch label and amber inset
communicate its purpose. Only the next purchase plate appears; buying removes it.

Ownership uses PurchasedBuildings.RoyalMintUpgrader01 in schema 1. Reclaim restores
the arch without repurchase; the existing free Start Farm interaction gates all
production. Existing traveling coins upgrade if they cross after purchase; coins
already downstream do not upgrade retroactively. Farm and Mint still share one
Collect Total balance. Departure discards session earnings and live coins.

## Implementation and performance

FarmLedger retains each registered token's expiry, current value and applied-ID
set. ApplyUpgrade(token,id,multiplier,now) rejects unknown/expired tokens, repeated
IDs, invalid multipliers and unsafe values. Remove credits that token's final
value on actual arrival. GetValue is server-only. Existing constructor, token cap,
expiry and shared-account cleanup semantics remain compatible.

FarmService retains optional arch references before PurchaseService detaches
locked models. HasUpgrader validates the actual zone/model and matching plate;
purchase validation checks that capability and active production before charging.
PurchaseService exclusively parents whole unlock models. Committed ownership
rebases previous positions, preventing pre-purchase segments from applying later.

The existing timed loop sweeps previous/current server-owned coin positions
through each owned UpgradeZone oriented box. Forward intersections apply before
pit collection; a delayed tick cannot skip the zone. Coin attributes and display
colors never determine value. Position history is cleared with registration
expiry, arrival and release. No frame loop, extra physics query, remotes, schema
migration, dependencies or Rojo mapping changes. Cost is bounded by the existing
32-coin Mint cap and configured owned arches; only one arch is configured now.

## Tests

Enable only MintConfig.RUN_UPGRADER_TESTS_IN_STUDIO in Mock, sync and Play before
claiming. Expect All upgrader ledger checks passed, geometry/directional crossing
success messages, and All Mint upgrader prototype checks passed. Reset afterward.
Tests restore original Gold, ownership and position. They cover once-only doubling,
distinct IDs composing, expiry/overflow, rotated/fast/reverse/missed crossings,
hidden/underfunded/distant/duplicate purchase rejection, actual upgraded first
stream with unchanged downstream streams, shared collection and restoration.
Native multiplayer touches remain a hands-on acceptance item.

Run the existing Mint sustained-production, farm, purchase and HUD suites
separately, plus formatting, lint, strict Roblox types and code-only build.

## Expansion reserved, not implemented

The same arch design and per-ID value logic support eight future stations. Only
the first purchase/model/config entry is installed. Provisional prices:
250/300/400/600/1000/1900/3800/7500. Planned centers along Z are
-52/-40/-28/-16/-4/8/20/32; the eighth needs a short forward belt/collector extension
before installation. Do not construct future arches or expose future plates now.
No decorations, second conveyor or horse are part of this prototype.

## Integration evidence — 2026-11-17

Private ledger tests observed the missing operation fail before implementation,
then pass with once-only/composed values, duplicate/expiry/overflow rejection,
final-value collection and legacy shared-account behavior. Numeric slab and
Studio rotated/directional tests pass. The normal-bootstrap Mock prototype suite
passes, including actual brighter Dropper 1 coins, unchanged Dropper 2 coins,
unchanged coin geometry/material, purchase rejection, shared collection, release
and owned-arch restoration. A test cooldown-order error was corrected by waiting
between distant rejection and the subsequent valid attempt; production throttling
was preserved.

The existing Mint 36-second containment suite, farm accounting/service, purchase
and HUD suites pass separately. Formatting, lint (zero errors/warnings), strict
Roblox Luau-LSP and code-only build pass. Independent source review found no
runtime defects. Installed arch: 40 anchored script-free parts. Edit preview was
inspected; native creator visual/multiplayer acceptance remains open.

Cloud saved as version **89**, Edit mode, all test switches false, no temporary
preview or runtime kingdoms. Original template retained in the named backup.
Modular commits on feat/mint-upgrader-prototype; no publish/push. Full Persistent
player rejoin and native visitor interactions were not exercised in this task.
Existing unrelated audio 203785492 and Assistant plugin-version warnings appeared;
project test success messages completed.
