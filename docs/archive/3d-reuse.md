# 3D archive: what Neon Glitch can reuse (2026-10-26)

The 3D game lives at git tag `3d-archive` (branch `archive/3d`); the working tree no longer has it.
Restore one file with `git checkout 3d-archive -- <path>`, then fix it to Neon's rules before committing.

Fit: **as is** = no 3D types and usable without a rewrite; **port** = keep the rules/data, redraw the view in 2D;
**idea only** = read it for the concept.

| Archived path(s) | What it is | Reuse for Neon (how, in one line) | Fit |
|---|---|---|---|
| `features/world/logic/walk_graph.gd` | One-metre walk graph: reachable cells, free 2x2 blocks, traps, too-high steps | Reachability and corridor checks for any tile-based roof (Neon's polygon rooms use IsoWalk) | as is |
| `features/world/logic/patrol_safety.gd` | Flat distance to patrol lanes; post-battle return spot; unstuck pick | Keep patrols off the hero's standing spot and choose a clear return cell | port |
| `features/world/logic/safe_spot.gd` | Remembers the last two spots the player stood still | Unstuck fallback when the hero is wedged on a plate | port |
| `features/world/logic/camera_limits.gd` | Clamps the camera target into area limits; camera point for a pitch and distance | Keep the iso camera on the plate and off its edges | port |
| `features/world/logic/follow_cam.gd` | Lazy auto-yaw, scripted orbit, zone easing, arm shortening | Camera feel (ease, recentre, vista zone), not the 3D orbit itself | idea only |
| `features/world/logic/stall_keeper.gd` | Keeper stands at the counter's open end, clear of its box, facing customers | Abu Nabil's spot beside the 2D herb stall | port |
| `features/world/logic/light_pick.gd` | Nearest-few real lights; fade and flicker maths | Flicker and fade for neon signs; the light budget is 3D-only | port |
| `features/world/rooftop/patrol_director.gd` | Beaten patrols stay gone; touch grace; return to lane; a drink revives all | Patrol lifecycle between sabil drinks | port |
| `features/world/interact/sabil_drink.gd`, `features/world/interact/sabil_spot.gd` | Drink refills the party, forgets cleared patrols, saves to a slot; spot opens the question | The sabil save/refill rule (DECISIONS 2026-10-21) | port |
| `features/world/interact/talk_spot.gd` | Interact spot that emits `talked(place_id)` | NPC talk prompt on the plate | port |
| `features/world/interact/stall_spot.gd` | Interact spot that opens the shop screen | Herb-stall prompt | port |
| `features/world/interact/crossing_spot.gd` | Rooftop crossing: usable ends, party teleport with fade | A 2D crossing if the opening roofs connect | port |
| `features/world/view/interact_focus.gd` | Camera ease-in on a spot and restore when the screen closes | Focus/zoom and walk-stop while a screen is up | port |
| `features/combat/view/battle_item_menu.gd` | Herb rows with free counts, then targets; back at each level | 2D item menu in the turn panel | as is |
| `features/combat/view/battle_numbers.gd` | Damage/heal pops and the BREAK! stamp (3D labels) | 2D number pops at the sprite rect | port |
| `features/combat/view/battle_end_panel.gd` | Victory spoils and Continue; defeat Retry/back | 2D end panel | as is |
| `features/combat/view/battle_hero_card.gd`, `features/combat/view/battle_info_card.gd` | Acting hero card; pointed-fighter card | 2D HUD cards | as is |
| `features/combat/view/battle_turn_panel.gd` | Hero card over the command/herb menu beside the hero | 2D turn panel (the command menu is already on main) | as is |
| `features/combat/view/battle_notices.gd` | Banner, one-time tip, key-hint strip | 2D HUD notices | as is |
| `features/combat/logic/hud_layout.gd` | Pure screen-rect maths: bounds, panels dodging fighters, pointing | Rect provider for the 2D HUD (replaces the 3D projection) | as is |
| `features/combat/view/battle_rects.gd` | Projects 3D fighter boxes to screen | Only the interface idea: feed sprite rects instead | idea only |
| `features/map/logic/map_plan.gd` | Walkable cell runs, aspect fitting, marker positioning | 2D Neon floor-plan map | port |
| `features/map/view/holo_map_legend.gd`, `features/map/view/holo_map_markers.gd` | Legend panel; marker icons (player, npc, vendor, quest) | Legend and pins on a 2D map | as is |
| `features/map/defs/map_marker_def.gd`, `content/world/map_markers.json`, `content/ui/map.json` | Marker kinds and place links, one quest flag; map coordinates and sector key | Marker and map metadata for the 2D map | as is |
| `features/map/view/holo_map_geo.gd`, `features/map/view/holo_city_old_town.gd` | Metres-to-screen projection with radial compression; Old City disc, rings, Bab al-Yaman, al-Saila | City-map projection and art for 2D (restyle the palette) | as is |
| `features/puzzles/view/puzzle_level.gd` | Places a level puzzle from the valve place; one spot per piece | Valve puzzle placement on a 2D plate | port |
| `features/ui/view/area_title_card.gd` | Musnad/English title, frieze, subtitle, fade | Area title card; drop the year line (no calendar year) | port |
| `features/ui/view/loot_popup.gd` | Queued "Obtained" banners, rarity colour, "+N riyal" | Loot and riyal feedback | as is |
| `content/world/storm.json`, `features/world/weather/defs/storm_def.gd`, `features/world/weather/view/storm_builder.gd` | Rain/splash/puddle/drip/steam/lightning preset and 3D builder | 2D rain overlay; keep the splash/puddle timing and colour ideas | port |
| `content/dialogue/talks.json`, `content/dialogue/dialogues.json`, `features/dialogue/logic/talk_picker.gd`, `features/dialogue/logic/dialogue_run.gd` | Abu Nabil first/after-battle/four chats, haggle branches A-D, duel effects; first-to-after-battle-to-chat picker | His stall talk if level 1 joins the opening | as is |
| `content/economy/shops.json` | Herb stock, greeting, price multiplier keyed on `abu_nabil_beaten` | Prices keyed to the beaten flag (shop screen is already on main) | as is |
| `content/world/areas.json` (`souq_rooftops_v4`) | Level-1 layout: R1-R5 safe spots, X1-X5 crossings, patrol lanes, valve place, loop | Layout ideas if the parked level 1 joins the opening | idea only |
| `content/world/look.json`, `content/world/mist.json`, `content/world/sky.json`, `content/world/skyline.json` | Night look, mist layers, sky, skyline bands | Art direction for the 2D night (fog, skyline, moon) | idea only |

## Do not reuse

- `features/world/player/player.gd`, `features/world/player/follower.gd`, `features/world/patrol/patrol.gd`, `features/world/rooftop/actor_body.gd`: runtime 3D characters; DECISIONS 2026-10-24 says characters are offline 3D renders as sprites, none at runtime.
- `features/world/view/painted_look.gd`, `features/world/view/painted_materials.gd`, `features/world/view/diorama.gd`, `content/world/look.json`: the painted 3D diorama; DECISIONS 2026-10-26 makes Neon isometric like Hades and DECISIONS 2026-10-24 fixes the 2D isometric ink-comic.
- `features/world/view/explore_camera.gd`, `features/world/view/follow_camera_rig.gd`, `features/combat/view/battle_camera.gd`, `features/combat/view/battle_camera_rig.gd`, `content/world/camera.json`: 3D perspective rigs; DECISIONS 2026-10-26 is isometric (first-playable: a 2:1 dimetric plate).
- `features/world/defs/tile_def.gd`, `features/world/view/area_builder.gd`, `content/world/tiles.json`: tile-grid blocks (MultiMesh in the archive); first-playable puts the walkable area in `content/neon/rooms.json` polygons with y-sort by feet.
- `features/map/view/holo_map.gd`, `features/map/view/holo_map_canvas.gd`, `features/map/view/holo_scan.gdshader`: the 3D holo table; the retire audit removed HoloMap and DECISIONS 2026-10-24 is 2D, so keep only the logic and legend above.
- `features/combat/view/battle_stage.gd`, `features/combat/view/arena_builder.gd`, `features/combat/view/arena_dressing.gd`, `features/combat/view/battle_shatter.gd`: arena swap and 3D stage; DECISIONS 2026-10-26 keeps fights turn-based on the map.
- `features/puzzles/view/yard_builder.gd`, `features/puzzles/view/puzzle_yard.tscn`: grey-box 3D yard; DECISIONS 2026-10-24 fixes the 2D look, and the puzzle rules already stay on main.
- `features/world/view/prop_mesh.gd`, `features/world/view/tower_house.gd`, `features/world/view/skyline_builder.gd`, `content/world/buildings.json`, `content/world/props.json`: 3D meshes; DECISIONS 2026-10-24 uses 2D isometric plates.

## Tests worth porting with the reused piece

- `features/world/tests/test_walk_graph.gd`: reachability, 2 m corridors, traps and steps on every area.
- `features/world/tests/test_places.gd`: patrol lane maths, unstuck/return picks, StallKeeper placement.
- `features/world/tests/test_safe_spot.gd`: two newest spots; the wedged spot is skipped.
- `features/world/tests/test_ambush.gd`: who struck first, from the patrol's walking direction.
- `features/world/tests/test_sabil_patrols.gd`: a drink saves, refills and revives patrols; grace time.
- `features/world/tests/test_crossing_freeze.gd`: a crossing press must not freeze the party (2026-10-24 bug).
- `features/dialogue/tests/test_talk_picker.gd`: first, then after-battle, then chat wrapping.
- `features/dialogue/tests/test_abu_nabil_haggle.gd`: branches A-D, flags, prices before and after.
- `features/combat/tests/test_battle_item_menu.gd`: herb list, targets, back, reserved cast.
- `features/combat/tests/test_hud_layout.gd`: pure rect maths: panels dodge fighters; pointing.
- `features/ui/tests/test_popups.gd`: loot queue order and the area title card.
- `features/map/tests/test_holo_map.gd`: map planning and marker filtering.
- `features/puzzles/tests/test_puzzle_place.gd`: puzzle order, saved flags, spawn, view.
- `features/world/tests/test_level1_blockout.gd`: R1-R5/X1-X5 reachability, loop, clearances.
