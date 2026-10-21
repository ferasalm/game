# Rooftop v3 (souq_rooftops): level spec for the painted camera
[cx,cx+1] x [cz,cz+1]; floor top y = 0.5. Yaw 0 = the figure faces +z (south, toward the camera); 180 faces north.

## 1. Goals (first 2 minutes)
Intent: a warm, safe commons you learn in, a readable field with three visible dangers, one gate (the bridge) you choose to cross.
- 0:00 Spawn. The first frame shows the mafraj (left), the herb stall with its seller (centre) and the sabil in front of a lit
  qamariya house (right); the enforcer pair patrols as a small figure at the top edge (read time before any danger).
- 0:10-0:40 Workshop W (2.5,13.5): dialogue, then equipment. 0:40-1:00 the stall (3.5 m east of spawn): buy one herb.
- 1:00-1:15 the sabil (4 m further): first drink = tutorial save + refill; the tip says patrols come back after a drink.
- 1:15-2:00 walk the 6 m corridor north between mafraj and house_b, meet patrol A on its worn-tile lane (fight or slip past),
  vista beat at the north strip, then the 3 m bridge.
- Critical path (about 45 m): spawn - W - stall - sabil - north corridor - bridge - east roof. Nothing forces a fight: every
  patrol lane has a 2 m+ side lane. Optional loops: chest_mafraj (yard), vista strip + drone (north), east alcove chest guarded
  by the mixed patrol. The commons is a pocket with one wide entrance (prospect-refuge: overview of the field, back to walls).

## 2. Layout (26 x 18 kept; no size change)
```
      x: 0         1         2
         01234567890123456789012345
z= 0     %%%%%%%%%%%%%%%%%__%%%%%%%
z= 1     %TTTT...........%__%TTTTT%   tower_e (NW, tall) | vista strip z1-3 | tower_h (NE, tall)
z= 2     %TTTT...........%__%TTTTT%
z= 3     %TTTT...........%__%TTTTT%
z= 4     %TTTT..,,,,,....%__%TTTTT%   patrol B lane (drone)
z= 5     %TTTT...........====.....%   bridge rows 5-7 = 3 m wide (was 1 m)
z= 6     %...............====.....%
z= 7     %...............====.....%
z= 8     %......,,,,,,...%__%.....%   patrol A lane (pair)
z= 9     %...............%__%.....%
z=10     %TTTT......TTTT%%__%.,,,.%   mafraj (T 1-4) | house_b (T 11-14) | patrol C lane (mixed)
z=11     %TTTT......TTTT%%__%.....%
z=12     %TTTT......TTTT%%__%..TTT%   house_a now x22-26 (T 22-24; col 25 parapet)
z=13     %.W..%..........%__%..TTT%   W workshop door; col 5 = parapet stub under the AC unit
z=14     %...............%__%..TTT%   stall (x7.9-10.1) and sabil (x12.1-13.9) sit here
z=15     %....S..........%__%.....%   S spawn; east alcove (z15-17) holds chest_saila
z=16     %...............%__%.....%
z=17     %kkkkkkkkkkkkkkkk__kkkkkk%
```
Legend unchanged (. roof_floor, "," roof_worn, = bridge, _ street, % parapet, k kerb, T footprint). P and Q are dropped P and Q dropped; S, W stay.
Fixes versus v2: (a) bridge 3 cells wide, lamp posts (16.5,6.5) and (20.6,6.6) moved off the lane; (b) house_a lowered and moved
2 m east so the east strip beside it is 2 m (was 1 m: a second stuck trap); (c) the col-15 alley beside house_b is filled with
parapet (no 1 m dead end); (d) tall buildings only where the camera cannot reach them.
Camera rule. Camera = target + (0, h, d) with h = D sin(pitch), d = D cos(pitch); pitch 35-55, D 14-20, so h in [8.0,16.4]
and d in [8.0,16.4]. The camera x equals the target x. Target = player clamped to x [7.5,18.5], z [3.0,14.0] (new `limits` in
camera.json; frames the commons at spawn, keeps the frame inside the 26 m area). A building volume is camera-safe if either
(1) top_y <= 7.0 (lowest camera y 8.5 minus 1.5 m margin, roof extras and parapet included), or (2) for every reachable cell it
fails the hit test: footprint grown 1 m intersects [tx-1,tx+1] x [tz+7, tz+17.4]. Tall rule: with min target z = 3, every
tall building needs z1 <= 7 (tower_e z1-6, tower_h z1-5 pass). house_a: floors 4 to 2, roof_extras [] (top about 6.6). house_b
(new): floors 2, no extras. South apron: nothing above y 7.0 in x -2..28, z 18..36 (skyline near band must obey; test it).

