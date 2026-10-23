extends TestCase
## Menu polish tests: portrait faces, pause hero progression, icon disc fallback, label font sizes, glass panel colour.


func test_portrait_faces_texture_and_fallback() -> void:
	var zayd_tex: Texture2D = PortraitFaces.texture(&"zayd")
	check(zayd_tex != null, "portrait_faces returns texture for zayd")
	var bilqis_tex: Texture2D = PortraitFaces.texture(&"bilqis")
	check(bilqis_tex != null, "portrait_faces returns texture for bilqis")
	var fallback_tex: Texture2D = PortraitFaces.texture(&"unknown_hero")
	check_eq(fallback_tex, CharacterIcons.texture(&"unknown_hero"), "portrait_faces falls back for unknown id")


func test_pause_row_shows_level_and_class_name() -> void:
	GameState.xp.clear()
	var row := PauseHeroRow.new().setup(&"zayd")
	check(row.lv_node() != null, "row has lv node")
	check(row.lv_node() is Label and (row.lv_node() as Label).text.begins_with("Lv 1"), "fresh game shows Lv 1")
	var cdef := ContentDB.get_def("class", &"courier") as ClassDef
	var class_name_str: String = Ui.text(cdef.name_key) if cdef != null else ""
	check(row.class_label() != null, "row has class label")
	check(row.class_label().text.contains(class_name_str), "fresh game shows class name Courier")

	GameState.xp[&"zayd"] = 60
	row.update(100, 50)
	check((row.lv_node() as Label).text.begins_with("Lv 2"), "after 60 xp shows Lv 2")
	row.free()
	GameState.xp.clear()


func test_disc_fallback_when_icon_file_missing() -> void:
	var missing := ConsumableDef.new()
	missing.id = &"missing_item"
	missing.icon = &"non_existent_icon_file"
	missing.name_key = "ITEM_HEALING_SALVE"

	var tr := TextureRect.new()
	ItemIcons.apply(tr, missing, 96)
	check(tr.texture != null, "texture is created for missing icon")
	var label_found: bool = false
	for child: Node in tr.get_children():
		if child is Label and child.name == &"InitialLabel":
			label_found = true
			var initial_str: String = (child as Label).text
			check_eq(initial_str, ItemIcons.initial(missing), "disc shows item initial")
	check(label_found, "disc fallback adds initial label")
	tr.free()


func test_no_label_on_pause_save_shop_smaller_than_s_font_small() -> void:
	Ui.clear_cache()
	var min_size: int = Ui.style().size(&"s_font_small")

	var pause := PauseMenu.new()
	tree.root.add_child(pause)
	pause.open()
	_assert_all_labels_at_least(pause, min_size, "pause")
	pause.queue_free()

	var save := SlotPickerScreen.new()
	tree.root.add_child(save)
	save.open({"mode": SlotPickerScreen.MODE_SAVE})
	_assert_all_labels_at_least(save, min_size, "save")
	save.queue_free()

	var shop := ShopScreen.new()
	tree.root.add_child(shop)
	shop.open({"shop": &"herb_stall"})
	_assert_all_labels_at_least(shop, min_size, "shop")
	shop.queue_free()


func test_panel_colour_is_c_glass_menu() -> void:
	var style: UiStyleDef = Ui.style()
	check(style.colours.has(&"c_glass_menu"), "c_glass_menu is registered in UiStyleDef")
	var expected: Color = Color("#161230b8")
	check_eq(style.colour(&"c_glass_menu"), expected, "c_glass_menu colour is #161230b8")


func _assert_all_labels_at_least(root: Node, min_size: int, screen_name: String) -> void:
	for node: Node in NodeWalk.all(root):
		if node is Label:
			var lbl := node as Label
			var sz: int = lbl.get_theme_font_size(&"font_size")
			check(sz >= min_size, "%s label '%s' font size %d < %d" % [screen_name, lbl.name, sz, min_size])
