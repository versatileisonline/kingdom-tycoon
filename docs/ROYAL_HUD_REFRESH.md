# Royal HUD refresh

## Approved direction

Royal blue banner headings, sculpted antique-gold corners extending beyond dark
inset panels, ivory labels, brass controls and a prominent lower-left coin badge.
Use the supplied coin reference across HUD currency, purchase/collector amounts,
and Royal Mint coin faces. Farm drops remain wheat bundles. Preserve settings
behavior, prices, production and progression.

Custom artwork creation was explicitly approved as a task-specific exception to
AGENTS.md section 7. Artwork was approved on 2026-11-17; the three images are now uploaded to Roblox.

## Asset contract

Store source PNGs in `assets/hud/`. All three images require real alpha
transparency, no baked text, and clear silhouettes at their intended sizes:

- `gold-coin.png`: centered circular front face, thick yellow bevel, dark ochre
  inset, diagonal highlights; HUD at 40px and amounts at approximately 16px.
- `gold-corner.png`: one top-left L-shaped antique-gold scroll ornament, transparent
  interior; rotate for the other corners without blocking controls.
- `royal-banner.png`: symmetrical blue ribbon, antique-gold piping, blank central
  area for a live Settings heading; no baked heading.

Imported IDs in HudConfig: Coin `94873438043725`, Corner `81173608072407`,
Banner `100935518284790`. The Studio upload tool accepted `http://localhost` URLs
but rejected `127.0.0.1` URLs. Sources were created with built-in imagegen, using
these prompts: front-facing gold coin with thick bevel/ochre inset/three diagonal
highlights; single top-left L-shaped sculpted antique-gold acanthus ornament;
symmetrical blank royal-blue silk ribbon with folded ends and gold piping. All
prompts required true transparency, no baked text, and small-size readability. Keep controls and text native; artwork is decorative and noninteractive.
Mint faces reuse the coin image on the existing cylinder's two flat faces.
Preserve the original template in a uniquely named backup before installation.
The recipe must refuse a conflicting prior installation. Do not alter FarmService,
MintConfig, upgrader tests, production geometry, physics or saved data for art.
Coordinate the source coin installation with the upgrader session in Studio Edit
mode; never alter a live Play session or replace the KingdomTemplate.

## Parallel work ownership

HUD work lives on `feat/royal-hud-refresh` in
`/private/tmp/kingdom-royal-hud-refresh`. The original checkout remains on
`feat/mint-upgrader-chain`, with its existing dirty changes preserved. Do not
switch the original checkout, stage its files, or sync this worktree into its
running Rojo session. Integration follows artwork approval and source verification.

## Verification

Baseline: `stylua --check src` and `selene src` pass in the HUD worktree.
Source: HudConfig owns artwork/palette/layout constants; RoyalStyle supplies
noninteractive artwork, gradients and bounded event-triggered button feedback;
HudView retains existing settings behavior. PlatePresentation.SetAmount keeps its
signature, but the title is plain text and CurrencyRow contains Amount + Coin.
The whole row is centered using TextService text measurement; existing callers
still pass the same title/amount. This changes the presentation test contract.
No remotes, data schema, Rojo mappings or server tick work are added. Per-price
updates measure a short string; three cached image assets are reused across UI.

Run tools/DecorateMintCoin.luau once in Edit mode, after source sync. It preserves
an original clone in ServerStorage.RoyalHudCoinBackup_20261117, then attaches two
Decals to the source cylinder's Left/Right faces. Runtime clones inherit them.
It leaves the source coin and its physics properties intact; upgraded rim/body
color continues to come from FarmService. Rollback: archive the decorated source,
then restore the backup coin; revert HUD source commits together if desired.
Never replace KingdomTemplate for this task.

Source checks: formatting, lint, Luau compilation and code-only Rojo build pass.
Native desktop capture verified the Settings banner, four gold corners, clear
controls and new coin badge at 1914 x 780. ContentProvider reported Success for
all three UI images and the decorated coin face. Initial coin representation
warnings resolved on a subsequent preload. The Editor's old module cache initially
ran stale plate code; the fresh Server context passed the current plate suite.
Normal-bootstrap Mock HUD suites and the full purchase suite passed, including
centered labels, scheduling, farm purchases and wooden-wall purchases.
Narrow/short viewport hands-on acceptance remains for the creator.
Final acceptance requires separate Mock HUD/purchase suites, Studio visual checks
at narrow/short viewports, and existing Mint containment/upgrader checks after the
source coin is decorated. Expected logs: `All HUD presentation checks passed`,
`All HUD client checks passed`, `All centered plate presentation checks passed`.

Final native Mint verification with the decorated source passed: `All sustained
Mint coin containment checks passed` and `All Royal Mint checks passed`. All test
switches were reset. Combined source is integrated on feat/mint-upgrader-chain;
HUD commits preserve the other session's upgrader commits and changes.

Coin size refinement (2026-11-17): the lower-left badge uses an 18px coin,
vertically centered inside the panel, with the balance moved closer. Plate coin
images stay 16px and physical Mint coin geometry is unchanged.

Compact icon acceptance: native Play reported an 18 x 18 loaded image entirely
inside the badge, and the desktop screenshot confirmed the small coin beside
the balance. Output: `All compact HUD gold icon checks passed`. Formatting,
lint and Rojo build passed. Saved the combined place as Roblox version 97.
Leaderboard work was explicitly deferred; no leaderboard changes were made.
