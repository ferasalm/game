extends TestCase
## Unit tests for Level 1 polish: default area souq_rooftops_v4, blocked cells under ac units, on_prop height, patrol drone lane over X4 gap, and crossing camera zones yaw.

const AREA_ID: StringName = &"souq_rooftops_v4"


func _rules() -> ExploreRulesDef:
	return ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef


func test_default_area_is_souq_rooftops_v4() -> void:
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	check_eq(rooftop.area_id, AREA_ID, "default area is souq_rooftops_v4")
	rooftop.free()


func test_old_area_ac_unit_cells_are_blocked() -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var wg: WalkGraph = AreaWalk.build(area, _rules())
	check(not wg.is_open(Vector2i(1, 21)), "old souq_rooftops cell (1, 21) under ac_unit is blocked")
	check(not wg.is_open(Vector2i(32, 11)), "old souq_rooftops cell (32, 11) under ac_unit is blocked")


func test_on_prop_respects_height() -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var at_floor := Vector3(1.0, 0.0, 21.5)
	check(AreaWalk.on_prop(area, _rules(), at_floor), "on_prop is true when capsule overlaps prop height")
	var high_up := Vector3(1.0, 3.0, 21.5)
	check(not AreaWalk.on_prop(area, _rules(), high_up), "on_prop is false when body is above prop")


func test_patrol_drone_lane_crosses_x4_gap() -> void:
	var area := ContentDB.get_def("area", AREA_ID) as AreaDef
	var drone: PlaceDef = null
	for p: PlaceDef in area.places_of(PlaceDef.PATROL):
		if p.id == &"patrol_drone":
			drone = p
			break
	check(drone != null, "patrol_drone exists in souq_rooftops_v4")
	var x4: PlaceDef = null
	for c: PlaceDef in area.places_of(PlaceDef.CROSSING):
		if c.id == &"x4":
			x4 = c
			break
	check(x4 != null, "crossing X4 exists")
	var min_drone_x: float = minf(drone.pos.x, drone.end.x)
	var max_drone_x: float = maxf(drone.pos.x, drone.end.x)
	var drone_z: float = (drone.pos.z + drone.end.z) / 2.0
	var min_x4_z: float = minf(x4.from_pos.y, x4.to_pos.y)
	var max_x4_z: float = maxf(x4.from_pos.y, x4.to_pos.y)
	var x4_x: float = (x4.from_pos.x + x4.to_pos.x) / 2.0
	check(x4_x >= min_drone_x and x4_x <= max_drone_x, "drone lane spans across X4 x coordinate")
	check(drone_z >= min_x4_z and drone_z <= max_x4_z, "drone lane crosses between X4 landings")


func test_camera_zones_x3_and_x5_yaw() -> void:
	var area := ContentDB.get_def("area", AREA_ID) as AreaDef
	var z3: PlaceDef = null
	var z5: PlaceDef = null
	for p: PlaceDef in area.places:
		if p.id == &"zone_x3":
			z3 = p
		elif p.id == &"zone_x5":
			z5 = p
	check(z3 != null, "zone_x3 exists")
	check(z5 != null, "zone_x5 exists")
	check(is_equal_approx(z3.yaw, 90.0) or is_equal_approx(z3.yaw, 270.0), "zone_x3 yaw is 90 or 270")
	check(is_equal_approx(z5.yaw, 90.0) or is_equal_approx(z5.yaw, 270.0), "zone_x5 yaw is 90 or 270")


func test_abu_nabil_stands_within_one_and_a_half_metres_of_counter_end() -> void:
	var area := ContentDB.get_def("area", AREA_ID) as AreaDef
	var seller: PlaceDef = null
	for p: PlaceDef in area.places_of(PlaceDef.NPC):
		if p.id == &"herb_seller":
			seller = p
			break
	check(seller != null, "herb_seller place exists in souq_rooftops_v4")
	check_eq(seller.prop, &"herb_stall", "herb_seller links to prop herb_stall")
	var counter: Placement = AreaActors.kept_prop(area, seller)
	check(counter != null, "herb_stall prop found by kept_prop")
	var rules := _rules()
	var keeper_pos: Vector3 = AreaActors.keeper_point(counter, rules, 0.0)
	var stall_def := ContentDB.get_def("prop", counter.ref) as PropDef
	check(stall_def != null, "herb_stall prop def exists")
	var counter_end := Vector2(counter.pos.x, counter.pos.z) + Vector2(-stall_def.collide.x / 2.0, 0.0).rotated(-deg_to_rad(counter.yaw))
	var dist: float = Vector2(keeper_pos.x, keeper_pos.z).distance_to(counter_end)
	check(dist <= 1.5, "stall keeper stands within 1.5 m of his stall's counter end (got %.2f m)" % dist)

