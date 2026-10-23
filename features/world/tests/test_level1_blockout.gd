extends TestCase
## Unit tests for Level 1 blockout: area souq_rooftops_v4, crossings X1-X5, walk-graph regions, reachability, loop, and clearances.

const AREA_ID: StringName = &"souq_rooftops_v4"


func _area() -> AreaDef:
	return ContentDB.get_def("area", AREA_ID) as AreaDef


func _rules() -> ExploreRulesDef:
	return ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef


func test_crossing_places_parse_and_connect_regions() -> void:
	var area: AreaDef = _area()
	check(area != null, "area souq_rooftops_v4 exists")
	var crossings: Array[PlaceDef] = area.places_of(PlaceDef.CROSSING)
	check_eq(crossings.size(), 5, "5 crossings X1-X5 exist")
	var kinds: Array[StringName] = [&"board", &"bridge", &"zipline", &"leap", &"cable"]
	for i: int in 5:
		check_eq(crossings[i].crossing_kind, kinds[i], "crossing %d is %s" % [i + 1, kinds[i]])
	check(crossings[2].one_way, "X3 zipline is one-way")
	check(not crossings[0].one_way and not crossings[1].one_way, "X1 and X2 are two-way")
	check(not crossings[3].one_way and not crossings[4].one_way, "X4 and X5 are two-way")
	var wg: WalkGraph = AreaWalk.build(area, _rules())
	var regs: Array[Dictionary] = wg.regions(0.1)
	check_eq(regs.size(), 5, "5 roofs form 5 distinct height-separated regions")


func test_reachability_and_loop_and_r5_isolation() -> void:
	var area: AreaDef = _area()
	var wg: WalkGraph = AreaWalk.build(area, _rules())
	var crossings: Array[PlaceDef] = area.places_of(PlaceDef.CROSSING)
	var spawn: PlaceDef = area.place(&"spawn_start")
	var sc := Vector2i(floori(spawn.pos.x), floori(spawn.pos.z))
	var reached: Dictionary[Vector2i, bool] = wg.reachable_with_crossings(sc, crossings)
	check_eq(reached.size(), wg.open_cells().size(), "every open cell across all 5 roofs is reachable")
	var no_x4: Array[PlaceDef] = []
	for x: PlaceDef in crossings:
		if x.id != &"x4":
			no_x4.append(x)
	var loop_reach: Dictionary[Vector2i, bool] = wg.reachable_with_crossings(sc, no_x4)
	var r5_cell: Vector2i = area.place(&"safe_r5").cell
	check(not loop_reach.has(r5_cell), "R5 is NOT reachable without X4")
	for roof_safe: StringName in [&"safe_r1", &"safe_r2", &"safe_r3", &"safe_r4"]:
		check(loop_reach.has(area.place(roof_safe).cell), "%s is reachable in the loop" % roof_safe)


func test_all_places_and_patrol_endpoints_reachable() -> void:
	var area: AreaDef = _area()
	var wg: WalkGraph = AreaWalk.build(area, _rules())
	var crossings: Array[PlaceDef] = area.places_of(PlaceDef.CROSSING)
	var spawn: PlaceDef = area.place(&"spawn_start")
	var sc := Vector2i(floori(spawn.pos.x), floori(spawn.pos.z))
	var reached: Dictionary[Vector2i, bool] = wg.reachable_with_crossings(sc, crossings)
	for p: PlaceDef in area.places:
		if p.kind == PlaceDef.CAMERA_ZONE or p.kind == PlaceDef.VISTA:
			continue
		if p.kind == PlaceDef.CROSSING:
			check(reached.has(p.from_cell()) and reached.has(p.to_cell()), "crossing %s ends reachable" % p.id)
		elif p.kind == PlaceDef.PATROL:
			if p.id != &"patrol_drone":
				check(reached.has(p.cell), "patrol %s start reachable" % p.id)
				check(reached.has(Vector2i(floori(p.end.x), floori(p.end.z))), "patrol %s end reachable" % p.id)
		else:
			check(reached.has(p.cell), "place %s (%s) reachable" % [p.id, p.kind])


func test_section5_width_and_traps_on_every_roof() -> void:
	var area: AreaDef = _area()
	var wg: WalkGraph = AreaWalk.build(area, _rules())
	check(wg.traps().is_empty(), "no trap cells on any roof")
	var wide: PackedByteArray = wg.wide_mask()
	for reg: Dictionary in wg.regions(0.1):
		for cell: Vector2i in reg:
			if wide[cell.y * wg.width + cell.x] == 1:
				continue
			var touches_wide: bool = false
			for step: Vector2i in WalkGraph.AROUND:
				var next: Vector2i = cell + step
				if next.x >= 0 and next.y >= 0 and next.x < wg.width and next.y < wg.depth:
					if wide[next.y * wg.width + next.x] == 1:
						touches_wide = true
						break
			check(touches_wide, "pocket cell %s touches a 2x2 wide block" % str(cell))


