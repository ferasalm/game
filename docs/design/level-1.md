# Level 1: the rooftops of Souq al-Milh (demo level; Level Designer, rewritten 2026-10-23 from the owner's brief)
Owner: "multiple roofs of multiple buildings like before, but don't pack them with extra shops, rooms (keep the
Tayramana)"; Abu Nabil on one roof; crossings by "a wooden board, a simple bridge, jumping to a close roof, ziplines
or cables"; cyberpunk old Sana'a as in his concept art (chat, 2026-10-23: rain, neon trims on crenellations, cables
between towers, searchlight drones, the megacity behind the mountains). Answers: 5 roofs; the workbench inside the
tayramana; contextual leaps; rain. rooftop-v3.md is superseded as the layout (its walk-graph, unstuck and patrol
clearance rules still apply to every roof). Puzzles: valve-puzzles.md.

## 1. Intent
A courier who owns the rooftops of his old city in a night storm, while the megacity glows past the mountains and
the Concession owns the water. Arc: home roofs (warm, safe) -> the tayramana (a cup with Bilqis, the seal) -> the
zipline over al-Saila into the cold side -> patrols and searchlights -> the light lock and the water -> the water
runs home to the sabil. The moment to remember: the zipline ride over the neon-lit street in the rain, and later
the water you freed pouring down that same street.

## 2. The five roofs (each its own tower-house; floor heights relative to the market roof)
| Roof | Building | Size | Floor | What is there |
|---|---|---|---|---|
| R1 Home | Zayd's family tower, 6 storeys | 8 x 7 m | -0.8 | spawn; the stair door; a dovecote, a water tank, a washing line |
| R2 Souq al-Milh | the widest old roof, crenellated | 12 x 10 m | 0.0 | Abu Nabil's herb stall, the sabil, 2-3 neighbours under a neon awning, lantern strings |
| R3 Tayramana | the tallest old tower, 8 storeys | 9 x 8 m | +1.6 | the tayramana (glass-arched top room: majlis + workbench corner) on its north half |
| R4 Washline | a lower building across al-Saila street | 11 x 9 m | -3.2 | patrol A (enforcer pair), solar panels, dish farm, laundry, AC units, steam vents |
| R5 Concession | an old tower with a steel annex and the water tower | 12 x 10 m | -3.2 | patrol C (mixed), drone dock, the water tower, the valve, the light lock |
Gaps between buildings: 2-6 m alleys; al-Saila street between R1/R3 and R4 is 14-16 m wide, 18 m below. Every roof
edge has a parapet except at a crossing; nobody can fall (no fall state anywhere).

## 3. Crossings (one of each kind the owner named; each is taught where it is safe)
| ID | From -> to | Kind | Length / rise | Notes |
|---|---|---|---|---|
| X1 | R1 -> R2 | wooden board | 4 m, rises 0.8 m | a scaffold plank across the alley; teaches "edges have crossings"; both ways |
| X2 | R2 -> R3 | simple bridge | 6 m, rises 1.6 m | planks on two cables with rope rails, sways a little under the pair; both ways |
| X3 | R3 -> R4 | zipline | 16 m over al-Saila, drops 4.8 m | one way; a courier's pulley handle on a steel cable; Bilqis rides a second line |
| X4 | R4 -> R5 | leap | 1.8 m gap, same height | contextual: a chalk hook mark on the ledge; interact, the pair leaps in a set move; both ways |
| X5 | R4 -> R1 | cable traverse | 10 m, rises 2.4 m | hand-over-hand along a thick power-cable bundle over a ledge; both ways; the way home |
Loop: R1 -> R2 -> R3 -> (zip) R4 -> (cable) R1, so the player can always return to the stall and the sabil; R5 hangs
off R4 by the leap. Crossings are interact-started set moves (input locked, 1.5-4 s), each with its own camera zone
(side view), sound and a rain splash on landing. The follower crosses right behind the player.