## 3. places (builder data; new key in areas.json, one list)
Every place: {kind, id, x, z, yaw}. Interact points are where the player stands; props are listed in section 7.
```
spawn    spawn_start   5.5  15.5  180
workshop workshop      2.5  13.5  180      (existing W; dialogue then equipment)
npc      herb_seller   9.0  13.3    0      (behind the stall counter; idle puppet; talks via shop)
shop     shop_herbs    9.0  15.6  180      shop id "herbs"; stall prop at (9.0,14.4)
save     sabil         13.0 15.5  180      refill HP/SP + save + patrols return; fountain prop at (13.0,13.9)
chest    chest_mafraj  3.0  15.8    0      (existing id)
chest    chest_saila   22.4 16.45   0      (existing id, moved into the east alcove)
vista    vista_north   rect [5,1,15,3]     (existing rect; B lane z4.2 stays 1.2 m clear of it)
patrol   patrol_a  enc patrol_pair    a (7.5,8.2)  b (12.5,8.2)   2 enforcers
patrol   patrol_b  enc patrol_drone   a (7.0,4.2)  b (11.5,4.2)   1 drone (new encounter id)
patrol   patrol_c  enc rooftop_patrol a (21.0,10.5) b (23.8,10.5)  mixed (existing id)
safe     safe_spawn 5.5 15.5 | safe_court 9.0 11.8 | safe_sabil 13.0 15.6 | safe_bridge_w 15.5 6.5
safe     safe_bridge_e 20.5 6.5 | safe_vista 14.5 2.5 | safe_alcove 21.0 15.6
```
Patrol clearance (segment to point, tests assert >= 3.0): A to spawn 7.6, stall 6.2, sabil edge 4.7, workshop 7.0; B and C
are farther than 9 from all three. Lane separation A-B 4.0 m, so a 2.2 m side lane (z 5.1-7.3) lies between them; the
bridge entrance (15.5,6.5) is 3.45 m from A's east end. Patrols never enter the commons (z >= 9.5, x 5-16).
Respawn and re-touch rule (config in explore.json: `touch_grace` 3.0 s, `safe_return_distance` 3.5 m):
- Victory clears that patrol until the next sabil drink (cleared_patrols); other patrols keep their positions; no timed respawn.
- Return from battle: the player stands on the pre-battle cell if it is >= 3.5 m from every active patrol position and lane,
  otherwise on the nearest reachable cell that is; touch is off for 3.0 s. Retry restores the snapshot, same rule.
- Sabil drink: patrols reset to endpoint `a` (never inside 3 m of the sabil by construction) and re-arm after 3.0 s.

## 4. Safe cells and "Unstuck"
- Track `last_safe_cell`: each frame, if the player's cell is in R (section 5), has 0.3 m clearance from every collider and
  patrol touch radius + 1 m, and has been held 0.5 s, push it on a ring of 8 cells.
- Unstuck (pause menu): teleport to the newest ring cell that is >= 3.0 m from every active patrol; if none, to the nearest
  `safe` place by straight distance; grace 3.0 s; the party follows (Bilqis snaps to the trail start). If the player's own cell
  is outside R (a bad save), use the nearest `safe` place directly. Never move the player across a loaded battle.
- Saves store `place.save_point` only; position is not stored in v0.3 (load puts the party at `safe_sabil`).

