extends TestCase
## purpose: Tests equipment polish features: hologram override, slot box name/dim ring, stats header, hero header Lv 1.

const OWNED: Array[StringName] = [
	&"grandfather_hilt", &"swift_hilt", &"rustwire_blade", &"keen_blade", &"salvage_arm", &"arc_arm",
	&"wrist_rig", &"lens_array", &"courier_jacket", &"rig_shawl", &"aqiq_red",
]


func _open_menu() -> EquipmentMenu:
	GameState.start_new()
	Inventory.add_all(GameState.inventory, OWNED)
	var menu: EquipmentMenu = Screens.open(&"equipment") as EquipmentMenu
	return menu


func test_hologram_stage_mesh_instances_have_override() -> void:
	var menu: EquipmentMenu = _open_menu()
	var stage: HologramStage = menu.stage
	var meshes: Array[MeshInstance3D] = stage.model_meshes()
	check(not meshes.is_empty(), "model has mesh instances")
	var holo_mat: ShaderMaterial = stage.hologram_material()
	check(holo_mat != null, "hologram material exists")
	for mi: MeshInstance3D in meshes:
		check_eq(mi.material_override, holo_mat, "%s has hologram material_override" % mi.name)
	Screens.clear()
	GameState.reset()


func test_worn_blade_box_shows_name() -> void:
	var menu: EquipmentMenu = _open_menu()
	var blade_box: SlotBox = menu.boxes_manager.boxes[&"blade"]
	check(blade_box != null, "blade box exists")
	var rustwire: EquipDef = ContentDB.get_def("blade", &"rustwire_blade") as EquipDef
	var expected_name: String = Ui.text(rustwire.name_key)
	check_eq(blade_box.item_name(), expected_name, "worn blade's box shows its name")
	Screens.clear()
	GameState.reset()


func test_empty_slot_shows_dim_ring() -> void:
	var menu: EquipmentMenu = _open_menu()
	GameState.equipment[&"zayd.armor"] = &""
	menu.boxes_manager.refresh(menu.hero)
	var armor_box: SlotBox = menu.boxes_manager.boxes[&"armor"]
	check(armor_box != null, "armor box exists")
	check(armor_box.has_dim_ring(), "empty armor slot shows the dim ring")
	check_eq(armor_box.item_name(), "", "empty slot has empty name text")
	check(armor_box.icon_texture() != null, "dim ring texture is assigned")
	Screens.clear()
	GameState.reset()


func test_stats_header_has_now_and_after() -> void:
	var menu: EquipmentMenu = _open_menu()
	var now_lbl: Label = menu.stats.header_now()
	var after_lbl: Label = menu.stats.header_after()
	check(now_lbl != null, "stats header has Now node")
	check_eq(now_lbl.text, "Now", "stats header shows Now")
	check(after_lbl != null, "stats header has After node")
	check_eq(after_lbl.text, "After", "stats header shows After")
	Screens.clear()
	GameState.reset()


func test_hero_header_shows_lv_1_on_fresh_game() -> void:
	var menu: EquipmentMenu = _open_menu()
	check(menu.header.lv_label() != null, "hero header has lv label")
	check_eq(menu.header.lv_text(), "Lv 1", "hero header shows 'Lv 1' on a fresh game")
	check(menu.header.portrait_face() != null, "hero header has portrait face")
	Screens.clear()
	GameState.reset()


func test_stats_preview_shows_arrow_indicators() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"zayd")
	menu._on_slot_activated(&"blade")
	var keen: EquipDef = ContentDB.get_def("blade", &"keen_blade") as EquipDef
	menu._on_item_focused(keen)
	var atk_after_lbl: Label = menu.stats._after_labels["ATK"]
	check(atk_after_lbl != null, "ATK after label exists")
	check(atk_after_lbl.text.contains("▲"), "improved ATK has up arrow")
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