## 4. Flow and pacing (15-20 min first time)
| Min | Where | Activity | Tension | Notes |
|---|---|---|---|---|
| 0:00 | opening pan | camera | none | storm over the city, megacity, the water tower's red beacon, down to R1 |
| 0:30 | R1 | walk, talk | low | Bilqis waits under the dovecote awning; the ledger job is set up |
| 1:30 | X1 -> R2 | board, market | low | Abu Nabil's stall (buy, optional haggle and fight), the sabil (save) |
| 4:00 | X2 -> R3 | bridge, tayramana | low, warm | sit with Bilqis, qishr, the seal; the workbench (weapon pick) |
| 8:00 | X3 | zipline | release | the hero shot: side view, neon street below, drones crossing the megacity |
| 8:30 | R4 | patrol A | medium | fight, slip past under the washing lines, or ambush from behind |
| 11:00 | X4 -> R5 | leap | rising | a drone searchlight sweeps the gap every 6 s: leap between sweeps |
| 12:00 | R5 | patrol C, light lock | high | cold floodlights; the lock (valve-puzzles 1) |
| 15:00 | R5 | route the water | climax | valve-puzzles 2; the water runs down al-Saila |
| 16:30 | X5 -> R1 -> R2 | walk home or end card | resolution | the sabil overflows; neighbours at the edge |

## 5. Look and dressing (concept art: cyberpunk laid over old Sana'a, never replacing it)
- Old Sana'a first: brown basalt and fired-brick tower-houses, white gypsum friezes (zigzag, triangles), round-arched
  qamariya windows in red, green, yellow and blue glass lit from inside; crenellated roof edges; carved wooden doors.
- 2150 laid over it: neon strips (magenta, cyan) along crenellations and window lines (not on the home roofs' inner
  faces); sagging cable bundles between every pair of towers (they make X5 believable); AC units, dishes, solar
  panels, water tanks with red-locked Concession meters; vertical Musnad neon signs on street faces; striped neon
  awnings over doorways; drones with searchlight cones; steam from vents.
- Storm: rain streaks, wet roofs that mirror the neon in puddles, drips from awnings and cables, the moon breaking
  through clouds now and then, lightning far behind the mountains (rare, quiet).
- Colour rule: home side (R1-R3) warm (qamariya, lanterns, the stall's amber); danger side (R4-R5) cold (cyan
  floodlights, red Concession seals); neon magenta belongs to the street and the city between them.
- Horizon: Jabal Nuqum's ridge, the Haddah megacity with holo-bands, drone light trails, a searchlight sweep every
  20 s, the Great Mosque minarets to the north.
- Street below (seen from every crossing): wet cobbles, the al-Saila channel dry and dark until the finale, a figure
  with an umbrella, neon reflections; never walkable in level 1.
- One close-up detail per roof (the camera is near now): R1 the dovecote and herb pots; R2 the stall's hanging
  bundles and price holo; R3 the tayramana's glass arches; R4 the laundry in the rain; R5 the water tower's ring gauge.

## 6. Tayramana (the one room; framed camera)
Top room of R3's tower: big qamariya arches on three sides, warm light spilling on the wet roof. Door on its south
face; fade 0.4 s inside. 7 x 5 m: the majlis (cushions and armrests along two walls, a carpet, a brass tray with a
jamana pot and cups, the grandfather's cracked holo-frame on a shelf) and, in the east corner, the workbench (the
built prop). Two framed shots (door corner, window corner). Sit at a cushion: the qishr talk (docs/briefs/
tayramana.md lines 1-7), +2 qishr the first time. The bench opens the existing workshop talk and equipment menu.

## 7. Encounters (timeline battles in the arena, as today)
| ID | Where | Enemies | Read time | Options | Fallback |
|---|---|---|---|---|---|
| E1 | R4 | 2 enforcers | from the zipline landing, 6 m | fight; slip past under the washing lines; ambush | the landing pad by X3 |
| E2 | X4 gap | drone sweep | its cone is visible | time the leap; caught = a drone fight | R4's dish farm |
| E3 | R5 | mixed (2 + drone) | from the leap landing, 5 m | fight; circle the water tower; ambush | the leap ledge |
| E4 | R2 | Abu Nabil (optional) | talk first | haggle or fight | the sabil |
The home roofs (R1-R3) never hold a patrol.

## 8. Build order (one worktree each; max 3 runs)
1. level1-blockout (agy): five roof buildings, the street, crossings as interact places (set moves in step 3),
   patrols, camera zones incl. side angle and roll, walk-graph tests per roof and across crossings.
2. skin-bake (agy, running), then the route B look pass (Claude).
3. crossings (agy): board, bridge, zipline, leap, cable as set moves with camera zones, sounds and tests.
4. tayramana (agy, after the Abu Nabil part B merge): room, door, sit, talk, the workbench corner.
5. storm (agy + Claude judging): rain streaks, wet floors and puddles, drips, steam; fps_probe on the laptop.
6. valve-puzzles (agy): from valve-puzzles.md section 3.
7. dressing (agy/opencode): the section 5 lists as prop JSON, the street, the horizon life.
Claude: this design, the briefs, the talk lines, every review and render judgment. Owner: play checks per gate.
