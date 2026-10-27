extends TestCase
## purpose: Tests EquipmentMenu layout rects, header label widths, and connector lines.

const OWNED: Array[StringName] = [
	&"grandfather_hilt", &"swift_hilt", &"rustwire_blade", &"keen_blade", &"salvage_arm", &"arc_arm",
	&"wrist_rig", &"lens_array", &"courier_jacket", &"rig_shawl", &"aqiq_red",
]


func _open_menu() -> EquipmentMenu:
	GameState.start_new()
	Inventory.add_all(GameState.inventory, OWNED)
	var menu: EquipmentMenu = Screens.open(&"equipment") as EquipmentMenu
	return menu


func test_rects_match_spec_within_2px() -> void:
	var menu: EquipmentMenu = _open_menu()
	check_approx(menu.tabs.position.x, 80.0, 2.0, "tabs x")
	check_approx(menu.tabs.position.y, 40.0, 2.0, "tabs y")
	check_approx(menu.header.position.x, 80.0, 2.0, "header x")
	check_approx(menu.header.position.y, 124.0, 2.0, "header y")
	check_approx(menu.owned_list.position.x, 80.0, 2.0, "list x")
	check_approx(menu.owned_list.position.y, 280.0, 2.0, "list y")
	check_approx(menu.stage.position.x, 560.0, 2.0, "stage x")
	check_approx(menu.stage.position.y, 140.0, 2.0, "stage y")
	check_approx(menu.boxes_manager.boxes[&"blade"].position.x, 600.0, 2.0, "blade x")
	check_approx(menu.boxes_manager.boxes[&"blade"].position.y, 180.0, 2.0, "blade y")
	check_approx(menu.boxes_manager.boxes[&"armor"].position.x, 1210.0, 2.0, "armor x")
	check_approx(menu.boxes_manager.boxes[&"armor"].position.y, 180.0, 2.0, "armor y")
	check_approx(menu.stats.position.x, 1400.0, 2.0, "stats x")
	check_approx(menu.stats.position.y, 140.0, 2.0, "stats y")
	check_approx(menu.desc.position.x, 80.0, 2.0, "desc x")
	check_approx(menu.desc.position.y, 900.0, 2.0, "desc y")
	Screens.clear()
	GameState.reset()


func test_no_two_connector_lines_intersect() -> void:
	var menu: EquipmentMenu = _open_menu()
	for hero_id: StringName in [&"rydan", &"bilqis"]:
		menu.show_hero(hero_id)
		menu.stage._process(0.01)
		var lines_dict: Dictionary[StringName, Line2D] = menu.stage.lines()
		var visible_lines: Array[Line2D] = []
		for p: StringName in lines_dict:
			var l: Line2D = lines_dict[p]
			if l.visible and l.points.size() >= 2:
				visible_lines.append(l)
		check(visible_lines.size() >= 2, "%s: at least 2 visible connector lines" % hero_id)
		var intersected: bool = false
		var shared: bool = false
		for i: int in visible_lines.size():
			for j: int in range(i + 1, visible_lines.size()):
				var l1: Line2D = visible_lines[i]
				var l2: Line2D = visible_lines[j]
				if _segments_intersect(l1.points[0], l1.points[1], l2.points[0], l2.points[1]):
					intersected = true
				if l1.points[1].distance_to(l2.points[1]) < 8.0:
					shared = true
		check(not intersected, "%s: no two connector lines intersect" % hero_id)
		check(not shared, "%s: no two connector lines share an end point" % hero_id)
	Screens.clear()
	GameState.reset()


func test_header_labels_lie_inside_the_header_rect() -> void:
	var menu: EquipmentMenu = _open_menu()
	var header_rect: Rect2 = menu.header.get_global_rect()
	for hero_id: StringName in [&"rydan", &"bilqis"]:
		menu.show_hero(hero_id)
		for node: Node in NodeScan.of_type(menu.header, &"Label"):
			var l := node as Label
			if l.text.is_empty():
				continue
			var rect: Rect2 = l.get_global_rect()
			check(rect.position.x >= header_rect.position.x - 1.0 and rect.position.y >= header_rect.position.y - 1.0
					and rect.end.x <= header_rect.end.x + 1.0 and rect.end.y <= header_rect.end.y + 1.0,
					"%s label '%s' lies inside the header rect" % [hero_id, l.text])
	Screens.clear()
	GameState.reset()


func check_approx(val: float, target: float, tolerance: float, msg: String) -> void:
	check(absf(val - target) <= tolerance, "%s: expected %f got %f" % [msg, target, val])


func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var d1: float = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
	var d2: float = (b.x - a.x) * (d.y - a.y) - (b.y - a.y) * (d.x - a.x)
	var d3: float = (d.x - c.x) * (a.y - c.y) - (d.y - c.y) * (a.x - c.x)
	var d4: float = (d.x - c.x) * (b.y - c.y) - (d.y - c.y) * (b.x - c.x)
	return ((d1 > 0.0 and d2 < 0.0) or (d1 < 0.0 and d2 > 0.0)) and ((d3 > 0.0 and d4 < 0.0) or (d3 < 0.0 and d4 > 0.0))
