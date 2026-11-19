# Leaderboard launcher polish implementation plan

**Goal:** Apply the creator-approved Ranks placement, matching royal styling and trophy icon; reduce the panel by about 8%.

**Architecture:** Retain the existing view/controller contract and responsive rows. Use a 0.92 panel UIScale and a transparent trophy ImageLabel. Only client presentation changes.

**Spec:** Creator approved the three-point proposal in this session and requested implementation.

**Constraints:** Preserve Tab/X, menu exclusivity, startup gating, leaderboard data and Rojo mappings. Keep the launcher compact. No push.

## Task 1: Presentation and asset

- [x] Create a dedicated branch and verify it; preserve existing work.
- [x] Generate/upload one transparent royal trophy; keep its source in assets/hud/leaderboard-trophy.png.
- [x] Add dimensions, asset ID and scale to LeaderboardConfig; update LeaderboardView.
- [x] Verify formatting, lint, build and Studio presentation/input; check desktop and narrow geometry without adding implementation-mirroring tests for this reversible visual change.
- [x] Update asset contract/verification docs and review the diff; commit the coherent presentation change after final checks.

QA finding: the short545x338 viewport clipped the player row. Hide optional subtitle/footer and tighten headings below300 design pixels; verified the full row is visible. Shared config owns short-layout constants. Desktop layout remains unchanged apart from the approved0.92 scale.

## Review focus

Check launcher alignment despite different ScreenGui insets, icon readability at 36px, no button overlap, panel scaling without unintended stacked desktop rows, and Tab/X/menu behavior.

## Artwork provenance

Built-in image generation. Final prompt: one centered antique gold two-handled trophy with an embossed crown and royal-blue pedestal, polished stylized medieval game-menu artwork matching the existing Shop/Rebirth family, bold small-icon silhouette, transparent alpha, no text/background/watermark.
