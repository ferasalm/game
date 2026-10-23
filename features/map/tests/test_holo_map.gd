extends TestCase
## purpose: Tests for holographic map planning, marker filtering, city districts, and screen view.


func test_plan_3x2_area_walkable_cells_only() -> void:
	var area := AreaDef.new()
	area.id = &"test_area"
	area.name_key = "AREA_TEST"
	area.rows = PackedStringArray([
		".#.",
		"..#"
	])
	area.legend = {".": "roof_floor", "#": "parapet"}

	var plan: Dictionary = MapPlan.plan(area)
	var runs: Array[Rect2i] = plan.get("runs", [])
	check_eq(runs.size(), 3, "3 runs for walkable cells")
	check(runs.has(Rect2i(0, 0, 1, 1)), "row 0 cell 0")
	check(runs.has(Rect2i(2, 0, 1, 1)), "row 0 cell 2")
	check(runs.has(Rect2i(0, 1, 2, 1)), "row 1 cells 0..1")


func test_fit_keeps_aspect_inside_panel() -> void:
	var plan := {
		"bounds": Rect2(0.0, 0.0, 100.0, 50.0),
		"runs": [Rect2i(0, 0, 100, 50)]
	}
	var panel := Rect2(360.0, 140.0, 1200.0, 800.0)
	var fitted: Dictionary = MapPlan.fit(plan, panel)

	var scale_val: float = float(fitted.get("scale", 0.0))
	var offset: Vector2 = fitted.get("offset", Vector2.ZERO)
	check(scale_val > 0.0, "scale is positive")

	var top_left: Vector2 = Vector2(0.0, 0.0) * scale_val + offset
	var bottom_right: Vector2 = Vector2(100.0, 50.0) * scale_val + offset
	check(panel.has_point(top_left), "top left is inside panel")
	check(panel.has_point(bottom_right - Vector2(1.0, 1.0)), "bottom right is inside panel")


func test_quest_marker_flag_filtering() -> void:
	var area: AreaDef = ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	check(area != null, "souq_rooftops area exists")
	var q_def := ContentDB.get_def("map_marker", &"quest_water") as MapMarkerDef
	check(q_def != null, "quest_water def exists")

	var showing: Array[Dictionary] = MapPlan.markers(area, [q_def], {})
	check_eq(showing.size(), 1, "quest marker shows when flag unset")

	var hidden: Array[Dictionary] = MapPlan.markers(area, [q_def], {&"sabil_visited": true})
	check_eq(hidden.size(), 0, "quest marker hides when flag set")


func test_vendor_marker_for_shop_place() -> void:
	var area: AreaDef = ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var v_def := ContentDB.get_def("map_marker", &"shop_herbs") as MapMarkerDef
	check(v_def != null, "shop_herbs marker exists")

	var res: Array[Dictionary] = MapPlan.markers(area, [v_def], {})
	check_eq(res.size(), 1, "vendor marker found")
	if not res.is_empty():
		check_eq(res[0].kind, &"vendor", "kind is vendor")
		var pl: PlaceDef = area.place(&"shop_herbs")
		check(pl != null and res[0].cell == pl.cell, "cell matches shop place")


func test_screen_opens_by_id_and_from_pause() -> void:
	Router.state = Router.STATE_EXPLORING
	Screens.open(&"map")
	var map_screen: HoloMap = Screens.top() as HoloMap
	check(map_screen != null, "opens by id &map")
	Screens.clear()

	Screens.open(&"pause")
	var pause: PauseMenu = Screens.top() as PauseMenu
	check(pause != null, "pause opens")
	var map_btn: Button = pause.button_of(&"map")
	check(map_btn != null, "pause has Map button")
	if map_btn != null:
		map_btn.pressed.emit()
		var opened: HoloMap = Screens.top() as HoloMap
		check(opened != null, "map screen opened from pause button")
	Screens.clear()
	tree.paused = false
	Router.state = Router.STATE_TITLE


func test_y_toggles_city_and_area() -> void:
	Screens.open(&"map")
	var map_screen: HoloMap = Screens.top() as HoloMap
	check(map_screen != null, "map open")
	check_eq(map_screen.canvas.mode, HoloMapCanvas.Mode.AREA, "starts in AREA mode")

	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_Y
	map_screen._unhandled_input(key_event)
	check_eq(map_screen.canvas.mode, HoloMapCanvas.Mode.CITY, "toggled to CITY mode")

	map_screen._unhandled_input(key_event)
	check_eq(map_screen.canvas.mode, HoloMapCanvas.Mode.AREA, "toggled back to AREA mode")
	Screens.clear()
	tree.paused = false


func test_city_map_loads_eight_districts() -> void:
	var ids: Array[StringName] = ContentDB.ids("city_district")
	check_eq(ids.size(), 8, "city_map has 8 districts")
	for d_id: StringName in ids:
		var d := ContentDB.get_def("city_district", d_id) as CityDistrictDef
		check(d != null, "district def exists: " + str(d_id))
		if d != null:
			check(d.polygon.size() >= 3, "%s has >= 3 points (%d)" % [d_id, d.polygon.size()])


func test_player_marker_follows_moved_position() -> void:
	Screens.open(&"map")
	var map_screen: HoloMap = Screens.top() as HoloMap
	check(map_screen != null, "map open")

	map_screen.player_pos_override = Vector3(10.0, 0.0, 15.0)
	map_screen._process(0.1)
	check_eq(map_screen.canvas.player_world_pos, Vector3(10.0, 0.0, 15.0), "player pos updated")

	map_screen.player_pos_override = Vector3(25.0, 0.0, 5.0)
	map_screen._process(0.1)
	check_eq(map_screen.canvas.player_world_pos, Vector3(25.0, 0.0, 5.0), "player pos moved")
	Screens.clear()
	tree.paused = false
