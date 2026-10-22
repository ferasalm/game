# Level 1: the rooftops of Souq al-Milh (demo level; Level Designer, 2026-10-23)
Base layout: docs/design/rooftop-v3.md (two terraces and a 3 m bridge over al-Saila, 26 x 18 m grid, places, patrol
clearances, reachability and unstuck rules all kept). This file adds what the new camera, the cyberpunk look, the
tayramana and the demo story need. Where they disagree, this file wins. Owner choices: section 9.

## 1. Intent
Player fantasy: a courier who owns the rooftops of his old city at night, while the megacity glows on the horizon and
the Concession owns the water. Arc: warm home (commons) -> a quiet cup with Bilqis (majlis) -> danger in the open
(patrols, bridge) -> cold Concession roof -> one act of defiance (open the valve) -> water runs home to the sabil.
The moment to remember: Zayd turns the Concession valve, water rushes down the cyan al-Saila channel under the
bridge, and the sabil back on the commons overflows with light, seen across the canyon in one camera move.

## 2. What the Brothers-style camera changes (versus rooftop-v3)
- The sky is in frame now (follow camera, pitch about 28 degrees, wide FOV): the horizon carries the cyberpunk. The
  Haddah megacity (SW), the Great Mosque minarets (N), the moon and the drone lanes are the level's landmarks.
- Rooftop-v3's "camera-safe building" height rule is dropped: the arm shortens on walls (camera-v2). Tall tower-houses
  may now ring both roofs; they frame the sky and make the roofs feel like rooms open to the night.
- Scale reads closer: props are seen at 4-7 m, so dressing must hold up at that distance (no bare boxes at eye level).
- Navigation by landmark, not by map: from every cell of the commons the player sees the goal landmark (the Concession
  water tower on the east roof, red beacon, a cyan holo-gauge) between house_b and tower_h.
- Camera zones (camera-v2) author the views: spawn (looks NE over the commons to the water tower), vista strip (low,
  north to minarets and moon), bridge (side view along the canyon), valve (wide, back over the canyon to the sabil).

## 3. Shape and flow
Shape: hub (the commons) with one gated spoke (bridge) to a small arena roof; one interior off the hub (tayramana).
Critical path about 60 m, 15-20 min first time:
[Opening pan] -> [Spawn, commons] -> [Workshop room: talk + weapon] -> [Stall] -> [Sabil: save]
  -> [Tayramana: qishr with Bilqis, the seal] -> [North corridor: patrol A] -> [Vista strip] -> [Bridge]
  -> [East roof: patrol B drone, patrol C at the tank] -> [Light lock] -> [Route the water] -> [Water runs home] -> [End card]
Puzzles: docs/design/valve-puzzles.md (owner: both, light lock first, medium, no fail state).
Optional: chest_mafraj (yard), drone patrol B (north lane), chest_saila (east alcove, guarded by C), Abu Nabil's haggle
and fight (docs/design/abu-nabil-boss.md), the qamariya rooftop overlook (a dead end with a view, not a trap).

## 4. Pacing
| Min | Where | Activity | Tension | Notes |
|---|---|---|---|---|
| 0:00 | Opening pan | Camera | none | megacity, minarets, moon; ends behind the party |
| 0:30 | Commons | Walk, learn camera | low | warm lamps, music explore_souq |
| 1:30 | Workshop room | Talk, weapon pick | low | the bench is the first close-up of the look |
| 3:00 | Stall, sabil | Buy, save | low | Abu Nabil's haggle is optional |
| 4:30 | Tayramana | Sit, qishr, talk | low, warm | the story beat: the Concession seal |
| 8:00 | North corridor | Patrol A | medium | fight, slip past, or ambush from behind |
| 10:00 | Vista strip | Look | release | the postcard; drone B crosses the moon |
| 11:00 | Bridge | Cross | rising | canyon below, Concession roof ahead |
| 12:00 | East roof | Patrols B, C | high | colder light; the tank under guard |
| 15:00 | Valve | Interact, cutscene | climax | camera swings back to the commons |
| 16:00 | Back home | Walk, sabil | resolution | sabil overflows; people at the edge; end card |

## 5. Zones and dressing (old Sana'a first, 2150 laid over it)
- Commons (west roof, warm, safe): lime-plaster floor, tower-house faces with lit qamariya, washing lines with neon-
  strip pegs, AC units and tangled cables down the walls, a Musnad neon SOUQ sign on a tower, Abu Nabil's stall with
  hanging herb bundles and a price-holo that flickers; the sabil (cool cyan water against warm glass, the key colour
  contrast). No Concession red here: safety reads as warm.
