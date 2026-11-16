# Centered plate labels

Approved 2026-11-16: bold background-free text hovering above the center of each
plate. Purchase name on line one; configured amount plus gold-colored ● on line two.
Collector shows Collect: then its live amount plus the same ●. Dropper 4 remains
24 Gold; Wooden Walls remains 40 Gold. No economy or purchase-chain changes.

PlatePresentation.Style explicitly sets Adornee to the plate, zeroes inherited
extent/world/size offsets, and uses camera-relative StudsOffset (0, 2, 0). This
keeps label screen X aligned with the plate even at oblique viewing angles. The
TextLabel is anchored and positioned at (0.5, 0.5) within its billboard. Existing
14px bold type, 128 × 40 canvas, 65-stud visibility distance and no background remain.

SetAmount escapes title markup, enables RichText and colors the ● using the same
HudConfig.GOLD_ICON and COLORS.Gold (#E7B84B) consumed by HudView. Other labels keep
plain-text behavior. PurchaseService passes configured price; FarmService passes
private ledger balance on publication. No new loops, remotes, asset contracts,
data fields, Rojo mappings or image assets are required.

## Verification

Enable only PurchaseConfig.RUN_TESTS_IN_STUDIO in Mock mode, sync and Play. Expect
All centered plate presentation checks passed and the farm/wall purchase successes.
The regression test failed before the fix; it now checks explicit adornee, cleared
inherited offsets, centered canvas, upward screen offset, exact two-line money text,
zero amount, escaped titles and repeated styling without duplicate billboards.
Purchase integration checks configured prices/icons on each revealed plate.

Separately run FarmConfig.RUN_TESTS_IN_STUDIO: the real production/collection suite
checks the displayed balance against ledger presentation and zero after collection.
Both suites passed; formatting, Selene, strict Roblox Luau-LSP and Rojo build passed.
Reset test switches to false. Source changes are committed on fix/centered-plate-prices.

Native check: Play, claim/start, approach the next purchase and collect plates.
Orbit the camera: labels should stay horizontally centered over their plate and
hover clear of its surface. Confirm the gold ● matches the HUD, prices are correct,
and collection resets to 0 ●. MCP screen captures did not reliably render billboard
text, so final screenshot-based visual acceptance remains a creator check. All
preview instances and camera probes were confined to Play and removed on Stop.

Saved cloud place version 75 in Edit mode, all tests disabled, no previews or active
kingdoms. Two focused commits; no publish or Git push.
