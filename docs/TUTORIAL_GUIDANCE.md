# First-action tutorial guidance

The owner sees a translucent gold arrowhead trail from waist height toward the
current interaction plate. A brighter wave flows toward the objective. The
existing **Display Helper Arrow** setting controls the entire trail.

Teach these actions once per claim, in order: Start Farm; collect the first farm
income; Wooden Walls; Royal Mint; Mint Dropper 2; collect Mint income; Upgrader 1.
A purchase target appears only when affordable and its real plate is present.
Collection targets require at least one uncollected Gold. Used targets disappear;
already owned saved purchases are skipped. Collection teaching survives death and
resets on claim/release. Later familiar purchases have no tutorial trail.

## Implementation

- TutorialConfig owns target paths, shared prices, presentation attributes and
  trail styling. TutorialState selects the first incomplete eligible action.
- TutorialProgress publishes read-only presentation attributes. Ownership comes
  from committed DataService snapshots; FarmService marks only a successful
  collection at the exact StarterFarm or RoyalMint site.
- PurchaseGuidanceController resolves only the owner's currently visible plate,
  follows respawns/streaming, and hides during typing, settings, Roblox menus or
  death. Disabling HelperArrow disconnects animation immediately.
- TutorialArrowView projects at most 64 simple triangle labels along the world
  line. Pulse speed is five studs/second. Rendering is client-only while eligible;
  there are no physics parts, external artwork, server frame loops, schema changes
  or new remotes. This straight guide does not route around obstacles.
- FirstPurchaseArrow remains the diagnostic ScreenGui name. Its TutorialTarget
  attribute identifies the selected action. Client presentation never authorizes
  a purchase or collection.

## Verification

Keep Studio Mock mode and all other test switches false. Set
TutorialConfig.RUN_TESTS_IN_STUDIO true, sync and Play before claiming. Output:
`All tutorial presentation checks passed`, `All tutorial stage checks passed`,
`All tutorial service checks passed`. The service suite checks failed/overflow
collection, correct-site success, committed ownership, claim and release reset.
Reset the switch after testing. TutorialArrowViewTests.Run separately verifies
engine projections, cleanup, bounded markers and pulse direction; its Output is
`All tutorial arrow layout checks passed` and `All tutorial arrow view checks passed`.

Normal-bootstrap service tests and engine-view checks passed. Actual client
visibility passed at 69/70 Gold for Mint Dropper 2. Formatting, lint and code-only
build passed; authored tutorial files have no strict type errors. Whole-project
strict analysis retains existing PlatePresentation/CurrencyRow errors. Creator
accepted the flowing visual revision; native helper-toggle, device/input and
full first-action walkthrough remain creator checks.

## Studio preview

The opt-in Tests.TutorialPreview helper runs only in Studio Mock from the normal
server bootstrap. Before Play, set ServerScriptService.Server attributes:
StudioTutorialPreview=true, StudioPreviewFrontier to a configured purchase ID
(default RoyalMintDropper02), and optional StudioPreviewGold (default 1000000).
It starts the farm, owns earlier live purchases and places the player beside that
purchase. Preview attributes are absent from the saved default place/source.
Output: `Tutorial preview ready: <purchase ID>; <amount> Gold (Mock only)`.

During that preview, Studio's Server Command Bar can add test Gold:

```lua
game.ServerScriptService.Server:SetAttribute("StudioGrantGold", 1000000)
```

Output: `Studio preview Gold granted`. Repeating the command works. The grant
uses DataService, rejects invalid/noninteger/overflow amounts, and adds no remote.
Stop Play, then clear StudioTutorialPreview to return to ordinary joins.