- Workshop (owner 2026-10-23: a room like the tayramana): the lower room of the same tower-house (the mafraj
  block x1-4 z10-12); door on its south face at (2.5,13.0), lit by a qamariya lamp. Inside, 6 x 4 m, framed camera:
  the workbench (low cedar table, glowing screen on a brass arm, vise, tools, a jambiyah blank on cloth, cable to a
  battery box, a brazier), shelves of hilts and blades, the grandfather's old sheath on the wall.
- Tayramana (the top room of the same tower-house; its door, the stair up, on the east face at 4.5,11.0): see 6.
- North corridor and vista strip: worn lane tiles (the patrol path is visible on the floor), crenellated parapet, a
  satellite dish farm, solar panels; the strip ends at the parapet with the minarets and the moon straight ahead.
- Bridge (x16-19, z5-7): old planks on a new carbon-fibre truss, cables overhead with hanging lanterns, lamp posts at
  both ends; under it the al-Saila street, its channel dry and dark until the valve beat.
- East roof (Concession, cold): white-cyan floodlights, red seal lights, a drone dock, crates with the Concession mark;
  the water tower (tower_h, NE) with a ring gauge holo; the valve wheel at its foot (21.5,3.0) behind patrol C's lane;
  the HADDAH pink glow around house_a. Ration-meter boxes with red locks on every roof tank: the story without text.
- Horizon (all zones): Haddah towers with cyan and magenta holo-bands, drone light trails crossing slowly, a far
  searchlight sweep every 20 s, Jabal Nuqum ridge, mist bands.

## 6. Tayramana and majlis (interior; framed camera)
- Outside: a glass-walled room on top of the mafraj (big qamariya arches, warm light spilling on the roof). Door at
  (4.5,11.0), an interact prompt "Enter". Fade 0.4 s into the interior scene; leaving puts the party at (5.5,11.0).
- Inside, 7 x 4.5 m, 3 m high: low cushions (mattrah) along three walls, armrests (masnad), a carpet, a low brass tray
  with a jamana coffee pot and small cups, the large windows on the long wall showing the city and Haddah, a mafraj
  shelf with a radio and a cracked holo-frame of Zayd's grandfather. Two framed shots (door corner, window corner).
- Sit: interact at a cushion; Zayd and Bilqis sit (a sit clip, or a held crouch pose until one exists); the talk
  (4-6 lines): Bilqis pours qishr, reads the ledger seal: Concession; she names the water tower on the east roof.
- Reward: 2 qishr (cures spice confusion, the Abu Nabil fight). Sitting again later: one line, no reward.

## 7. Encounters (timeline battles today; the arena stays when action combat arrives)
| ID | Where | Enemies | Read time | Options | Fallback |
|---|---|---|---|---|---|
| E1 patrol A | north corridor z8 | 2 enforcers | seen from the commons exit, 6 m | fight; side lane z5-7; ambush from behind (reverse stab) | commons (z >= 9.5, never entered) |
| E2 patrol B | north lane z4 | 1 drone | its light sweeps the strip | fight; wait under the dish farm | vista strip west end |
| E3 patrol C | east roof z10.5 | mixed (2 + drone) | from the bridge landing, 5 m | fight; circle north of house_a; ambush | bridge landing |
| E4 Abu Nabil | stall | boss (optional) | talk first | haggle or fight | sabil |
No fight is forced: E3 guards the valve and the alcove chest, but the valve can be reached by the north side while C
walks south (timing). Clearances and lane rules: rooftop-v3 section 3.

## 8. Build order and builders (one worktree each; at most 3 at once)
1. camera-v2 (agy, running): follow camera, camera zones, framed indoor shots, grey-box test room.
2. workbench (agy): finish the WIP bench prop and the alcove (brief docs/briefs/workbench.md).
3. level1-blockout (agy, after 1 merges): rooftop-v3 grid and places plus this file's deltas (tall ring buildings,
   tayramana door, water tower, valve place, four camera zones). Grey box, then a render pass; owner plays it.
4. tayramana (agy, after 1): interior scene, door fade, sit, the talk (Claude writes the lines), qishr reward.
5. valve-puzzles (agy, after 3): docs/design/valve-puzzles.md: light lock, water routing, the finale camera move.
6. dressing (opencode or agy, after the owner plays 3): the 2150 props of section 5 as prop JSON, horizon life.
7. look: route B (owner pick 2026-10-23): painted skins (skin-bake, opencode, running), the oil-baked world kept,
   softer flat light; every new prop and room goes through the same bake.
Claude: this design, the briefs, the talk lines, every review and render judgment. Owner: the look pick, play checks.

## 9. Owner answers (2026-10-23, DECISIONS)
Tayramana: a real room behind a door. Last beat: open the valve, after the two puzzles (valve-puzzles.md). Demo keeps
today's timeline battles. Camera: automatic with designed zones, no player camera control. Workshop: a room like the
tayramana. Puzzles: both, approved as written in valve-puzzles.md.
