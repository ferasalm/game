# Playtest with Claude (mark bugs while you play)

## Feras: play and mark
1. Start the game from a terminal tab in C:\dev\game: `bash tools/playtest.sh` (or ask Claude to start it in one).
   Everything the game prints also goes to `inbox/playtest/game.log`.
2. See a bug: press **F12** (gamepad: Back/View). The game freezes; a hint line and a note box show.
   - Left-drag: draw freely. Right-drag: a clean circle. Ctrl+Z: undo the last mark.
   - Type a one-line note. **Enter** (or F12 again) saves, **Esc** cancels. The game goes on where it stopped.
3. Tell Claude "read my playtest marks" (no need to paste pictures: they are already on disk).

Each save makes `inbox/playtest/<date_time>/` with `shot.png` (the frame), `marked.png` (your marks) and
`state.json` (scene, stage, room, hero position, the fight's HP and last 10 events, the last 50 warnings and errors,
your note), and prints `PLAYTEST <folder>` in the terminal. The tool exists only when the game runs from the project
(debug); exported release builds have no F12 overlay. inbox/ is git-ignored: delete old folders when fixed.

## Claude: read them
- New captures: `grep PLAYTEST inbox/playtest/game.log` (or the terminal tab), newest last.
- Per capture: read `state.json` first (note, stage, fight, log), then `marked.png` small (640x360, LESSONS 1).
- Errors around the moment: the lines of `game.log` before that `PLAYTEST` line.
- Code: features/debug/playtest/ (overlay, logger, dump); the game's state comes from NeonGame.playtest_state().
