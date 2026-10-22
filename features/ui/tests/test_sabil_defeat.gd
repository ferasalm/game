extends TestCase
## The Sabil question and the Defeat screen: registered ids, focus order, results, back handling.


func _action(name: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	return event


func _finish() -> void:
	Screens.clear()
	tree.paused = false


func _results_of(screen: UiScreen) -> Array[Variant]:
	var out: Array[Variant] = []
	screen.closed.connect(func(result: Variant) -> void: out.append(result))
	return out


func test_sabil_is_registered_and_drink_has_focus() -> void:
	check(Screens.has_screen(&"sabil") and Screens.has_screen(&"defeat"), "both registered")
	var screen := Screens.open(&"sabil") as SabilScreen
	check(screen != null and Screens.is_open_id(&"sabil"), "opened by id, returned")
	if screen == null:
		return
	check_eq(screen.results(), [&"drink", &"leave"] as Array[StringName], "focus order: drink, not now")
	check(screen.choices()[0].has_focus(), "Drink is the default")
	check(tree.paused, "the world waits")
	_finish()


func test_sabil_results_drink_and_leave() -> void:
	var screen := Screens.open(&"sabil") as SabilScreen
	var got: Array[Variant] = _results_of(screen)
	screen.choices()[0].pressed.emit()
	check_eq(got, [&"drink"] as Array[Variant], "Drink closes with drink")
	check(not Screens.is_open(), "closed")
	var again := Screens.open(&"sabil") as SabilScreen
	var second: Array[Variant] = _results_of(again)
	Screens._unhandled_input(_action(&"back"))
	check_eq(second, [&"leave"] as Array[Variant], "back means leave")
	_finish()


func test_defeat_offers_retry_load_title_and_ignores_back() -> void:
	var screen := Screens.open(&"defeat") as DefeatScreen
	check(screen != null, "defeat opens")
	if screen == null:
		return
	check_eq(screen.results(), [&"retry", &"load", &"title"] as Array[StringName], "focus order")
	check(screen.choices()[0].has_focus(), "Retry is the default")
	check_eq(screen.choices()[1].disabled, not Router.has_save(1), "Load is greyed exactly when there is no save")
	Screens._unhandled_input(_action(&"back"))
	check(Screens.is_open_id(&"defeat"), "back does not close the defeat screen")
	var got: Array[Variant] = _results_of(screen)
	screen.choices()[0].pressed.emit()
	check_eq(got, [&"retry"] as Array[Variant], "retry result")
	_finish()


func test_defeat_title_asks_first() -> void:
	var screen := Screens.open(&"defeat") as DefeatScreen
	var got: Array[Variant] = _results_of(screen)
	screen.choices()[2].pressed.emit()
	var dialog := Screens.top() as ConfirmDialog
	check(dialog != null, "a ConfirmDialog opens over it")
	if dialog == null:
		_finish()
		return
	dialog.answer(false)
	check(got.is_empty() and Screens.is_open_id(&"defeat"), "No keeps the defeat screen")
	screen.choices()[2].pressed.emit()
	(Screens.top() as ConfirmDialog).answer(true)
	check_eq(got, [&"title"] as Array[Variant], "Yes closes with title")
	_finish()


func test_defeat_and_sabil_text_exists() -> void:
	for key: String in ["SABIL_TITLE", "SABIL_TITLE_MUSNAD", "SABIL_ASK", "SABIL_DRINK", "SABIL_NOT_NOW", "SABIL_SAVED",
			"SABIL_PATROLS", "SABIL_FAIL", "SABIL_PROMPT", "PROMPT_TALK", "PROMPT_OPEN", "DEFEAT_TITLE", "DEFEAT_TITLE_MUSNAD",
			"DEFEAT_RETRY", "DEFEAT_LOAD", "DEFEAT_TITLE_MENU", "MONEY_GLYPH"]:
		check(Ui.text(key) != key, "text for " + key)


func test_screens_toast_goes_to_one_host() -> void:
	Ui.toast("SABIL_SAVED", &"good")
	Ui.toast("SABIL_PATROLS")
	var hosts: int = 0
	for child: Node in Screens.get_children():
		if child is ToastHost:
			hosts += 1
			check((child as ToastHost).pending() >= 1, "a toast waits behind the first")
			check_eq((child as ToastHost).layer, UiLayers.TOAST, "toast layer")
	check_eq(hosts, 1, "one shared host")
