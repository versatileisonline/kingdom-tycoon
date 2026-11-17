# Second Royal Mint lane

The final first-floor production chain follows RoyalMintUpgrader08. It clones the
accepted machinery 48 studs to the right (local belt X -32), retaining its +Z
travel direction, raised presses and eight gold curtains. No new artwork is built.
The first Mint owns the shared paving, perimeter lamps and sign; the second clone
omits those duplicate scenery pieces. The existing entrance remains clear.

## Economy and ownership

Lane two yields 9 Gold per coin every 3 seconds per owned producer. Eight arches
double passing coins once each. Final stream values are 2304/1152/576/288/144/72/36/18:
4590 Gold per wave, theoretical 1530 Gold/second. The first lane remains 510/second;
with the four-producer farm, total theoretical production is 2041.33/second.
Travel time, collection and coin expiry can reduce realized income. These are
experimental numbers, not measured retention or claims about player behavior.

Prices: opening lane + producer 12000; producers 2–8 cost
12200/12400/12600/12800/13000/13200/13400; arches 1–8 cost
13600/13800/14000/14200/14500/15000/16500/19500.
Only the next action appears; owned machinery remains. All three collectors share
one private session balance. Collecting from RoyalMint02 does not complete the
first-Mint collector tutorial. Farm start and uncollected earnings remain session-only.

Existing IDs/data stay intact. New saved IDs are RoyalMint02,
RoyalMint02Dropper02–08 and RoyalMint02Upgrader01–08. No migration, remotes or Rojo
mapping changes. Optional absent second-lane assets preserve earlier templates.

## Asset contract and installation

`tools/BuildSecondRoyalMint.luau` is a one-time Studio Edit recipe, not Rojo mapped.
Stop Play in place 77311816657817 and require empty Workspace.ActiveKingdoms.
Sync the matching disk source before running the recipe verbatim. It clones and
audits a detached full template, then archives the original intact under
ServerStorage.SecondRoyalMintBackup_20261117. It refuses duplicate installation.

PurchaseUnlocks.RoyalMint02 has direct Conveyor, CollectionPit, CollectPlate
(descendant EarningsLabel) and Producers.Dropper01–08 (direct DropPoint).
PurchaseUnlocks.RoyalMint02Upgrader01–08 retain direct UpgradeZone and visual-only
GoldHologram. Each matching PurchasePlates entry retains PurchaseLabel. All assets
are anchored and script-free. Conveyor/guide attributes, collision geometry,
coin template and original lane remain unchanged. Entry plate is local (-16,0.8,60).

Expected installation Output: `Second Royal Mint asset checks passed (cloned belt,
eight presses, eight arches)` and `Installed RoyalMint02; original retained...`.
Save the Studio place to retain assets. Code-only Rojo builds omit Studio geometry.
To roll back, archive the installed template intact, restore the backup template,
and revert matching runtime/config together. Preserve saved purchase IDs and all backups.

## Verification and performance

In Mock mode enable only MintConfig.RUN_SECOND_LANE_TESTS_IN_STUDIO, sync and Play
before claiming. Expect `All second Royal Mint lane checks passed`. Reset afterward.
The suite checks prices/frontier, all sixteen native service purchase paths, duplicate
rejection, exact 4590 registered-wave credit, shared collection, thirty-second natural
transit from all eight producers, restoration, start gating and release cleanup.
Pure config and ledger tests cover routing, cross-ledger isolation, 6120 combined
wave earnings and failed-credit retention. Run existing Mint chain, farm and purchase
suites separately. Original chain now expects the next RoyalMint02 plate.

Independent caps are 32 coins per Mint and 12 farm bundles: 76 physical tokens per
player maximum. Both lanes use the existing timed tick, server physics ownership
and collision groups. Each site queries only its own registered tokens. No extra
frame loop or NPCs. Additional static machinery/arches and doubled coin budget
increase rendering and physics costs; verify multi-player performance before release.

Hands-on acceptance: walking and plate/label readability, both-lane appearance,
spending/collection pacing, native multiplayer ownership and Persistent test-store
rejoin. No second floor, stairs, rebirth or shop changes are included.

## Implementation evidence

Normal-bootstrap Mock second-lane suite passed all sixteen purchases, exact4590
wave, thirty-second natural transit, shared collection, reclaim and cleanup.
Farm and purchase-service suites passed separately.
Original eight-arch suite also passed, including its delayed-crossing regression
and exact1530 first-lane wave. Pure two-lane ledger checks passed. Independent
code review found no material issues. Lint, changed-file formatting and code-only
build pass. Strict Roblox analysis reports existing PlatePresentation optional
Frame and CurrencyRow label-test errors; no new-file/type errors were reported.
Integration resolves the imported TutorialProgressTests formatting difference;
repository-wide source formatting now passes. Studio logs include an existing
asset-type failure for203785492 and an Assistant plugin version warning.

Final suite rerun includes the original-Mint tutorial collection guard and the
durable two-lane ledger suite; both passed. Edit preview confirms two matching
parallel belts fit the existing yard. Temporary preview removed and test switches
reset before saving. Native appearance/pacing remains creator acceptance.

## Purchase-plate lamp clearance

Creator requested shifting dropper and upgrader purchase rows left on both lanes
because some plates overlapped lamp bases. Final local X is -68 for
RoyalMintDropper02–08/RoyalMintUpgrader01–08, and -20 for
RoyalMint02Dropper02–08/RoyalMint02Upgrader01–08: 30 plates, four studs left.
Preserve every Y/Z, rotation, rim/label alignment, both entry plates and collectors.
For example Mint 2 Dropper 3 moves from (-16,0.8,-34) to (-20,0.8,-34).

BuildSecondRoyalMint normalizes these absolute positions, including when its source
first lane was already moved. For existing two-lane assets use
`tools/ShiftMintPurchasePlates.luau` only in Edit with no active kingdoms. It validates
all 30 positions before cloning, preserves the original under
ServerStorage.MintPlateClearanceBackup_20261117, and swaps only after audits. It
accepts old or corrected positions; an already-correct template is a no-op even if
the backup exists. Unexpected positions or a conflicting backup stop installation.
Expected Output: `Mint purchase plate clearance checks passed (30 checked, ... moved)`;
on rerun: `Mint purchase plates already clear lamps (30 checked, no changes)`.
Preserve the current template in a new archive before restoring the backup for
rollback. Static compile, formatting and lint pass; native clearance acceptance and
installation are coordinated with the tutorial agent. The requested Mock preview
was restored at Mint2 Dropper3, and the creator accepted clearance through the
last second-lane upgrader.

Coordinated Studio installation evidence: the tutorial agent reports cloud save
version 104 with all 30 row plates corrected and the complete original template
plus 30 original plate clones preserved in MintPlateClearanceBackup_20261117.
Minimum conservative plate-circle/lamp-base gap measured 2.244 studs. Second-lane
Dropper 3 is local (-20,0.8,-34); Upgrader 7 is (-20,0.8,20). The agent then left
Play at Mint 2 Dropper 3 with 977920 temporary Mock Gold for creator walking and
visual verification, normal test switches false. This stage is session-only and
not saved progression. Native acceptance remains with the creator; no further
Studio calls were made by the second-lane agent for this documentation update.

Creator accepted the plate-clearance fix ("looks great") after native verification.
This closes plate placement acceptance; multiplayer and Persistent rejoin remain
separate checks. Both feature branches remain unmerged and unpushed.
