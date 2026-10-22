extends TestCase
## Area, tile and look content: the rooftop layout is well formed and every probe of a broken layout is caught.


func _area() -> AreaDef:
	return ContentDB.get_def("area", &"souq_rooftops") as AreaDef


func test_content_loads_clean() -> void:
	var errors: PackedStringArray = ContentDB.load_all()
	check(errors.is_empty(), "content problems: " + "; ".join(errors))


func test_rooftop_area_is_well_formed() -> void:
	var area: AreaDef = _area()
	check(area != null, "area souq_rooftops exists")
	check(area.problems().is_empty(), "layout problems: " + "; ".join(area.problems()))
	check(area.width() >= 30 and area.depth() >= 24, "the area is about 34x26 tiles")
	check_eq(area.places_of(PlaceDef.PATROL).size(), 3, "three patrols")


func test_markers_stand_on_floor() -> void:
	var area: AreaDef = _area()
	for marker: String in AreaDef.MARKERS:
		var cell: Vector2i = area.find_marker(marker)
		var tile := ContentDB.get_def("tile", area.tile_id_at(cell.x, cell.y)) as TileDef
		check(tile != null and not tile.solid, "marker %s stands on a walkable tile" % marker)


func test_broken_layouts_are_caught() -> void:
	var legend: Dictionary[String, String] = {".": "roof_floor", "S": "roof_floor", "W": "roof_floor",
		"P": "roof_floor", "Q": "roof_floor"}
	var good := AreaDef.new()
	good.legend = legend
	good.rows = PackedStringArray(["SW..", "PQ.."])
	check(good.problems().is_empty(), "a small good layout passes: " + "; ".join(good.problems()))
	var variants: Array[PackedStringArray] = [
		PackedStringArray(["SW..", "PQ."]),
		PackedStringArray(["SW?.", "PQ.."]),
		PackedStringArray(["S...", "PQ.."]),
		PackedStringArray(["SWS.", "PQ.."]),
		PackedStringArray([]),
	]
	for rows: PackedStringArray in variants:
		var bad := AreaDef.new()
		bad.legend = legend
		bad.rows = rows
		check(not bad.problems().is_empty(), "layout %s is caught" % str(rows))


func test_look_v1_keeps_the_accepted_numbers() -> void:
	var look := ContentDB.get_def("look", &"v1") as LookDef
	check(look != null, "look v1 exists")
	check_eq(look.camera_offset, Vector3(0.0, 6.0, 8.5), "camera offset")
	check(is_equal_approx(look.fov, 30.0), "field of view 30")
	check(is_equal_approx(look.dof_near, 5.0) and is_equal_approx(look.dof_far, 12.0), "depth of field 5 to 12")
	check(is_equal_approx(look.dof_amount, 0.1), "depth of field amount 0.1")
	check_eq(look.sun_rotation, Vector3(-50.0, -35.0, 0.0), "sun rotation")


func test_building_footprints_block_walking_but_draw_nothing() -> void:
	var footprint := ContentDB.get_def("tile", &"footprint") as TileDef
	check(footprint != null and footprint.solid and footprint.hidden, "a building's cells are solid and invisible")
	var street := ContentDB.get_def("tile", &"street") as TileDef
	check(street.solid and street.hidden, "the sunken street's cells are solid and invisible (al-Saila shows below)")
	var floor_tile := ContentDB.get_def("tile", &"roof_floor") as TileDef
	check(floor_tile != null and not floor_tile.solid, "the roof floor is walkable")


func test_unwalkable_save_point_lands_on_spawn_start() -> void:
	var area: AreaDef = _area()
	var spawn_pos: Vector3 = area.spawn_position_for(&"spawn_start")
	check_eq(area.spawn_position_for(&"nonexistent_point"), spawn_pos, "missing save point lands on spawn_start")
	check_eq(area.spawn_position_for(&""), spawn_pos, "empty save point lands on spawn_start")
	var bad_place := PlaceDef.new()
	bad_place.id = &"test_unwalkable"
	bad_place.pos = Vector3(1.5, 0.0, 1.5)
	area.places.append(bad_place)
	check(not area.is_walkable(1, 1), "cell (1,1) is not walkable")
	check_eq(area.spawn_position_for(&"test_unwalkable"), spawn_pos, "unwalkable save point lands on spawn_start")
	area.places.erase(bad_place)

