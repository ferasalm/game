# Neon Glitch: game plan (brainstorm 2026-10-25, Feras + Claude)
Decisions are in docs/DECISIONS.md; this doc is the plan built on them. Start concept: inbox/Neon Glitch Videos/edit/.
Update 2026-10-25: Bilqis is set aside (Rydan only); the old story is cut; the story is Feras's own (docs/story/).
Update 2026-10-26: his story bible is in (docs/story/bible.md, map in rydan.twee). Bilqis is now a story character;
opening = start flow -> Roya cold open (in-engine) -> prison escape tutorial (first fight on the prison roof) ->
"Earlier": Zayd's first shift -> back to the escape. No calendar year.

## What it is
- Neon Glitch is the whole game: the 2D isometric ink-comic RPG set in cyberpunk old Sana'a. The 2D redesign
  track and the RPG systems on main (XP, classes, gear, Jambiyah, workshop, menus) carry over.
- Start: menu -> qamariya -> pick hero -> brief + Normal/Hard -> reaction -> game (as in the v3 cuts).

## Two campaigns, one story
- Rydan and Bilqis each get a full campaign. Both tell the same events in Sana'a from their side.
- Shared: the city, enemies, bosses, items and systems. Separate: routes, fights, scenes and allies.
- Their paths cross: scenes where one campaign shows what the other hero was doing (story to write).

## Combat now, and later
- Now: turn-based, on the map where you meet the enemy, timeline system kept.
- The hero fights alone; story allies appear as call-in assists (one move each, like Hades' call), not as
  party members. The current party code stays until the solo switch is briefed.
- Later: likely an action roguelike like Hades. Whether the campaigns become runs is decided at the switch.
  To keep the switch cheap: combat rules (damage, stats, statuses, moves) stay in pure logic/, separate
  from the turn order. Nothing is built for action yet.
- Difficulty: Normal and Hard. Hard = stronger enemies and tighter resources. "Learn your habits" in the
  texts.py draft is not a committed feature; the text changes unless adaptive AI proves cheap.

## Build order (Rydan first: his kit, Jambiyah and gear exist on main)
1. First playable: start flow + one rooftop (the prison roof of the escape) + one Rydan fight + HUD. Same scope as the 2D redesign's
   one-scene prototype; waits on Feras's concept pictures and empty plates.
2. Rydan's opening (~30 min): solo combat, first call-in ally, first chapter scenes.
3. Bilqis's kit (rivet pistol frame + barrel, marks, static nets, hacks), then her opening (~30 min).
   Built after Rydan's, not in parallel: both touch the shared combat code.
4. Demo: both openings, picked from the start screen.

## Start flow in Godot (clips play as video)
- Check first: test-load one converted clip in Godot 4.7.2 (Theora .ogv is the expected format).
- The UI draws over the video; the blur zoom, whip-blur and pull-back become shaders on the video texture.
  One clock drives both hero loops (as in render3.py).
- Every Flow clip used gets an asset-manifest entry (source: Feras's Flow outputs).

## Open for Feras
- The shared story: what happens, where the two paths cross, how each opening ends.
- Who the call-in allies are for each hero.
- Whether the parked level-1 content (roofs, Abu Nabil, valve puzzles) becomes part of Rydan's opening.
- Final hero and difficulty texts (texts.py drafts).
