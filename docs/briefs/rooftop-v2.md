# Brief: rooftop v2, the guesthouse tower roof in Souq al-Milh
You are in your own worktree on branch gemini/rooftop-v2 (made from claude/night-sanaa). Follow GEMINI.md. Load the
level-designer skill (.agents/skills/level-designer) for layout.

## Why
The owner: the rooftop is "too maximalist and tight". He wants a larger surface with breathing room, less congested,
on top of a guesthouse tower (funduq) in Souq al-Milh.

## What to build (content first; code only where content can't express it)
1. content/world/areas.json, area `souq_rooftops` (keep the id: saves and tests use it): a new `rows` grid for ONE
   big roof terrace of a tall guesthouse tower, about 34 x 26 cells (now 26 x 18). Drop the street gap and bridge:
   the whole walkable surface is one roof, ringed by parapet. Neighbouring lower roofs and towers are scenery beyond
   the parapet (buildings/skyline/vista), not walkable.
2. Breathing room, measured: at least 3 free floor cells round every place (spawn, workshop, herb_seller, shop,
   sabil, chests); `T` footprints (roof structures: stair head, a mafraj room, water tanks) cover at most 12% of the
   inner cells; the open middle stays clear for the patrol loop. Zones: stair head + spawn at the south; Abu Nabil's
   corner (his npc place and the herb_stall) at the west; Bilqis's workshop under an awning at the east; the sabil
   by the north parapet facing the city view; one chest in each of two far corners.
3. Fewer props, not more: the area's prop count, light_budget (8) and lights must not rise above today's (count them
   before you start and report both numbers). Prefer a few large readable props over many small ones.
4. Name: change the text of WORLD_ROOFTOP_NAME in localization/world.csv to "Funduq Roof, Souq al-Milh" (real place
   name; Musnad rules unchanged).
5. Camera limits, walk graph, patrol route, unstuck and anything else that reads the old grid must follow the new
   one. A saved position that is not on a walkable cell of the new grid must land on spawn_start: if that is not
   already true, fix it and add a test (core/tests/test_save_service.gd or test_area.gd).
6. Update the tests that pin old coordinates (grep: souq_rooftops, herb_seller, chest_mafraj, chest_saila in
   features/world/tests, core/tests). Keep every assertion's intent; change only the numbers.
7. Do NOT edit content/dialogue/, localization/dialogue.csv, content/audio/, features/audio/, features/ui/ (other
   briefs own them). Keep the npc place id `herb_seller` and shop place `shop_herbs` (a dialogue brief hooks them).
8. Update the rooftop section of docs/design/prototype.md (grep "rooftop") to the new layout, briefly.

## Proof
- `bash tools/check.sh`: paste the raw last 15 lines.
- Two renders (LESSONS section 2, last line): one from spawn_start with the game camera, one wide from high above
  showing the whole roof. Save the frames as inbox/rooftop_v2_spawn.png and inbox/rooftop_v2_wide.png (absolute path:
  the main checkout's inbox/, C:/dev/game/inbox/). Report the prop and light counts before and after.
- Small WIP commits; final commit message ends with `Built-by: Gemini 3.8 Flash (agy)`.
