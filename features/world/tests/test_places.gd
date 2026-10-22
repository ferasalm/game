extends TestCase
## The typed places of the rooftop (docs/design/rooftop-v3.md section 3): valid ids and references, every standing
## point and patrol end reachable, the props they use stand next to them, and the patrol lanes keep away from the
## commons; PatrolSafety's lane maths and the unstuck and return picks; a keeper stands at his counter's end facing
## his customers (StallKeeper) and no NPC overlaps a prop's collision.

const CLEARANCE: float = 3.0
const COMMONS_X: Vector2 = Vector2(5.0, 10.0)
const COMMONS_Z_MIN: float = 18.0


func _area() -> AreaDef:
	return ContentDB.get_def("area", &"souq_rooftops") as AreaDef


func _rules() -> ExploreRulesDef:
	return ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef


func _reach(area: AreaDef) -> Dictionary[Vector2i, bool]:
	return AreaWalk.build(area, _rules()).reachable(area.find_marker(AreaDef.SPAWN))


func _near_reachable(reach: Dictionary[Vector2i, bool], p: Vector3, radius: float) -> bool:
	for cell: Vector2i in reach:
		if Vector2(cell.x + 0.5, cell.y + 0.5).distance_to(Vector2(p.x, p.z)) <= radius:
			return true
	return false


func test_places_are_well_formed() -> void:
	var area: AreaDef = _area()
	check(area.problems().is_empty(), "layout problems: " + "; ".join(area.problems()))
	check_eq(area.places_of(PlaceDef.PATROL).size(), 3, "three patrols")
	check_eq(area.places_of(PlaceDef.CHEST).size(), 2, "two chests")
	for kind: StringName in [PlaceDef.SPAWN, PlaceDef.WORKSHOP, PlaceDef.NPC, PlaceDef.SHOP, PlaceDef.SAVE, PlaceDef.VISTA]:
		check_eq(area.places_of(kind).size(), 1, "one %s place" % kind)
	check_eq(area.places_of(PlaceDef.VISTA)[0].rect, area.vista, "the vista place is the vista zone")
	for p: PlaceDef in area.places_of(PlaceDef.PATROL):
		check(ContentDB.get_def("encounter", p.encounter) != null, "%s: encounter %s exists" % [p.id, p.encounter])
	check(ContentDB.get_def("shop", area.places_of(PlaceDef.SHOP)[0].shop) != null, "the shop id exists")


func test_spawn_and_workshop_places_match_the_markers() -> void:
	var area: AreaDef = _area()
	check_eq(area.places_of(PlaceDef.SPAWN)[0].cell, area.find_marker(AreaDef.SPAWN), "spawn")
	check_eq(area.places_of(PlaceDef.WORKSHOP)[0].cell, area.find_marker(AreaDef.WORKSHOP), "workshop")


func test_every_use_point_is_reachable() -> void:
	var area: AreaDef = _area()
	var reach: Dictionary[Vector2i, bool] = _reach(area)
	for p: PlaceDef in area.places:
		if p.kind == PlaceDef.VISTA:
			for z: int in range(p.rect.position.y, p.rect.end.y):
				for x: int in range(p.rect.position.x, p.rect.end.x):
					check(reach.has(Vector2i(x, z)), "vista cell (%d, %d) is reachable" % [x, z])
		elif p.kind == PlaceDef.CAMERA_ZONE:
			for z: int in range(floori(p.zone_rect.position.y), ceili(p.zone_rect.end.y)):
				for x: int in range(floori(p.zone_rect.position.x), ceili(p.zone_rect.end.x)):
					check(reach.has(Vector2i(x, z)), "%s cell (%d, %d) is reachable" % [p.id, x, z])
		elif p.kind == PlaceDef.CHEST or p.kind == PlaceDef.NPC:
			check(_near_reachable(reach, p.pos, _rules().interact_radius), "%s: a reachable cell within reach" % p.id)
		else:
			check(reach.has(p.cell), "%s: its cell is reachable" % p.id)
		if p.kind == PlaceDef.PATROL:
			check(reach.has(AreaWalk.cell_of(p.end)), "%s: the far end is reachable" % p.id)


func test_stall_and_sabil_stand_beside_their_props() -> void:
	var area: AreaDef = _area()
	for p: PlaceDef in area.places:
		if p.prop == &"":
			continue
		var found: bool = false
		for placed: Placement in area.props:
			found = found or (placed.ref == p.prop and Vector2(placed.pos.x - p.pos.x, placed.pos.z - p.pos.z).length() <= 2.0)
		check(found, "%s: a %s prop stands within 2 m" % [p.id, p.prop])


func test_patrols_keep_clear_of_the_commons() -> void:
	var area: AreaDef = _area()
	var keep: Array[PlaceDef] = [area.places_of(PlaceDef.SPAWN)[0], area.places_of(PlaceDef.SHOP)[0],
		area.places_of(PlaceDef.SAVE)[0], area.places_of(PlaceDef.WORKSHOP)[0]]
	for patrol: PlaceDef in area.places_of(PlaceDef.PATROL):
		var lane := PackedVector3Array([patrol.pos, patrol.end])
		for spot: PlaceDef in keep:
			check(PatrolSafety.lane_distance(spot.pos, lane) >= CLEARANCE, "%s is %.1f m from %s" % [
				patrol.id, PatrolSafety.lane_distance(spot.pos, lane), spot.id])
		for end: Vector3 in [patrol.pos, patrol.end]:
			check(end.z < COMMONS_Z_MIN or end.x < COMMONS_X.x or end.x > COMMONS_X.y, "%s never enters the commons" % patrol.id)


