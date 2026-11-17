# Eight Royal Mint upgraders

This supersedes the prototype-only scope in MINT_UPGRADER.md. The existing first
arch is repeated across all eight stations, each with a gold holographic curtain.
Asset installation/rollback: [chain asset contract](MINT_UPGRADER_CHAIN_ASSETS.md).

## Progression

All eight droppers precede the sequential upgraders. Prices are 250, 300, 400, 600,
1,000, 1,900, 3,800, 7,500 Gold (15,750 total). Only the next plate and owned arches show.
Each arch doubles each passing coin once. Fully upgraded stream values from
Dropper 1 through 8 are 768, 384, 192, 96, 48, 24, 12, 6 Gold. One full production wave totals
1530 Gold; theoretical Mint output is 510 Gold/second before travel time and
physical interruptions. The farm still contributes to the same Collect Total.

Every GoldHologram is a thin, translucent Neon plane, noncolliding/non-touching/
non-queryable, without shadows. It is visual only; invisible UpgradeZone geometry
and private server token records decide multipliers. Model size and coin physics
are unchanged. No new frame loop, particle animation, remotes or schema migration.

## Geometry and performance

The existing conveyor, two frames and two rails extend four studs downstream:
100-stud length, local Z-64..36. Pit/trough center moves to Z 39; collector moves to
Z 49.5 and stays within the paved yard. Last arch center Z 32 and its detection zone
end Z 34 precede the pit beginning Z 36. All other Mint and kingdom geometry remains.

Each arch adds 41 anchored script-free parts (328 total), including the visual
plane, plus existing low-range, shadowless lights. Swept checks remain bounded by
32 coins and 8 arches on the existing 0.25-second tick. Per-arch purchase baselines
preserve pending crossings through already-owned arches during a delayed tick;
a new purchase cannot retroactively upgrade coins that already passed its zone.

## Verification and creator stage

Enable only MintConfig.RUN_UPGRADER_CHAIN_TESTS_IN_STUDIO in Mock and Play before
claiming. Expect All eight Mint upgrader chain checks passed. The suite validates
prices/frontier/curtains, a delayed-tick purchase-history regression, exact 1,530
credit from eight real registered coins swept through the full path, 30 seconds
of natural arrival from every stream, ownership restoration and cleanup. Fixtures
restore original data. Run the prototype and existing farm/purchase suites
separately; reset every switch afterward.

Creator verification starts a separate Mock Play session with all eight Mint
droppers owned, all eight upgraders unowned, and 20,000 Gold. Walk onto each newly
revealed plate to buy the chain; observe the gold curtains and growing earnings.
The source-only startup fixture is removed after it runs. This stage is temporary
and does not write live/persistent data. Saved assets and test-stage progress are
separate: stopping Play discards the stage. No second conveyor, decorations,
weapons, or horses are part of this task.

## Implementation evidence

The full normal-bootstrap chain suite passes, including a registered first-wave
sweep yielding exactly 1,530 Gold and 30 seconds of natural arrivals from all eight
producers. The ownership-history regression was observed failing before the fix,
then passed after activation baselines became per-arch. The old prototype suite
and existing Mint containment suite also pass against the expanded assets.
Independent review confirmed the timing fix and found no remaining defects.

All eight holograms were inspected in an Edit preview. Each arch has 41 anchored,
script-free parts; planes never collide, touch or participate in queries. Creator
acceptance of the laser appearance and native purchase experience remains open.

Final integration: existing prototype, Mint containment, farm and purchase suites
pass separately. Formatting, lint, strict Roblox type analysis and code-only build
pass. The per-arch history fix received an independent review with no remaining
defects. Static audit confirms eight 41-part arches, all anchored/script-free,
with the visual-only curtain contract and 100-stud belt. Saved cloud version 93 in
Edit, tests disabled and no temporary previews or runtime kingdoms. After saving,
a separate creator Mock session is started with 20,000 Gold and all droppers; the
temporary source fixture is restored afterward. Leave Play running for the user.
Native visual/pacing/multiplayer and full Persistent rejoin remain hands-on.
No publish or push.
