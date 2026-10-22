# Demo plan (2026-10-23; owner direction: environment and levels first, action combat later)
Goal: turn prototype v0 into a 15-20 minute demo of level 1 (docs/design/level-1.md) that shows the game's identity:
old Sana'a rooftops under a 2150 megacity, painted, at 60 FPS on the Iris Xe laptop. Combat in the demo is today's
timeline battle in the arena; the action-combat overhaul replaces it after the demo (HANDOFF next steps).

## Scope
In: title -> opening pan -> level 1 (commons, workshop alcove, stall, sabil, tayramana, corridor, vista, bridge, east
roof, valve) -> end card; the chosen painted look; camera-v2; 3 patrols + optional Abu Nabil; saves; music already in.
Out: Chapter 1's cistern and station, Hamoud, action combat, Arabic, new characters beyond the Rodin cast.

## Milestones (each ends with renders for Feras and a play check by him)
| M | Content | Builders | Gate |
|---|---|---|---|
| M1 Foundations | camera-v2; workbench; look pick | agy x2 (running); Feras picks | Feras walks the rooftop with the new camera |
| M2 Grey box | level1-blockout (rooftop-v3 + level-1 deltas) | agy | Feras plays the grey box; layout locks |
| M3 Beats | tayramana interior + talk; valve beat + water | agy x2; Claude writes the lines | Feras plays both beats |
| M4 Look and dress | chosen painted route; 2150 dressing; horizon life | Claude (look) + agy/opencode (props) | renders side by side with M2 |
| M5 Demo build | end card, title flow, fps_probe pass, Windows export | agy; Feras downloads export templates | a build Feras can hand to a friend |

## Who does what
- Claude (Opus high): designs, briefs, talk lines, every review and art judgment, the painted look itself.
- agy (Gemini 3.8 Flash): Godot code with tests from briefs (camera, blockout, interiors, beats).
- opencode (GLM 5.3 Flash / DeepSeek V4.1 Flash, once installed): research, content JSON (props), docs, second
  opinions on briefs. Same worktree-per-task rule; tools/oc_task.sh.
- Feras: the look pick, play checks at every gate, any download (export templates), art from Gemini/Flow if wanted.

## Risks
- The painted route he picks may change how much dressing is worth doing in 3D: M4 waits for the pick.
- Route C (sprites) would lock the camera angle and undo camera-v2: decide before M2.
- A 60 FPS miss on the laptop: fps_probe at every gate, not only at M5.
