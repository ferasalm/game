extends TestCase
## purpose: Tests EquipmentMenu layout, 3D hologram stage, slot boxes, equipping, preview and focus.

const OWNED: Array[StringName] = [
	&"grandfather_hilt", &"swift_hilt", &"rustwire_blade", &"keen_blade", &"salvage_arm", &"arc_arm",
	&"wrist_rig", &"lens_array", &"courier_jacket", &"rig_shawl", &"aqiq_red",
]


func _open_menu() -> EquipmentMenu:
	GameState.start_new()
	Inventory.add_all(GameState.inventory, OWNED)
	var menu: EquipmentMenu = Screens.open(&"equipment") as EquipmentMenu
	return menu


func test_screens_open_gives_equipment_menu() -> void:
	var menu: EquipmentMenu = _open_menu()
	check(menu != null, "Screens.open(&'equipment') gives an EquipmentMenu")
	Screens.clear()
	GameState.reset()


func test_bilqis_shows_two_boxes_zayd_five() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"zayd")
	check_eq(menu.boxes_manager.visible_boxes().size(), 5, "Zayd shows 5 boxes")
	menu.show_hero(&"bilqis")
	check_eq(menu.boxes_manager.visible_boxes().size(), 2, "Bilqis shows 2 boxes")
	Screens.clear()
	GameState.reset()


func test_equipping_writes_game_state_equipment() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"zayd")
	menu._on_slot_activated(&"hilt")
	var swift: EquipDef = ContentDB.get_def("hilt", &"swift_hilt") as EquipDef
	menu._on_item_pressed(swift)
	check_eq(GameState.equipment[&"zayd.hilt"], &"swift_hilt", "A on an item writes GameState.equipment")
	Screens.clear()
	GameState.reset()


func test_unowned_items_never_list() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"zayd")
	menu._on_slot_activated(&"hilt")
	for row: ListRow in menu.owned_list.rows():
		check(row.name_text() != Ui.text("HILT_ANVIL_HILT"), "unowned anvil_hilt never lists")
	Screens.clear()
	GameState.reset()


func test_qe_cycles_heroes() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"zayd")
	menu.cycle_hero(1)
	check_eq(menu.hero, &"bilqis", "E cycles to Bilqis")
	menu.cycle_hero(1)
	check_eq(menu.hero, &"zayd", "E cycles back to Zayd")
	menu.cycle_hero(-1)
	check_eq(menu.hero, &"bilqis", "Q cycles back to Bilqis")
	Screens.clear()
	GameState.reset()


func test_b_twice_closes_and_restores_focus() -> void:
	GameState.start_new()
	var btn := Button.new()
	tree.root.add_child(btn)
	btn.grab_focus()
	var menu: EquipmentMenu = Screens.open(&"equipment") as EquipmentMenu
	menu._on_slot_activated(&"blade")
	check_eq(int(menu.mode), int(EquipmentMenu.Mode.LIST), "in list mode")
	menu.on_back()
	check(Screens.is_open(), "first B returns to slot boxes")
	check_eq(int(menu.mode), int(EquipmentMenu.Mode.SLOTS), "in slots mode")
	menu.on_back()
	check(not Screens.is_open(), "second B closes the screen")
	btn.free()
	Screens.clear()
	GameState.reset()


func test_header_and_inventory_rects_do_not_intersect() -> void:
	var menu: EquipmentMenu = _open_menu()
	var header_rect := Rect2(menu.header.position, menu.header.size)
	var inv_rect := Rect2(menu.owned_list.position, menu.owned_list.size)
	check(not header_rect.intersects(inv_rect), "header card rect and INVENTORY rect do not intersect")
	check(menu.owned_list.position.y >= header_rect.end.y + 16.0, "INVENTORY starts below header with >= 16px gap")
	var face: Control = menu.header.portrait_face()
	check(face != null, "portrait exists")
	check(face is TextureRect, "portrait is TextureRect")
	var face_tr := face as TextureRect
	check_eq(face_tr.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "portrait keeps image aspect")
	Screens.clear()
	GameState.reset()


func test_hovering_slot_fills_list_without_confirm() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"zayd")
	check_eq(menu.active_slot, &"blade", "starts on blade")
	var hilt_box: SlotBox = menu.boxes_manager.boxes[&"hilt"]
	hilt_box.grab_focus()
	check_eq(menu.active_slot, &"hilt", "focusing hilt slot updates active_slot")
	check_eq(int(menu.mode), int(EquipmentMenu.Mode.SLOTS), "remains in SLOTS mode without confirm")
	var rows: Array[ListRow] = menu.owned_list.rows()
	check(rows.size() > 0, "owned list filled without pressing confirm")
	check(rows[0].name_text().contains("Hilt"), "list populated with hilts")
	Screens.clear()
	GameState.reset()


func test_gemstones_slot_can_take_focus_and_lists_gemstones() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"zayd")
	var gem_box: SlotBox = menu.boxes_manager.boxes[&"gemstones"]
	check(gem_box.focus_mode != Control.FOCUS_NONE, "gemstones box can take focus")
	gem_box.grab_focus()
	check(gem_box.has_focus(), "gemstones has focus")
	check_eq(menu.active_slot, &"gemstones", "gemstones slot active on focus")
	var rows: Array[ListRow] = menu.owned_list.rows()
	check(rows.size() > 0, "gemstones listed in owned list")
	var has_aqiq: bool = false
	for r: ListRow in rows:
		if r.name_text() == Ui.text("STONE_AQIQ_RED_NAME"):
			has_aqiq = true
			break
	check(has_aqiq, "owned aqiq_red gemstone listed")
	Screens.clear()
	GameState.reset()


func test_no_two_connector_lines_intersect() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"zayd")
	menu.stage._process(0.01)
	var lines_dict: Dictionary[StringName, Line2D] = menu.stage.lines()
	var visible_lines: Array[Line2D] = []
	for p: StringName in lines_dict:
		var l: Line2D = lines_dict[p]
		if l.visible and l.points.size() >= 2:
			visible_lines.append(l)
	check(visible_lines.size() >= 2, "at least 2 visible connector lines")
	var intersected: bool = false
	for i: int in visible_lines.size():
		for j: int in range(i + 1, visible_lines.size()):
			var l1: Line2D = visible_lines[i]
			var l2: Line2D = visible_lines[j]
			if _segments_intersect(l1.points[0], l1.points[1], l2.points[0], l2.points[1]):
				intersected = true
				break
	check(not intersected, "no two connector lines intersect")
	Screens.clear()
	GameState.reset()


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


func check_approx(val: float, target: float, tolerance: float, msg: String) -> void:
	check(absf(val - target) <= tolerance, "%s: expected %f got %f" % [msg, target, val])


func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var d1: float = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
	var d2: float = (b.x - a.x) * (d.y - a.y) - (b.y - a.y) * (d.x - a.x)
	var d3: float = (d.x - c.x) * (a.y - c.y) - (d.y - c.y) * (a.x - c.x)
	var d4: float = (d.x - c.x) * (b.y - c.y) - (d.y - c.y) * (b.x - c.x)
	return ((d1 > 0.0 and d2 < 0.0) or (d1 < 0.0 and d2 > 0.0)) and ((d3 > 0.0 and d4 < 0.0) or (d3 < 0.0 and d4 > 0.0))
