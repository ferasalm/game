# The valve puzzles (level 1 finale; owner choices 2026-10-23)
Owner: both puzzles, light lock first, then the water; "challenging medium-difficulty, not too gentle and not too
hard"; no fail state, visible feedback on a wrong move. Target: about 5 minutes each for a first-time player.
Place: R5, the Concession roof (level-1.md), at the water tower's foot, plus one mirror on R4 by the leap (X4).

## 1. The qamariya light lock
Fiction: the Concession sealed the old valve with a glass eye that opens only to pure white light (their "clean"
signal). The souq answers with its oldest glass. The couriers' brass signal mirrors (old heliographs on the parapets,
used to flash messages roof to roof) still turn.
- Pieces: 4 lit qamariya windows facing the east roof, one colour each (red, yellow, green, blue), each with a
  wooden shutter (open or closed, interact). 3 brass mirrors on posts, each turns in 4 steps of 90 degrees.
  The lens on the valve shows the colour that reaches it right now.
- Light adds: red + green + blue = white, and yellow + blue = white too (yellow is red + green). Two right answers:
  the three-colour route uses all 3 mirrors; the yellow-blue route uses 2, the shortcut for a player who thinks.
- The medium part: the green window is on R3's tower across al-Saila, and its beam reaches R5 only through the
  mirror on R4 by the leap. So a player who wants three colours has to leap back to R4 to turn it,
  and a player who notices yellow skips that. Red + yellow (orange-white) and green + yellow are the near misses.
- Feedback: every beam is a visible painted ray in its glass colour (dust in the air); the lens takes the mixed
  colour; a wrong mix flickers and buzzes, a right one hums and the seal light turns from red to white; the
  Concession seal unlatches with a hook-curl animation (identity.md: steam curls into the hook).
- Hints (Bilqis, only when the player stalls): after 2 min "The lens wants white. Glass can make white." After
  4 min "Yellow is already half of white." No hint names a mirror.

## 2. Route the water home
Fiction: opening the valve sends the water where the Concession's pipes point, back into its own tank. The roofs
still have the old open gutters, wooden sluice gates and swinging mizab spouts from before the pumps.
- Pieces: a gutter network cut into the east roof floor (stone channels, visible at all times); 4 sluice gates (open
  or shut); 2 mizab spouts on the parapet that swing between two outlets; 3 outlets: the Concession return grate
  (red), the drone dock, and the canyon spout over al-Saila (the goal, toward the sabil).
- Water runs live from the valve along every open path and splits at forks. The canyon spout only gets the full
  stream when every other branch is shut: half a stream fills the sabil only halfway (a light gauge on the spout).
- The medium part: one gate is jammed. Zayd frees it with the jambiyah's hook (interact; the hooked blade lifts the
  gate: the weapon the whole game is about, used as a tool). Spout 2 points at the canyon only after gate 3 is shut,
  or its stream spills back into the return grate.
- Wrong routes are funny, never punishing: the return grate gurgles and the tower gauge rises (Bilqis: "Straight
  back to them."); the drone dock floods and two parked drones fizz and sag (harmless; a small cheer from the souq).
- Finale: the full stream pours from the canyon spout; the camera follows it down al-Saila under the zipline and
  up to R2, where the sabil overflows with cyan light and neighbours come to the edge. End card.
- Hints (Bilqis): after 2 min "Every open gate takes a share." After 4 min "That old gate is stuck, not locked."

## 3. Rules for the build (agy brief after level1-blockout)
- Pure logic, tested: features/world/logic/light_lock.gd (beam paths from windows through mirrors; additive colour
  at the lens; solved = white) and water_net.gd (graph from the valve: which outlets get water and what share, from
  gate and spout states). Content: content/world/puzzles.json (positions, colours, graph, hint times).
- Every piece is turned with the one interact key; any state can be turned back; nothing can be lost or locked.
- A save stores the solved flags only; an unsolved puzzle resets to its start state on load.
- 60 FPS: beams are unshaded additive quads, water is a scrolling shader on channel meshes (no particles beyond the
  spout splash).
