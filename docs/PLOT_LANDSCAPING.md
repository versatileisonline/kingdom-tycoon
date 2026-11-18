# Plot landscaping

Approved 2026-11-18: permanent shared trees, grass, ferns and small rocks inspired
by the creator's woodland reference. This is a foliage pass, not terrain, lighting,
hill, pond or gameplay work.

## Studio asset contract

- `ServerStorage.PlotLandscapeAssets`: prepared script-free Models named `Tree`,
  `Grass`, `Fern`, `Rock`. Each contains one anchored, non-colliding, non-touching,
  non-queryable part. Model pivot is the bottom center at local zero.
- `RawSources` inside that folder preserves imported/generated originals. Prepared
  copies retain geometry and texture children only; no scripts are cloned.
- `Workspace.Plots.<plot>.Environment`: permanent scenery, `LandscapeVersion=1`,
  `Seed=18112026`. It belongs to the plot, not the player's runtime kingdom.
- Each 320x320 plot receives 250 Grass, 40 Fern, 20 Rock and 8 Tree Models: 318
  parts total. Existing objects are preserved. Duplicating the entire plot carries
  its scenery; no new runtime service is needed. Workspace replicates to everyone.

Sources: generated tree model **87155412557584** (requested 3500 triangles),
generated grass model **71085021125277** (requested 900 triangles),
[Fern Bush by TheLegoGuy137](https://create.roblox.com/store/asset/7979002756),
and one stone from [Rock by FinisMaps](https://create.roblox.com/store/asset/4038061999).
The unused [Grass clumps by Quenty](https://create.roblox.com/store/asset/361802126)
source is archived, not placed: 71 parts per patch was too costly.
Prepared tree height is 48 studs, grass height 2; fern width 4.5, rock width 4.
Reconstruct prepared assets by cloning geometry with its textures, stripping all
other children, normalizing these dimensions and setting bottom-center pivots.
Assets are Studio-owned and are not included in a Rojo code-only build.

## Placement and installation

`tools/BuildPlotLandscaping.luau` runs only in Studio Edit, never in a live server.
Default `APPLY=false` constructs, validates and destroys an off-scene dry run.
Set `APPLY=true` in the command copy to install. It refuses existing Environment
folders rather than replacing them. Do not install during another agent's Play test.

The recipe asserts the documented wall reservation and centered/aligned Ground
before proceeding; changed layouts require a new placement review.

The full 216x216 wall reservation, entire farm, paths, every purchase plate and
unlock model, plus the broad entrance/spawn corridor are excluded. All grass,
ferns and rocks have six studs of horizontal bounding-box clearance from these
regions and remain within the baseplate. This includes future hidden purchases.
The interior remains empty even where no machinery currently exists.

Trees stand on dry terrain outside the plateau, with at least two studs of canopy
bounding-box clearance. Generation produced a broader crown than requested, so the
initial 185–190-stud offsets failed validation; installed offsets are 210–215
studs at the rear and 210–213 on the sides. The front remains open. Existing simple
plot trees and the earlier preview tree are preserved.

## Verification and limits

- Saved to Roblox cloud version 129 (not published).
- StyLua and Selene pass for the placement recipe.
- Dry run and installation both passed all geometry and asset safety assertions.
- Reinstallation was refused with Environment already exists. A final dry-run
  verification bypassed only that duplicate guard and preserved installed scenery.
- ContentProvider preloaded all six foliage mesh/texture requests successfully.
- Readback: 250 grass, 40 ferns, 20 rocks, 8 trees; 318 parts, no scripts, all
  anchored and collision/touch/query disabled.
- Compared existing plot, KingdomTemplate and KingdomMap descendant paths,
  classes and part transforms/sizes/collision flags before/after: identical,
  excluding only the new Environment subtree.
- Inspected overhead and near player-height screenshots. Grass forms uneven
  patches; existing lighting is preserved, so this does not reproduce the
  reference's sunset, fog or dense forest atmosphere.
- A Play session started, but the purchase suite refused to run because the
  current Studio data setting is Persistent. Its Mock-only assertion occurred
  before fixture mutations. Play was stopped; data mode was not edited. Purchase,
  collection and rebirth checks with foliage remain a Mock-mode hands-on check.
- No device performance benchmark was run. Mesh reuse and 318-part cap bound
  instance growth, but GPU cost still depends on foliage coverage and triangles.
  Existing LowGraphics disables effects/shadows; it does not hide these meshes.

Authoring Output:

```text
Landscaping installed: 1 plots; 250 grass, 40 ferns, 20 rocks, 8 trees; clearance checks passed
```

In Mock Play, verify claim/start/purchase/collect and rebirth with scenery remaining
unchanged, with readable plates and no blocked walkways. Also check mobile frame
rate and all foliage textures loading. The console already contained asset-load
warnings before this installation; those are not a clean-runtime verification.

## Rollback

Move the newly added Environment folder out of each plot into a uniquely named
ServerStorage archive. Do not delete or move any pre-existing plot parts.
PlotLandscapeAssets can remain in ServerStorage. No schema, remotes, mappings,
production, purchases, saving or rebirth code changed.