func test_safe_places_are_clear_of_every_patrol() -> void:
	var area: AreaDef = _area()
	var reach: Dictionary[Vector2i, bool] = _reach(area)
	var lanes: Array[PackedVector3Array] = []
	for patrol: PlaceDef in area.places_of(PlaceDef.PATROL):
		lanes.append(PackedVector3Array([patrol.pos, patrol.end]))
	check(area.places_of(PlaceDef.SAFE).size() >= 6, "at least six safe places")
	for safe: PlaceDef in area.places_of(PlaceDef.SAFE):
		check(reach.has(safe.cell), "%s is reachable" % safe.id)
		check(PatrolSafety.is_clear(safe.pos, lanes, CLEARANCE), "%s is %.1f m from the nearest patrol lane" % [
			safe.id, PatrolSafety.nearest_lane_distance(safe.pos, lanes)])


func test_lane_distance_is_to_the_segment() -> void:
	var lane := PackedVector3Array([Vector3(0, 0, 0), Vector3(10, 0, 0)])
	check(is_equal_approx(PatrolSafety.lane_distance(Vector3(5, 0, 3), lane), 3.0), "beside the lane")
	check(is_equal_approx(PatrolSafety.lane_distance(Vector3(13, 0, 4), lane), 5.0), "past its end")


func test_return_spot_keeps_a_clear_origin_and_moves_a_close_one() -> void:
	var lanes: Array[PackedVector3Array] = [PackedVector3Array([Vector3(0, 0, 0), Vector3(10, 0, 0)])]
	var cells: Array[Vector3] = [Vector3(5, 0, 2), Vector3(5, 0, 5), Vector3(5, 0, 9)]
	check_eq(PatrolSafety.return_spot(Vector3(5, 0, 8), cells, lanes, 3.5), Vector3(5, 0, 8), "a clear spot stays")
	check_eq(PatrolSafety.return_spot(Vector3(5, 0, 1), cells, lanes, 3.5), Vector3(5, 0, 5), "a close one moves to the nearest clear cell")
	check_eq(PatrolSafety.return_spot(Vector3(5, 0, 1), cells, lanes, 99.0), Vector3(5, 0, 9), "nothing clear: the farthest cell")


func test_unstuck_skips_the_wedged_spot_and_the_patrol_side() -> void:
	var lanes: Array[PackedVector3Array] = [PackedVector3Array([Vector3(0, 0, 0), Vector3(10, 0, 0)])]
	var spots: Array[Vector3] = [Vector3(5, 0, 8), Vector3(5, 0, 1), Vector3(5, 0, 9.5)]
	var safe: Array[Vector3] = [Vector3(1, 0, 12), Vector3(9, 0, 12)]
	var here := Vector3(5, 0, 9.7)
	check_eq(PatrolSafety.unstuck_spot(here, spots, safe, lanes, 3.0, 1.5), Vector3(5, 0, 8), "newest spot not under him, clear of the patrol")
	check_eq(PatrolSafety.unstuck_spot(here, [Vector3(5, 0, 1)], safe, lanes, 3.0, 1.5), Vector3(1, 0, 12), "else the nearest safe place")
	check_eq(PatrolSafety.unstuck_spot(here, [], [], lanes, 3.0, 1.5), here, "nothing known: stays")


func test_a_keeper_stands_at_his_counters_end_clear_of_it() -> void:
	var box := Vector3(2.2, 1.2, 1.0)
	var spot: Vector2 = StallKeeper.at_end(Vector2(6.0, 12.5), 0.0, box, 0.3, 0.15)
	check(spot.is_equal_approx(Vector2(4.45, 12.5)), "yaw 0: the end is -x, half the width + radius + gap (%s)" % spot)
	var turned: Vector2 = StallKeeper.at_end(Vector2.ZERO, 90.0, box, 0.3, 0.15)
	check(turned.is_equal_approx(Vector2(0.0, 1.55)), "yaw 90: the end turns to +z (%s)" % turned)
	check(is_equal_approx(StallKeeper.facing(Vector2.ZERO, Vector2(1.0, 0.0)), 90.0), "facing +x is yaw 90")
	check(is_equal_approx(StallKeeper.facing(Vector2.ZERO, Vector2(0.0, 1.0)), 0.0), "facing +z is yaw 0")


func test_no_npc_overlaps_a_prop() -> void:
	for area_id: StringName in ContentDB.ids("area"):
		var area := ContentDB.get_def("area", area_id) as AreaDef
		var holder := Node3D.new()
		tree.root.add_child(holder)
		var actors: AreaActors = AreaActors.build(holder, area, _rules(), AreaWalk.floor_height(area))
		for i: int in actors.bystanders.size():
			var place: PlaceDef = actors.bystander_places[i]
			var at: Vector3 = actors.bystanders[i].position
			check(not AreaWalk.on_prop(area, _rules(), at), "%s/%s: clear of every prop's collision at %s" % [area_id, place.id, at])
			var counter: Placement = AreaActors.kept_prop(area, place)
			if counter != null:
				var reach: float = Vector2(at.x - place.pos.x, at.z - place.pos.z).length()
				check(reach < 3.0, "%s stands at %s, %.1f m from where he is talked to" % [place.id, counter.ref, reach])
		holder.free()
