# Brief: three save slots, Load from the title and pause menus, and tests that never share saves
You are in your own worktree on branch gemini/save-slots (made from claude/night-sanaa). Follow GEMINI.md.

## Why
The owner wants to save at the sabil into one of 3 slots and load from both the title menu and the pause menu. Also,
parallel checkouts (worktrees) run tests at the same time and all write the same user:// save folder, so save tests
flake (test_battle_flow: "Load last save rebuilds the game from the slot: expected 1, got 0").

## What to build
1. Test isolation first: SaveService's folder becomes settable (default unchanged for players). tests/runner.gd sets
   it to `user://test_saves/<hash of ProjectSettings.globalize_path("res://")>/` and empties it at start, so every
   checkout has its own. Grep every `user://` write in core/ and features/ (saves, settings) and route test runs the
   same way. Test: two different res:// paths give two different folders.
2. Slots: the number of slots comes from content (add `save_slots: 3` to the existing save or flow rules JSON;
   find the right Def). Hard-coded `SAVE_SLOT: int = 1` constants (grep SAVE_SLOT in core/ and features/) go away:
   the slot chosen is passed through (sabil, Router, BattleSession "Load last save" = the slot last saved or loaded,
   kept in Router, not in the save itself).
3. A slot picker screen (features/ui/view/screens/, on the Screens stack like sabil_screen): one row per slot with
   its summary (SaveService summary: place, play time, party level or what it already shows) or "Empty"; Save mode
   asks "overwrite?" through the existing ConfirmDialog for a used slot; Load mode greys empty slots; Back closes.
4. The sabil: "Drink and save" opens the picker in Save mode, then saves into the chosen slot (refill and patrol reset
   unchanged). The pause menu gains "Load" (picker in Load mode; confirm "unsaved progress is lost"). The title
   overlay gains "Load" (picker in Load mode) next to New Game / Continue; Continue loads the newest slot.
5. Saves written by the old single-slot code (slot_1.json) keep loading (it is slot 1).
6. Player text: new keys in existing CSVs only (localization/pause.csv, sabil.csv, screens.csv); no new CSV.
7. Do NOT edit content/world/, content/dialogue/, content/audio/, features/audio/.
8. Tests: slot picker (save, overwrite confirm, load, empty greyed, back), sabil saves to the picked slot, Continue picks
   the newest, old slot_1 loads, and test isolation. Run test_battle_flow 5 times in a row: all pass.

## Proof
`bash tools/check.sh`: paste the raw last 15 lines, plus the 5 test_battle_flow runs. Small WIP commits; final message
ends with `Built-by: Gemini 3.8 Flash (agy)`.
