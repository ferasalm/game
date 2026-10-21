# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-21, session 4 (Opus 5.5, `claude-opus-5-5`, lead; 9 Sonnet 5.5 builders, 1 Haiku helper): v0.2.
Plan and estimates: docs/BRIEFING.md. Architecture: docs/ARCHITECTURE.md. Token rules: docs/EFFICIENCY.md.

## Status
- Prototype v0.2 (F5: features/prototype/prototype_main.tscn), merged into main (6a8c5c8 + handoff commit):
  title "Qarnaw / قرناو" over a moonlit sky (press a key), opening pan, area card "Souq al-Milh Rooftops", walk
  Zayd + Bilqis over night rooftops of old Sana'a, mafraj workshop (dialogue, then the equipment screen), two
  map chests, the patrol battle in place with a low cinematic camera, effects, BREAK! interrupts, loot popup.
- Look (docs/design/night-sanaa.md, art-bible.md): sky shader (moon, stars, clouds, city glow), fog and mist,
  moonlight, painted Sana'a tower-houses and skyline (minarets, Bab al-Yaman, Jabal Nuqum, Haddah megacity,
  Bayt Baws, al-Saila canyon), props, lamps, Arabic neon signs (Reem Kufi). F3 shows FPS.
- Systems: prosthetics (one slot per hero) and 6 rarity tiers on 12 items, perks, loot, chests, GameState v3
  (docs/design/prosthetics.md, harness 73-88% wins); UI theme (Amiri + Reem Kufi, docs/design/ui.md); motion,
  14 VFX kinds, hitstop/shake (art-bible "Motion and VFX"); AudioDirector + Kenney SFX + the owner's two Flow
  Music tracks (docs/design/audio.md).
- Art: the owner's 8 portraits; real sprites for Zayd, Bilqis (64 px), enforcer (68), drone, from his Flow
  pictures via tools/art/pixelize.py --outline (one frame each; motion is procedural).
- Checks: tools/check.sh all ok, 273 tests. FPS on the Latitude (fps_probe): prototype ~110, battle demo ~137.
- Not seen by a person yet: a full play-through; the victory camera on the real rooftop; how the music loops
  (the night track ends in a 5 s fade); sound picks were made by file name only.
- Known rough edges: battle camera faces buildings so little sky shows in battle; enemy intent text can overlap
  a timeline icon; the drone's left rotor was partly keyed out; equipment screen has no shoulder-button tab switch.

## Waiting on the owner
1. Play v0.2 (Godot 4.7.2, F5). Tell Claude: FPS (press F3), what looks or feels off (night look, characters,
   battle effects, menus), whether the music loops well, which sounds are wrong, and what isn't fun.
2. Optional: touch up the sprites in Pixelorama (`python tools/art/sprite_png.py export --id zayd --png zayd.png`,
   paint, `... import ...`); walk/attack frames can come later.
3. Read docs/design/prosthetics.md (item names, rarities) and night-sanaa.md (place names, geography); correct.

## Next steps
1. Play-test fixes from the owner's notes (numbers in content JSON first, small view fixes). Model: Sonnet.
   Effort: medium.
2. Seamless music loops (trim the night fade, or Flow Music "extend"/stems) and sound re-picks from the owner's
   list. Model: Haiku. Effort: low.
3. After the verdict: plan M2/M3 from slice.md (talk to NPCs, save/load, Hamoud and taunt, enemy cancels,
   stealth walk, sluice puzzle). Model: Opus. Effort: high. Build with Sonnet builders in worktrees (LESSONS 4),
   Haiku for mechanical work.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game). Read HANDOFF.md. I played prototype v0.2; my notes: <FPS (F3), what looks
or feels off, music loop, wrong sounds, what wasn't fun>. Fix what my notes point to (content JSON first), ask me
2-4 multiple-choice questions where a choice is mine, run tools/check.sh, render a frame to check visual fixes,
commit, push, merge to main, then /handoff. Sonnet, medium effort; Haiku for mechanical parts.
```
