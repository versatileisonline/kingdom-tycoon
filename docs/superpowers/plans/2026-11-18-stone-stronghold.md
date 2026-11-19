# Stone Stronghold Implementation Plan
Approved chat plan: reference-style 24-stud stone walls and continuous six-stud wall-walk; optional sequential purchases after RoyalMintUpgrader08: StoneWalls8000, ProtectionDoor9000, ArcherPosts10000, KingdomResidents12000. Four stationary archers, two workers, eight walkers (14 total). Owner-toggle lethal ward; owner/NPC immunity; existing spawn shields respected. Existing castle remains intact. Preserve templates, schema and unrelated work. No push or publish.

## Execution ledger
- Dedicated branch feat/stone-stronghold created from clean checkout.
- Working in the connected Rojo checkout to preserve the live source path.
- RED asset assertion observed: StoneWalls missing.
- Tasks: authored assets; catalog/replacement; server door; residents; integration/verification/docs.

## Results
- Asset/chain commit22663aa; runtime/services/tests commit4cf3f96.
- Normal bootstrap tests passed including8moving villagers,14restored rigs and rebirth cleanup.
- Farm, purchase and rebirth regressions passed sequentially.
- Review findings corrected: corner passage obstruction, character collision lifecycle,
  saved-restore isolation timing, true castle copies and recognizable medieval props.
- Limits and final verification recorded in docs/STONE_STRONGHOLD.md.
