# Brief: gear-slots (<= 60 lines; after menus-equip-fix merges; touches the save: sensitive)
You are in your own worktree on branch gemini/gear-slots (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill and the game-designer skill.

## Why
DECISIONS 2026-10-24: Bilqis carries a rivet pistol in two parts (frame + barrel), upgraded like Zayd's hilt and
blade; every hero gets an accessory slot (ring) with 1-2 gem sockets by rarity; the grandfather hilt keeps its 3.

## Read first
features/equipment/logic/equipment_options.gd, features/items/defs/equip_def.gd, content/items/*.json,
docs/design/rpg-menus.md, docs/design/hilt-stones.md, core/save/ (version and migrations), core/game_state.gd.

## What to build
1. Content: content/items/pistols.json (Bilqis): frames and barrels, 2 each (Common rivet_frame/rivet_barrel start
   gear, one Uncommon each), stats in the style of hilts/blades; content/items/accessories.json: 4 rings (Common 1
   socket, Uncommon 1, Rare 2, Epic 2). Names/descriptions as localization keys.
2. Slots: Bilqis gains frame + barrel; every hero gains accessory; gem sockets on the accessory use the existing
   gemstone rules. Zayd keeps hilt/blade and the hilt's sockets.
3. Start gear: Bilqis wears rivet_frame + rivet_barrel; each hero wears a Common ring.
4. Save: bump the version by one with a migration that adds the new slots and start items to old saves (no loss).
5. Equipment menu shows the new slots (Bilqis: FRAME, BARREL; everyone: ACCESSORY with its sockets).
6. Balance: run the balance harness; start-gear wins stay inside 65-90% (write the numbers in the final message).

## Do NOT edit
`tools/check.sh`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`
(core/save/ and core/game_state.gd: only the version bump + migration of step 4, smallest edit.)

## Tests
- An old-version save loads with the new slots filled by the start items and nothing else changed.
- Bilqis's slots are frame, barrel, armor, prosthetic, accessory; Zayd's include hilt, blade and accessory.
- Ring sockets follow rarity (Common 1 ... Epic 2).

## Checklist
- file: content/items/accessories.json
- file: content/items/pistols.json

## Proof
`bash tools/check.sh` raw last 15 lines; balance numbers; render inbox/gear_bilqis.png; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
