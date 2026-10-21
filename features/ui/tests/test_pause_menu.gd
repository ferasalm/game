extends TestCase
## The pause menu rules (PauseLogic) and the screen built from them.


func test_entries_follow_registered_screens_and_saves() -> void:
	var full: Array[StringName] = PauseLogic.entries(true, true, true)
	check_eq(full, [&"resume", &"items", &"equipment", &"load_last", &"unstuck", &"title", &"quit"] as Array[StringName], "full")
	var bare: Array[StringName] = PauseLogic.entries(false, false, false)
	check_eq(bare, [&"resume", &"restart", &"unstuck", &"title", &"quit"] as Array[StringName], "no items, no save: Restart")


func test_destructive_entries_ask_first() -> void:
	for id: StringName in [&"load_last", &"restart", &"unstuck", &"title", &"quit"]:
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
	check(menu.button_of(&"restart") != null or menu.button_of(&"load_last") != null, "load or restart")
	menu.button_of(&"resume").pressed.emit()
	check(not Screens.is_open() and not tree.paused, "Resume closes and unpauses")
	Router.state = Router.STATE_TITLE


func test_equipment_host_opens_the_bench() -> void:
	Screens.open(&"equipment")
	var host: EquipmentHost = Screens.top() as EquipmentHost
	check(host != null and host.bench().is_open(), "the bench is open inside the host")
	if host != null:
		host.on_back()
		check(not Screens.is_open(), "back closes the bench and the host")
	Screens.clear()
	tree.paused = false
