extends TestCase
## purpose: The pause menu rules (PauseLogic) and the screen built from them.


func test_entries_follow_registered_screens_and_saves() -> void:
	var full: Array[StringName] = PauseLogic.entries(true, true, true)
	check_eq(full, [&"resume", &"items", &"equipment", &"load", &"unstuck", &"title", &"quit"] as Array[StringName], "full")
	var bare: Array[StringName] = PauseLogic.entries(false, false, false)
	check_eq(bare, [&"resume", &"restart", &"unstuck", &"title", &"quit"] as Array[StringName], "no items, no save: Restart")


func test_destructive_entries_ask_first() -> void:
	for id: StringName in [&"load", &"load_last", &"restart", &"unstuck", &"title", &"quit"]:
		check(not PauseLogic.confirm_key(id).is_empty(), "%s asks first" % id)
	for id: StringName in [&"resume", &"items", &"equipment"]:
		check(PauseLogic.confirm_key(id).is_empty(), "%s acts at once" % id)


func test_every_text_key_exists() -> void:
	for id: StringName in PauseLogic.ENTRIES:
		check(Ui.text(PauseLogic.label_key(id)) != PauseLogic.label_key(id), "text for " + id)
		var question: String = PauseLogic.confirm_key(id)
		check(question.is_empty() or Ui.text(question) != question, "question text for " + id)


func test_missing_vitals_mean_full() -> void:
	check_eq(PauseLogic.vitals_of(null, &"zayd", 120, 30), Vector2i(120, 30), "no record at all")
	check_eq(PauseLogic.vitals_of({}, &"zayd", 120, 30), Vector2i(120, 30), "no hero record")
	check_eq(PauseLogic.vitals_of({"zayd": {"hp": 0, "sp": 5}}, &"zayd", 120, 30), Vector2i(0, 5), "hp 0 is kept")
	check_eq(PauseLogic.vitals_of({&"zayd": {"hp": 999, "sp": -4}}, &"zayd", 120, 30), Vector2i(120, 0), "clamped")


func test_clock_and_money() -> void:
	check_eq(PauseLogic.clock(5047), "01:24:07", "1h 24m 7s")
	check_eq(PauseLogic.clock(null), "00:00:00", "missing time")
	check_eq(PauseLogic.clock(-9), "00:00:00", "negative time")
	check_eq(PauseLogic.money_of(null), 0, "missing money")
	check_eq(PauseLogic.money_of(1240), 1240, "money")


func test_pause_screen_builds_and_resume_closes() -> void:
	Router.state = Router.STATE_EXPLORING
	Screens.open(&"pause")
	var menu: PauseMenu = Screens.top() as PauseMenu
	check(menu != null, "pause opens")
	if menu == null:
		return
	check(menu.button_of(&"resume").has_focus(), "Resume has focus")
	check(menu.button_of(&"equipment") != null, "Equipment shows (registered)")
	check(menu.button_of(&"items") != null, "Items shows (registered)")
	check(menu.button_of(&"restart") != null or menu.button_of(&"load") != null, "load or restart")
	menu.button_of(&"resume").pressed.emit()
	check(not Screens.is_open() and not tree.paused, "Resume closes and unpauses")
	Router.state = Router.STATE_TITLE


func test_equipment_opens_the_menu() -> void:
	Screens.open(&"equipment")
	var menu: EquipmentMenu = Screens.top() as EquipmentMenu
	check(menu != null, "the equipment menu opens")
	if menu != null:
		menu.on_back()
		check(not Screens.is_open(), "back closes the menu")
	Screens.clear()
	tree.paused = false


func test_pause_party_portraits_fill_frame_and_bars_aligned_in_column() -> void:
	Router.state = Router.STATE_EXPLORING
	Screens.open(&"pause")
	var menu: PauseMenu = Screens.top() as PauseMenu
	check(menu != null, "pause opens")
	var rows: Array[PauseHeroRow] = menu.party().rows()
	check(rows.size() >= 2, "at least 2 hero rows in pause party")
	var first_hp_w: float = -1.0
	for row: PauseHeroRow in rows:
		var face: TextureRect = row.face_rect()
		check(face != null, "face exists")
		check_eq(face.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "face keeps aspect ratio")
		check_eq(face.custom_minimum_size, Vector2(160, 160), "face frame is 160x160")
		var hp: ProgressBar = row.hp_bar()
		check(hp != null, "hp bar exists")
		check_eq(hp.custom_minimum_size, Vector2(420, 14), "hp bar size is 420x14")
		var sp: ProgressBar = row.sp_bar()
		check(sp != null, "sp bar exists")
		check_eq(sp.custom_minimum_size, Vector2(420, 14), "sp bar size is 420x14")
		if first_hp_w < 0.0:
			first_hp_w = hp.custom_minimum_size.x
		else:
			check_eq(hp.custom_minimum_size.x, first_hp_w, "bars aligned on one column")
	Screens.clear()
	tree.paused = false
	Router.state = Router.STATE_TITLE