func test_patrol_clearances_and_home_roofs_safe() -> void:
	var area: AreaDef = _area()
	var wg: WalkGraph = AreaWalk.build(area, _rules())
	var regs: Array[Dictionary] = wg.regions(0.1)
	var home_cells: Dictionary[Vector2i, bool] = {}
	for safe_id: StringName in [&"safe_r1", &"safe_r2", &"safe_r3"]:
		var p: PlaceDef = area.place(safe_id)
		for reg: Dictionary in regs:
			if reg.has(p.cell):
				home_cells.merge(reg)
	var crossings: Array[PlaceDef] = area.places_of(PlaceDef.CROSSING)
	var sensitive_points: Array[Vector2] = []
	for x: PlaceDef in crossings:
		sensitive_points.append(x.from_pos)
		sensitive_points.append(x.to_pos)
	sensitive_points.append(Vector2(area.place(&"shop_herbs").pos.x, area.place(&"shop_herbs").pos.z))
	sensitive_points.append(Vector2(area.place(&"sabil").pos.x, area.place(&"sabil").pos.z))
	for p: PlaceDef in area.places_of(PlaceDef.PATROL):
		check(not home_cells.has(p.cell), "patrol %s is not on home roofs R1-R3" % p.id)
		if p.id == &"patrol_drone":
			continue
		for pt: Vector2 in sensitive_points:
			var d_start: float = Vector2(p.pos.x, p.pos.z).distance_to(pt)
			var d_end: float = Vector2(p.end.x, p.end.z).distance_to(pt)
			check(d_start >= 2.95 and d_end >= 2.95, "patrol %s clear from %s (d=%f, %f)" % [p.id, pt, d_start, d_end])


func test_level1_places_and_camera_zones() -> void:
	var area: AreaDef = _area()
	var door: PlaceDef = area.place(&"door_tayramana")
	check(door != null and door.target == &"tayramana", "door to tayramana exists")
	check_eq(door.prompt, &"WORLD_PROMPT_ENTER", "door prompt is WORLD_PROMPT_ENTER")
	var valve: PlaceDef = area.place(&"valve_water")
	check(valve != null and valve.prompt == &"WORLD_PROMPT_TURN", "valve has WORLD_PROMPT_TURN")
	var water_tank: Placement = null
	for prop: Placement in area.props:
		if prop.ref == &"water_tower":
			water_tank = prop
	check(water_tank != null, "water tower prop stands on R5")
	var zone_r5: PlaceDef = area.place(&"zone_r5")
	var zone_x4: PlaceDef = area.place(&"zone_x4")
	check(zone_r5 != null and is_equal_approx(zone_r5.roll, 6.0), "zone_r5 has roll 6")
	check(zone_x4 != null and is_equal_approx(zone_x4.roll, 6.0), "zone_x4 has roll 6")


func test_crossing_interact_moves_player() -> void:
	var rules := _rules()
	var player := Player.new(rules)
	player.position = Vector3(28.5, -0.8, 27.5)
	var x_place := PlaceDef.new()
	x_place.id = &"x1"
	x_place.kind = PlaceDef.CROSSING
	x_place.crossing_kind = &"board"
	x_place.from_pos = Vector2(28.5, 27.5)
	x_place.to_pos = Vector2(28.5, 23.5)
	var spot := CrossingSpot.new(rules, player, x_place, Vector3(28.5, -0.8, 27.5), Vector3(28.5, 0.0, 23.5))
	check(spot.prompt != null, "crossing prompt exists")
	check_eq(spot.prompt.text, "E: cross board", "prompt text is localized")
	spot.cross_to(Vector3(28.5, 0.0, 23.5))
	check(player.position.distance_to(Vector3(28.5, 0.0, 23.5)) < 0.05, "player crossed to target")
	spot.free()
	player.free()


func _lowest_floor(area: AreaDef) -> float:
	var lowest: float = INF
	for z: int in area.depth():
		for x: int in area.width():
			if not area.is_walkable(x, z):
				continue
			var tile := ContentDB.get_def("tile", area.tile_id_at(x, z)) as TileDef
			if tile != null:
				lowest = minf(lowest, tile.height)
	return lowest


func test_no_mist_layer_reaches_within_two_metres_of_lowest_floor() -> void:
	var area: AreaDef = _area()
	var lowest_floor: float = _lowest_floor(area)
	check(lowest_floor < INF, "lowest floor found")
	for mist_id: StringName in area.mist:
		var mist := ContentDB.get_def("mist", mist_id) as MistDef
		check(mist != null, "mist def %s exists" % mist_id)
		for i: int in mist.stack:
			var layer_y: float = mist.height + float(i) * mist.step
			check(lowest_floor - layer_y >= 2.0,
				"mist %s layer %d (y=%.2f) stays >= 2 m below lowest floor (%.2f)" % [mist_id, i, layer_y, lowest_floor])


func test_storm_and_height_fog_below_the_low_roofs() -> void:  # R4/R5 drowned in the look's height fog
	var area: AreaDef = _area()
	check_eq(area.weather, "storm", "level 1 is a night storm")
	check(not is_nan(area.fog_height) and _lowest_floor(area) - area.fog_height >= 2.0,
		"height fog pools >= 2 m below the lowest roof")


func test_every_patrol_and_npc_has_a_sprite() -> void:  # v4 patrols drew the magenta placeholder
	for area_id: StringName in ContentDB.ids("area"):
		var area := ContentDB.get_def("area", area_id) as AreaDef
		for place: PlaceDef in area.places_of(PlaceDef.PATROL) + area.places_of(PlaceDef.NPC):
			check(place.sprite != &"", "%s %s has a sprite" % [area_id, place.id])
