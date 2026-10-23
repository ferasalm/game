extends TestCase
## Menu skins test: backdrops, fallback, child 0, party rows, thumbnails, shop money-after, rects.

const RECTS: Dictionary = {
	"pause_cmd": [80.0, 80.0, 420.0, 760.0],
	"pause_info": [80.0, 880.0, 420.0, 100.0],
	"pause_party": [540.0, 80.0, 1300.0, 900.0],
	"save_title": [560.0, 60.0, 800.0, 90.0],
	"save_rows": [440.0, 180.0, 900.0, 620.0],
	"save_detail": [1380.0, 180.0, 460.0, 620.0],
	"shop_title": [80.0, 40.0, 1760.0, 80.0],
	"shop_grid": [80.0, 140.0, 720.0, 560.0],
	"shop_keeper": [80.0, 720.0, 620.0, 260.0],
	"shop_detail": [840.0, 140.0, 560.0, 760.0],
	"shop_summary": [1440.0, 140.0, 400.0, 420.0],
	"shop_party": [1440.0, 600.0, 400.0, 300.0]
}


func test_backdrops_load_seven_rows() -> void:
	var list: Array[StringName] = ContentDB.ids("backdrop")
	check_eq(list.size(), 7, "backdrops.json loads 7 rows")
	for id: StringName in [&"pause", &"items", &"equipment", &"workshop", &"shop", &"save", &"map"]:
		var def := ContentDB.get_def("backdrop", id) as BackdropDef
		check(def != null, "backdrop %s exists" % id)
		if def != null:
			check(def.path.ends_with("%s.webp" % id), "correct path for %s" % id)
			check(absf(def.dim - 0.35) < 0.01, "dim is 0.35")


func test_backdrop_fallback_never_bare_world() -> void:
	var bd_headless := MenuBackdrop.new().setup(&"missing_id")
	check(bd_headless.get_child_count() > 0, "headless fallback creates fill")
	check(bd_headless.get_child(0) is ColorRect, "fallback is ColorRect")
	bd_headless.free()

	var fake_frame := Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	var bd_frame := MenuBackdrop.new().setup(&"missing_id", fake_frame)
	check(bd_frame.get_child_count() >= 2, "frame fallback creates blurred texture + scrim")
	check(bd_frame.get_child(0) is TextureRect, "blurred TextureRect")
	check(bd_frame.get_child(1) is ColorRect, "scrim ColorRect")
	bd_frame.free()


func test_backdrop_is_child_0_of_screens() -> void:
	var pause := PauseMenu.new()
	pause.open()
	check(pause.get_child(0) is MenuBackdrop, "backdrop is child 0 of pause")
	pause.free()

	var items := ItemsScreen.new()
	items.open()
	check(items.get_child(0) is MenuBackdrop, "backdrop is child 0 of items")
	items.free()

	var shop := ShopScreen.new()
	shop.open({"shop": &"herb_stall"})
	check(shop.get_child(0) is MenuBackdrop, "backdrop is child 0 of shop")
	shop.free()

	var save := SlotPickerScreen.new()
	save.open({"mode": SlotPickerScreen.MODE_SAVE})
	check(save.get_child(0) is MenuBackdrop, "backdrop is child 0 of save")
	save.free()


func test_pause_party_row_progression_and_ko() -> void:
	var row := PauseHeroRow.new().setup(&"zayd")
	check(row.lv_node() != null and not row.lv_node().visible, "hidden Lv node")
	check(row.xp_bar() != null and not row.xp_bar().visible, "hidden XP node")
	check_eq(row.xp_bar().custom_minimum_size, Vector2(360, 10), "xp bar 360x10")
	check_eq(row.hp_bar().custom_minimum_size, Vector2(420, 14), "hp bar 420x14")
	check_eq(row.sp_bar().custom_minimum_size, Vector2(420, 14), "sp bar 420x14")
	check_eq(row.face_rect().custom_minimum_size, Vector2(160, 160), "face 160x160")

	row.update(0, 0)
	check(row.is_ko(), "KO state when hp <= 0")
	check(row.ko_label() != null and row.ko_label().text == "KO", "KO row says KO")
	row.free()


func test_save_thumbnail_written_and_read() -> void:
	var test_dir := SaveService.test_dir_for("test_menu_skins_thumb")
	var service := SaveService.new(test_dir)
	var thumb_path := service.thumbnail_path_for(1)
	check(thumb_path.ends_with("slot_1.png"), "thumbnail path is slot_1.png beside save")

	var test_img := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	check(service.write_thumbnail(1, test_img), "write thumbnail succeeds")
	check(FileAccess.file_exists(thumb_path), "thumbnail file written on save")

	var tex := service.read_thumbnail(1)
	check(tex != null, "read thumbnail returns texture")

	var slot_row := SlotRow.new().setup(1, true, {"area": "souq_rooftops"}, service, SlotPickerScreen.MODE_SAVE)
	check(slot_row.thumbnail_rect().texture != null, "thumbnail read in row")
	slot_row.free()

	service.delete(1)
	check(not FileAccess.file_exists(thumb_path), "delete removes thumbnail")
	SaveService.empty_dir(test_dir)


func test_shop_money_after_is_bad_when_short() -> void:
	GameState.money = 10
	var shop := ShopScreen.new()
	shop.open({"shop": &"herb_stall"})
	shop.select(&"pink_herb")
	shop.set_quantity(5)
	var summary := shop.summary_panel()
	var col: Color = summary.after_label().get_theme_color("font_color")
	check_eq(col, Ui.style().colour(&"c_bad"), "shop money-after is c_bad when short")
	shop.free()


func test_rects_match_spec_within_2px() -> void:
	var pause := PauseMenu.new()
	pause.open()
	_check_rect(pause.cmd_panel(), RECTS["pause_cmd"], "pause cmd")
	_check_rect(pause.info_box(), RECTS["pause_info"], "pause info")
	_check_rect(pause.party_panel(), RECTS["pause_party"], "pause party")
	pause.free()

	var save := SlotPickerScreen.new()
	save.open({"mode": SlotPickerScreen.MODE_SAVE})
	_check_rect(save.title_panel(), RECTS["save_title"], "save title")
	_check_rect(save.rows_container(), RECTS["save_rows"], "save rows")
	_check_rect(save.detail_panel(), RECTS["save_detail"], "save detail")
	save.free()

	var shop := ShopScreen.new()
	shop.open({"shop": &"herb_stall"})
	_check_rect(shop.title_bar(), RECTS["shop_title"], "shop title")
	_check_rect(shop.grid_panel(), RECTS["shop_grid"], "shop grid")
	_check_rect(shop.keeper_box(), RECTS["shop_keeper"], "shop keeper")
	_check_rect(shop.detail_panel(), RECTS["shop_detail"], "shop detail")
	_check_rect(shop.summary_panel(), RECTS["shop_summary"], "shop summary")
	_check_rect(shop.party_mini(), RECTS["shop_party"], "shop party")
	shop.free()


func _check_rect(c: Control, spec: Array, label: String) -> void:
	check(absf(c.position.x - float(spec[0])) <= 2.0, "%s x" % label)
	check(absf(c.position.y - float(spec[1])) <= 2.0, "%s y" % label)
	check(absf(c.size.x - float(spec[2])) <= 2.0, "%s w" % label)
	check(absf(c.size.y - float(spec[3])) <= 2.0, "%s h" % label)