## 5. Reachability rule (walk-graph test, every shipped area)
Walkable mask W: tile.solid false and not hidden-solid, minus prop collide boxes grown by capsule_radius 0.3 (use yaw).
1. R = cells reachable from spawn_start through W, 8-neighbour (a diagonal needs both orthogonal cells in W).
2. Every place interact point, every patrol endpoint and the vista rect are in R; every chest and the shop are reachable.
3. Step height: |h(a) - h(b)| <= 0.1 for every edge; no tile pair gives a one-way drop (all edges symmetric). v3 floors are 0.5.
4. Width: let M = cells of W that belong to a free 2 x 2 block of W. R_M (reachable from spawn through M only) must equal R,
   except an interaction pocket (a place's own cell) may sit outside M if it touches an M cell. So no corridor is under 2 m.
5. Bridge: in each column x16..19 the bridge cells connected to both roofs number >= 3 (the exact count is 3).
6. No walkable cell has all four neighbours solid (no cell traps), and no dead-end pocket in R is under 2 x 2 free cells.
7. Camera test: for each cell in R, clamp to the limits, sweep pitch 35/45/55 and D 14/17/20 with the section 2 formula and
   assert the camera point is outside every building volume, prop collider and the skyline near band.
   and the section 3 clearances hold.

## 6. Sightlines and composition (painted look, high camera)
Honest limit: at pitch 35-55 with FOV 30 the top of the frame is 20-40 degrees below the horizon, so sky, moon and minarets are
not in the exploration frame. They read in three places: the opening pan, the vista beat, and as colour on the ground.
- Vista pose (north strip, low camera, FOV 40): looking north, minaret 1 (4,-58, 36 m) sits left of centre about 5 degrees
  (top 14 degrees up), minaret 2 (28,-70, 30 m) 12 degrees right and lower; the moon (sky def) should sit between them, upper
  right of minaret 1, about 22 degrees up. Builder: aim the moon direction there if it is not already.
- Haddah (-230,240) is south-west, behind the exploration camera: it reads as a cyan/magenta rim light on the left-rear edge of
  puppets and prop silhouettes (painted_light rim colour from the SW), as the pink HADDAH sign on house_a, and in the opening pan.
- Spawn frame (about 16 m wide, z 7..22): thirds. Bottom third: party and two warm ground pools (stall, lantern). Middle third:
  stall (warm orange, left of centre), sabil (cool white-cyan water glow, right of centre) and the seller. Top third: house_b's
  south face, 6 m of lit qamariya windows (G, Y, B stained glass, lit_ratio 0.8, three bays centred on x 13.0, aligned over the
  sabil) with a warm doorway light at its foot; the cool sabil against warm glass is the key contrast.
- The canyon channel (cyan #5ad0ff, x17-19) runs along the commons' east edge: the sabil's water is the same colour (story:
  the sabil is fed from the al-Saila channel). Pink SOUQ and cyan ZUBAIRI neon stay on the towers as district edges.
  the commons has no neon, only warm lamps and the water, so danger and safety separate by colour temperature.
- Bridge: lamp posts at both ends (z 4.6 and 8.4) frame the 3 m lane; from the west landing the east roof shows the ZUBAIRI
  sign (cyan) above the landing and the pink HADDAH glow around the corner of house_a: a temptation line to the alcove chest.

## 7. areas.json change list
1. rows: replace with the grid in section 2 (rows 4, 8, 10 carry the worn lane tiles). legend: drop P and Q.
2. buildings: add {"ref":"house_b","x":13.0,"z":11.5}; move house_a to x 24.0, z 13.5. buildings.json: house_a floors 2,
   roof_extras []; new house_b (footprint 4 x 3, floors 2, qamariya ["G","Y","B"], lit_ratio 0.8, columns_front 3, crenellated, seed).
3. props, remove: sign_legs (11.5,11.5), lantern_post (14.6,13.6), laundry_line (12.6,15.2), crates (6.0,10.6) optional.
4. props, move: lantern_post (16.5,4.5) to (16.5,4.6); (16.5,6.5) to (16.5,8.4); (20.6,6.6) to (20.6,8.7); solar_panel to (22.2,8.6);
   crates (24,16) to (24.4,16.4) yaw 90; chest_saila to (22.4,16.45) yaw 0; ac_unit (5.5,13.5) stays on the col-5 stub.
5. props, add: herb_stall (9.0,14.4,0) with a warm light; sabil_fountain (13.0,13.9,0) collide [1.8,1.4,2.0], water VFX, cool
   lamp; herb_seller puppet at (9.0,13.3,0); two lantern_post at (19.5,4.6) and (19.5,8.4) y 1.2.
6. lights/signs: delete the green light (11.5,2.4,12.5); add sabil (13.0,2.2,13.9 #9fe8ff pool 3.2), house_b doorway
   (13.0,2.0,12.8 #ffb764), stall (9.0,2.0,14.9 #ffa04a); sign WORLD_SIGN_BAB becomes WORLD_SIGN_SABIL on house_b at
   (13.0,4.4,13.12); move WORLD_SIGN_HADDAH to (24.0,2.3,15.12), its pink light to (24.0,2.4,16.2).
7. add `places` (section 3), keep `vista` as is; camera.json `limits` {x:[7.5,18.5], z:[3.0,14.0]} and the pulled-back preset;
   explore.json: touch_grace 3.0, safe_return_distance 3.5, and drop `patrol_respawn` once cleared_patrols ships.
