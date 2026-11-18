# Optional kingdom additions

## Approved behavior
After RoyalMintDropper08, six optional offers appear alongside the next production
plate. Buy them in any order. They never gate production and provide no income bonus.
Prices: RoyalBanners 250; RoyalLanterns 400; TrainingSword 600; SprintTraining 1000;
HorsePaddock 1900; RoyalFountain 4000 Gold. Ownership uses schema-v1 PurchasedBuildings.
Rebirth clears these purchases; normal saved progress on rejoin remains unchanged.

## Studio asset contract
tools/BuildOptionalAdditions.luau is the approved one-time additive Edit recipe.
It preserves the original template snapshot in
ServerStorage.OptionalAdditionsBackup_20261118, refuses collisions/reinstallation,
and adds only its six named children to KingdomTemplate.PurchasePlates and
PurchaseUnlocks. No Rojo mappings change. Do not restore a whole old template over
the landscaping agent's later changes.

Every plate is an anchored touchable cylinder with descendant PurchaseLabel.
Every matching unlock is an anchored script-free Model. Runtime PurchaseService
owns visibility; models and plates remain hidden until their purchase/unlock stage.
Horse scenery has no Humanoid, collision, touch, query, AI or riding behavior.

Local layout (X,Z), relative to template pivot:
- Banners (27,-30), 14x14; plate (15,-30).
- Lanterns (27,-65), 14x14; plate (15,-65).
- Armory (30,35), 20x18; plate (30,49).
- Sprint training (70,35), 20x18; plate (70,49).
- Paddock (64,-88), 64x40; plate (64,-60); open entrance faces +Z.
- Fountain (64,-20), 26x26; plate (64,0).

LayoutReservations.OptionalAdditionsMin/Max reserve local (8,0,-110)..(100,12,60).
Other agents own grass, ferns and trees; this recipe never edits those objects.
Static geometry adds 128 descendants across six unlocks; two unshadowed point
lights, no NPCs or extra physics actors. The fountain is static glass/stone.

ServerStorage.KingdomTrainingSword is a script-free Tool with Handle, Blade, Guard,
welds, no contact/query/collision, and CanBeDropped=false. EquipmentService owns its
runtime copies. Never insert free-model scripts into this asset.

## Rollback
Archive the six installed plate/model pairs and sword template separately; revert
matching feature code. Preserve backups and saved IDs. Do not replace unrelated
template children or reset player data. The snapshot is reference/recovery material,
not an automatic whole-template rollback.

## Verification ledger
- Optional-offer policy: observed RED before module implementation, then GREEN in
  Studio Edit, including independent offers and production frontier preservation.
- Asset recipe: StyLua and Selene pass. Installed six plate/model pairs and sword;
  Studio readback confirms all IDs. Remaining runtime/visual checks recorded below.

