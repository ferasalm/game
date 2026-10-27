extends TestCase
## purpose: Tests EquipmentMenu layout, 2D hologram stage, slot boxes, equipping, preview and focus.

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


func test_equipping_writes_game_state_equipment() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"rydan")
	menu._on_slot_activated(&"hilt")
	var swift: EquipDef = ContentDB.get_def("hilt", &"swift_hilt") as EquipDef
	menu._on_item_pressed(swift)
	check_eq(GameState.equipment[&"rydan.hilt"], &"swift_hilt", "A on an item writes GameState.equipment")
	Screens.clear()
	GameState.reset()


func test_unowned_items_never_list() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"rydan")
	menu._on_slot_activated(&"hilt")
	for row: ListRow in menu.owned_list.rows():
		check(row.name_text() != Ui.text("HILT_ANVIL_HILT"), "unowned anvil_hilt never lists")
	Screens.clear()
	GameState.reset()


func test_qe_cycles_heroes() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"rydan")
	menu.cycle_hero(1)
	check_eq(menu.hero, &"bilqis", "E cycles to Bilqis")
	menu.cycle_hero(1)
	check_eq(menu.hero, &"rydan", "E cycles back to Rydan")
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


func test_hologram_is_a_neon_sprite() -> void:
	var menu: EquipmentMenu = _open_menu()
	var stage: HologramStage = menu.stage
	stage.set_hero(&"rydan")
	var neon: Texture2D = stage.sprite_texture()
	check(neon is AtlasTexture, "rydan shows a Neon sprite frame")
	if neon is AtlasTexture:
		var atlas := neon as AtlasTexture
		check_eq(atlas.atlas, load("res://assets/sprites/neon/rydan_idle.png"), "the atlas is rydan's idle sheet")
		check_eq(atlas.region.position, Vector2(0.0, 6.0 * 194.0), "row 6 (toward camera), frame 0")
		check_eq(atlas.region.size, Vector2(108.0, 194.0), "one idle frame")
	stage.set_hero(&"bilqis")
	var portrait: Texture2D = stage.sprite_texture()
	check(portrait != null, "a hero without a Neon set shows a portrait")
	check(not (portrait is AtlasTexture), "the portrait is not a sprite sheet frame")
	check(NodeScan.of_type(stage, &"SubViewport").is_empty(), "the stage has no SubViewport")
	check(NodeScan.of_type(stage, &"Node3D").is_empty(), "the stage has no 3D node")
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
	check(face_tr.texture != null, "portrait texture assigned")
	LayoutSettle.run(menu)
	var frame: Control = menu.header.face_box()
	check(frame != null, "portrait frame exists")
	var inner: Rect2 = _inner_rect(frame)
	var port_rect: Rect2 = face_tr.get_global_rect()
	check_approx(port_rect.position.x, inner.position.x, 2.0, "portrait left fills the frame")
	check_approx(port_rect.position.y, inner.position.y, 2.0, "portrait top fills the frame")
	check_approx(port_rect.size.x, inner.size.x, 2.0, "portrait width fills the frame")
	check_approx(port_rect.size.y, inner.size.y, 2.0, "portrait height fills the frame")
	var drawn: Vector2 = _drawn_size(face_tr.texture, inner.size)
	check(drawn.x >= inner.size.x - 2.0 and drawn.y >= inner.size.y - 2.0, "the texture covers the frame (no empty band)")
	Screens.clear()
	GameState.reset()


func _inner_rect(frame: Control) -> Rect2:
	var box: StyleBox = frame.get_theme_stylebox("panel")
	var frame_rect: Rect2 = frame.get_global_rect()
	var left: float = box.get_margin(SIDE_LEFT)
	var top: float = box.get_margin(SIDE_TOP)
	var right: float = box.get_margin(SIDE_RIGHT)
	var bottom: float = box.get_margin(SIDE_BOTTOM)
	return Rect2(frame_rect.position + Vector2(left, top), frame_rect.size - Vector2(left + right, top + bottom))


func _drawn_size(texture: Texture2D, into: Vector2) -> Vector2:
	var tex_size: Vector2 = texture.get_size()
	return tex_size * maxf(into.x / tex_size.x, into.y / tex_size.y)


func check_approx(val: float, target: float, tolerance: float, msg: String) -> void:
	check(absf(val - target) <= tolerance, "%s: expected %f got %f" % [msg, target, val])


func test_hovering_slot_fills_list_without_confirm() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"rydan")
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
	menu.show_hero(&"rydan")
	var gem_box: SlotBox = menu.boxes_manager.boxes[&"gemstones"]
	check(gem_box.focus_mode != Control.FOCUS_NONE, "gemstones box can take focus")
	gem_box.grab_focus()
	check(gem_box.has_focus(), "gemstones has focus")
	check_eq(menu.active_slot, &"gemstones", "gemstones slot active on focus")
	check(menu.owned_list.rows().size() > 0, "gemstones listed in owned list")
	var has_aqiq: bool = false
	for r: ListRow in menu.owned_list.rows():
		if r.name_text() == Ui.text("STONE_AQIQ_RED_NAME"):
			has_aqiq = true
			break
	check(has_aqiq, "owned aqiq_red gemstone listed")
	Screens.clear()
	GameState.reset()


func test_slot_hover_does_not_steal_focus_in_list_mode() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"rydan")
	menu._on_slot_activated(&"blade")
	check_eq(int(menu.mode), int(EquipmentMenu.Mode.LIST), "in list mode")
	var rows: Array[ListRow] = menu.owned_list.rows()
	check(rows.size() > 0 and rows[0].has_focus(), "first list row has focus")
	var hilt_box: SlotBox = menu.boxes_manager.boxes[&"hilt"]
	hilt_box._on_mouse_entered()
	check(not hilt_box.has_focus(), "hover did not steal focus in list mode")
	check(rows[0].has_focus(), "list row kept focus")
	Screens.clear()
	GameState.reset()
