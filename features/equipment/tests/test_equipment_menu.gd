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


func test_preview_after_value_equals_gear_build_hero() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"zayd")
	menu._on_slot_activated(&"blade")
	var keen: EquipDef = ContentDB.get_def("blade", &"keen_blade") as EquipDef
	menu._on_item_focused(keen)
	var loader := BattleLoader.from_db(ContentDB)
	var staged := EquipmentStatsPanel.StagedState.new()
	staged.xp = GameState.xp
	staged.equipment = GameState.equipment.duplicate()
	staged.equipment[&"zayd.blade"] = &"keen_blade"
	staged.sockets = GameState.sockets
	staged.upgrades = GameState.upgrades
	var expected: CombatantDef = loader.hero_from_state(&"zayd", staged)
	var after_val: CombatantDef = menu.stats.last_after()
	check_eq(after_val.attack, expected.attack, "after-value equals Gear.build_hero with swap")
	Screens.clear()
	GameState.reset()


func test_sockets_show_stones_and_hide_locked() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"zayd")
	var g_box: SlotBox = menu.boxes_manager.boxes[&"gemstones"]
	check(g_box != null, "gemstones box exists")
	check(g_box._socket_panels[0].visible, "socket 0 visible")
	check(not g_box._socket_panels[1].visible, "socket 1 hidden when locked")
	GameState.flags[&"heirloom_rank_3"] = true
	menu.boxes_manager.refresh(menu.hero)
	check(g_box._socket_panels[1].visible, "socket 1 visible when unlocked")
	check(g_box._socket_panels[2].visible, "socket 2 visible when unlocked")
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


func test_subviewport_and_character_visual_turns_while_paused() -> void:
	var menu: EquipmentMenu = _open_menu()
	var stage: HologramStage = menu.stage
	check(stage.sub_viewport() != null, "SubViewport exists")
	var visual: CharacterVisual = stage.visual()
	check(visual != null and stage.sub_viewport().get_children().has(visual), "visual is SubViewport child")
	tree.paused = true
	var r0: float = visual.rotation.y
	stage._process(0.5)
	var r1: float = visual.rotation.y
	check(r1 > r0, "visual keeps turning 20 deg/s while paused")
	tree.paused = false
	Screens.clear()
	GameState.reset()


func test_rects_match_spec_within_2px() -> void:
	var menu: EquipmentMenu = _open_menu()
	check_approx(menu.tabs.position.x, 80.0, 2.0, "tabs x")
	check_approx(menu.tabs.position.y, 40.0, 2.0, "tabs y")
	check_approx(menu.header.position.x, 80.0, 2.0, "header x")
	check_approx(menu.header.position.y, 124.0, 2.0, "header y")
	check_approx(menu.owned_list.position.x, 80.0, 2.0, "list x")
	check_approx(menu.owned_list.position.y, 240.0, 2.0, "list y")
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