## Runtime modules and interfaces
PurchaseConfig.Purchase.Optional marks independent offers. PurchaseOffers.Next ignores
optional entries; IsVisible requires activation, an unowned ID, and its prerequisite.
PurchaseService uses that policy and retains its existing atomic touch transaction.
EquipmentService derives sword ownership from DataService; its server-only TrySwing
validates the equipped issued Tool, living owner, reset state, and 0.65-second cooldown.
EquipmentController listens to local Tool.Activated and sends an argument-free
KingdomEquipment.Swing request. Tool input is client-side per
[Roblox tools documentation](https://create.roblox.com/docs/players/tools).
SprintService accepts only one boolean through KingdomSprint.Input, with a token bucket
for start requests. Releases remain accepted so throttling cannot leave sprint stuck.
Owner-only KingdomSprint.Status carries ownership, remaining fraction, and an explicit
exhaustion boolean (including changes that do not change the rounded fraction). The server
owns stamina and WalkSpeed; clients never send speed, stamina, prices, or ownership.
Horizontal root velocity determines movement because Humanoid.MoveDirection is not
replicated from client-owned characters. There is one 0.1-second server loop and
quantized status updates only when stamina, ownership, or exhaustion changes.
SprintController uses client Movement.SprintInput: hold Left Shift for temporary sprint,
quickly double-tap Left Shift (0.3 seconds between presses) to lock sprint, and press
Shift again to cancel. Only short presses count toward double-tapping. Locked sprint
ends after 0.15 seconds without movement intent or on server-reported exhaustion;
recovery never restarts it. Direction changes within the grace period, wall collisions,
and jumping with movement intent preserve lock. R independently toggles camera lock.
Menus, typing, focus loss, sitting, death, character removal, and ownership revocation
clear sprint and pending double-taps. One client Heartbeat checks movement intent and
blocking conditions; it sends remote requests only when requested sprint changes.
Server movement/stamina tick and purchase/rebirth validation remain unchanged.
The stamina view uses the fixed viewport center +30px even with camera lock off,
matching the approved plan; it does not follow the free mouse pointer.
No remotes or schema fields were added to purchasing or rebirth. New remotes are
limited to equipment input and sprint input/status. No Rojo mapping changes.

## Asset contract
Under ServerStorage.KingdomTemplate.PurchasePlates each of the six catalog IDs is an
anchored touchable cylinder with descendant PurchaseLabel. PurchaseUnlocks contains
a matching anchored, script-free Model for each ID.
ServerStorage.KingdomTrainingSword is a script-free Tool with one Handle, welded
Blade/Guard, massless noncolliding parts, CanBeDropped=false, and RequiresHandle=true.
The template contains no embedded runtime scripts.

Local asset positions (relative to the existing kingdom pivot):
| Model | Center X/Z | Footprint | Plate X/Z |
| --- | --- | --- | --- |
| RoyalBanners | 27 / -30 | 14 × 14 | 15 / -30 |
| RoyalLanterns | 27 / -65 | 14 × 14 | 15 / -65 |
| TrainingSword rack | 30 / 35 | 20 × 18 | 30 / 49 |
| SprintTraining station | 70 / 35 | 20 × 18 | 70 / 49 |
| HorsePaddock | 64 / -88 | 64 × 40 | 64 / -60 |
| RoyalFountain | 64 / -20 | 26 × 26 | 64 / 0 |

LayoutReservations.OptionalAdditionsMin/Max records (8,0,-110)–(100,12,60).
The scene adds 124 anchored scenery parts, six purchase plates, two non-shadowing
lights, and one three-part equipped sword per owning player. Horses are static
models, not Humanoids. No AI, particle loops, or additional production tokens.
The asset recipe adds only its own children to the current template and snapshots
the source under ServerStorage.OptionalAdditionsBackup_20261118. It never replaces
the shared template or edits vegetation. Preserve this snapshot and later vegetation
changes; rollback by archiving only these six assets and the sword, not swapping
the entire old template over subsequent work.

## Automated verification in Studio
Keep Config.DATA.STUDIO_MODE="Mock". Enable only SprintConfig.RUN_TESTS_IN_STUDIO,
sync, and Play before claiming. Expect:
- All optional offer checks passed
- All stamina checks passed
- All stamina HUD checks passed
- All sword input bridge checks passed
- All training sword checks passed
- All optional additions and rebirth checks passed

This fixture temporarily supplies prerequisites and Gold, buys all offers in reverse
order, checks exact charges, red/green plates, duplicate/distant/insufficient-funds
rejection, saved model restoration without another charge, and the real rebirth
reset. It restores the initial Mock profile and releases the plot. The client test
activates the equipped Tool and verifies the server increments SwingSerial.
Reset the switch false after testing. Do not run other suites simultaneously.

## Sprint control verification (2026-11-18)
SprintInputTests runs with the existing SprintConfig.RUN_TESTS_IN_STUDIO client switch;
expect `All sprint input checks passed`. It covers hold/release, double-tap versus
slow taps/long holds, explicit cancellation, stopping grace, movement continuation,
and clearing/rearming after interruption. Existing StaminaTests retains server-side
exhaustion/recovery checks. Restart Play after syncing to load updated controllers.
Verification for this change: source-bundled SprintInputTests and existing StaminaTests
passed in Studio's Luau runtime. A controller integration harness using the actual
controller source and isolated input/remote boundaries passed Shift routing, latch
release, stopping, exhaustion/recovery, focus/shop/death/revocation cancellation,
and shutdown disconnection. Full-source Selene, changed-file formatting, and Rojo
build passed. The active Play session belongs to a concurrent acceptance task;
it was not restarted or modified for these checks. Cached controllers in that
session still use the prior keys until a fresh Play.
Physical key feel and the full optional-additions service suite require a fresh Mock
Play before claiming; avoid rerunning that fixture in a player's active kingdom.

## Hands-on acceptance still required
With test switches false, earn or use an explicitly temporary Mock fixture to reach
Mint Dropper 8. Inspect six independent optional plates plus one production plate.
Buy Sprint Training: hold Shift while walking, release to recover; exhaust stamina,
keep holding to confirm it stays stopped, then release/repress. Confirm the bar
appears immediately below the center cursor, refills, and fades only at full.
Double-tap Left Shift, release it, and keep moving: sprint stays active. Tap Shift
to cancel; also check that stopping or exhaustion cancels without automatic restart.
R toggles camera lock; Shift and Control must not toggle it. Open Settings/Shop/Rebirth
and return: sprint should stop until Shift is pressed again.
Equip the sword and click; check its grip and visible swing. Visit another player:
sword contact must never lower their health. Reset character and verify owned
abilities/tool return; rebirth and verify they are revoked.
Review horse proportions, scenery placement, labels, walking clearances, and
low-graphics/narrow-window readability. Two-player native touch and physical-key
acceptance are manual checks, not claims made by the automated suite.

## Final verification and coordination (2026-11-18)
- Normal Mock Play: All optional offer checks passed; All stamina checks passed;
  All stamina HUD checks passed; All training sword checks passed;
  All sword input bridge checks passed; All optional additions and rebirth
  checks passed. The bridge check used client Tool:Activate(), not a physical click.
- Separately, All eight Mint upgrader chain checks passed, including existing
  sustained production/collection and saved restoration checks. Its frontier
  assertion now counts production plates separately from optional side offers.
- Full src Selene and StyLua checks passed after the menu agent completed its work.
  Rojo build passed. Luau-LSP reports only the seven existing nullable Frame errors
  in shared/PlatePresentation; no new diagnostics in feature files.
- Read-only independent review identified missing client sword input; fixed and
  verified through the client/server bridge test. Final review found no remaining
  production blockers. Fixed center placement was explicitly retained.
- Menu agent owns EntryService/MainMenuController. Sprint and sword input now reject
  KingdomEntered=false. These final guards and the menu-aware fixture cleanup passed
  static checks; rerun the optional suite after restarting Play to verify the combined
  menu/optional integration. Earlier complete optional suite passed before menu gates.
- The optional fixture temporarily enters/unanchors the player and restores initial
  attributes/root anchoring afterward. STOP and restart Play after this suite:
  the startup menu closes on temporary entry and will not reopen in that test session.
- All test switches restored false. Temporary preview removed. Visual overview
  inspected in Edit; native grip/keyboard/multiplayer acceptance remains outstanding.
- Foliage agent saved the coordinated scene in cloud version137 after this task's
  additive installation. Do not reinstall the recipe. No vegetation edits were made
  here. The menu agent subsequently left Studio in Play for user testing; this task
  did not stop that session or publish.
- Studio emitted an asset-type warning for rbxassetid://203785492 during runs.
  This task introduces no external image/mesh/audio IDs; warning remains outside
  this milestone.
- Shared checkout was moved by the menu agent from feat/mint-optional-additions
  to feat/main-menu. Preserved that branch and all menu commits; only this task's
  own hunks/files were staged. No push or merge performed here.

## Giving yourself Gold in the hands-on preview

While the TutorialPreview-backed Mock hands-on stage is running, open Studio's
Command Bar, select Server, and run:

```lua
game.ServerScriptService.Server:SetAttribute("StudioGrantGold", 100000)
```

This adds 100,000 banked Gold through DataService. Change the amount and repeat
as needed; expect `Studio preview Gold granted` in Output.
It only works while that preview's grant listener is active. Ending Play clears
the temporary Mock progress and listener; this is not a published-game command.

The accessory hands-on stage starts after the eight first-Mint droppers, before
Upgrader1, with six optional plates and the next production plate. Player is placed
beside the unpurchased HorsePaddock plate with 100,000 Gold. Buy the paddock/sword/
sprint yourself; they are not pre-owned. Temporary staging bootstrap was removed
from disk after setup, so the next ordinary Play will not auto-stage progression.

## Purchase plate correction (2026-11-18)
Creator requested the exact existing red/green dropper plates, including their
black outer rim. The initial optional recipe constructed plain faces and omitted
Outline; shared PlatePresentation.Style only adjusts existing rims.
BuildOptionalAdditions now clones PurchasePlates.RoyalMintDropper02, including its
complete rim/label hierarchy, then relocates descendants and renames the plate.
tools/RepairOptionalPurchasePlates.luau applies the same clone to all six existing
optional plate slots in Edit. It archives the original six plates in
ServerStorage.OptionalPlateStyleBackup_20261118, preserving positions and unrelated
template/vegetation objects. Repeat runs skip already repaired plates.
No runtime/purchase/economy/schema/mapping changes.
Studio before/after checks confirmed all six were missing Outline before repair;
all six now match reference face/rim dimensions, material, color, reflectance,
transparency, shape, and collision/touch/query properties. Rim offset matches the
source and original positions are unchanged. Cloud save144 contains the correction.
Runtime preview checks confirm the remaining funded offers are green with the
same black rim. Previous HorsePaddock purchase restored; five optional offers
remain alongside Upgrader1. StyLua/Selene and code-only build passed.
Rollback: archive repaired pairs and restore only the six original plate instances
from OptionalPlateStyleBackup_20261118; preserve all later unrelated changes.
