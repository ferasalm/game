extends TestCase
## The loadout fallback, saved equipment, and the workshop menu: it builds headless with 2 + 2 choices, selecting
## anchor + broad and confirming saves them and closes once, back changes nothing, the panel shows merged numbers.


func _start() -> LoadoutDef:
	return ContentDB.get_def("loadout", &"zayd_start") as LoadoutDef


func _menu() -> WorkshopMenu:
	GameState.reset()
	var menu := WorkshopMenu.new()
	tree.root.add_child(menu)
	return menu


func _closes(menu: WorkshopMenu) -> Array[int]:
	var count: Array[int] = [0]
	menu.closed.connect(func() -> void: count[0] += 1)
	return count


func _merged(hilt_id: StringName, blade_id: StringName) -> CombatantDef:
	return Djanbeyyah.equip(ContentDB.get_def("combatant", &"zayd") as CombatantDef,
		ContentDB.get_def("hilt", hilt_id) as HiltDef, ContentDB.get_def("blade", blade_id) as BladeDef)


func test_start_loadout_is_swift_and_keen() -> void:
	check_eq(_start().hilt, &"swift_hilt", "start hilt")
	check_eq(_start().blade, &"keen_blade", "start blade")


func test_loadout_falls_back_per_slot() -> void:
	var none: Dictionary[StringName, StringName] = {}
	check_eq(Loadout.current(none, _start()), [&"swift_hilt", &"keen_blade"] as Array[StringName], "empty: start pair")
	var blade_only: Dictionary[StringName, StringName] = {&"blade": &"broad_blade"}
	check_eq(Loadout.current(blade_only, _start()), [&"swift_hilt", &"broad_blade"] as Array[StringName], "missing hilt")
	var blank: Dictionary[StringName, StringName] = {&"hilt": &"", &"blade": &"broad_blade"}
	check_eq(Loadout.current(blank, _start()), [&"swift_hilt", &"broad_blade"] as Array[StringName], "empty hilt")
	var both: Dictionary[StringName, StringName] = {&"hilt": &"anvil_hilt", &"blade": &"broad_blade"}
	check_eq(Loadout.current(both, _start()), [&"anvil_hilt", &"broad_blade"] as Array[StringName], "saved pair")


func test_menu_builds_with_two_and_two_choices() -> void:
	var menu: WorkshopMenu = _menu()
	check(not menu.is_open(), "closed until open()")
	var choices: Array[WorkshopChoice] = menu.choice_buttons()
	check_eq(choices.size(), 4, "2 hilts + 2 blades")
	menu.open()
	check(menu.is_open(), "open")
	check_eq(menu.shown_pair(), [&"swift_hilt", &"keen_blade"] as Array[StringName], "starts on the worn pair")
	menu.free()


func test_anchor_and_broad_confirm_saves_and_closes_once() -> void:
	var menu: WorkshopMenu = _menu()
	var count: Array[int] = _closes(menu)
	menu.open()
	menu.select_hilt(&"anvil_hilt")
	menu.select_blade(&"broad_blade")
	check(GameState.equipment.is_empty(), "nothing saved before Confirm")
	menu.confirm()
	menu.confirm()
	check_eq(GameState.equipment[&"hilt"], &"anvil_hilt", "hilt saved")
	check_eq(GameState.equipment[&"blade"], &"broad_blade", "blade saved")
	check_eq(count[0], 1, "closed emitted once")
	check(not menu.is_open(), "closed")
	menu.free()
	GameState.reset()


func test_back_action_changes_nothing() -> void:
	var menu: WorkshopMenu = _menu()
	var count: Array[int] = _closes(menu)
	menu.open()
	menu.select_hilt(&"anvil_hilt")
	var back := InputEventAction.new()
	back.action = &"back"
	back.pressed = true
	menu._unhandled_input(back)
	check(GameState.equipment.is_empty(), "equipment unchanged")
	check_eq(count[0], 1, "closed emitted")
	check(not menu.is_open(), "closed")
	menu.free()
	GameState.reset()


func test_reopening_shows_the_saved_pair() -> void:
	var menu: WorkshopMenu = _menu()
	GameState.equipment[&"hilt"] = &"anvil_hilt"
	menu.open()
	check_eq(menu.shown_pair(), [&"anvil_hilt", &"keen_blade"] as Array[StringName], "saved hilt, start blade")
	menu.free()
	GameState.reset()


func test_panel_shows_the_merged_numbers() -> void:
	var menu: WorkshopMenu = _menu()
	menu.open()
	menu.select_hilt(&"anvil_hilt")
	menu.select_blade(&"broad_blade")
	var merged: CombatantDef = _merged(&"anvil_hilt", &"broad_blade")
	var base: CombatantDef = ContentDB.get_def("combatant", &"zayd") as CombatantDef
	var rows: PackedStringArray = menu.stats_panel().texts()
	check_eq(rows.size(), 5, "five stat rows")
	check(rows[0].contains("%d | %d" % [base.agility, merged.agility]), "turn speed: " + rows[0])
	check(rows[1].contains("%d%%" % roundi(merged.cast_speed * 100.0)), "charge speed: " + rows[1])
	check(rows[2].contains("%d | %d" % [base.attack, merged.attack]), "damage: " + rows[2])
	check(rows[3].contains("%d" % merged.knockback_bonus), "stagger: " + rows[3])
	check(rows[4].contains("%.1f" % merged.weight), "weight: " + rows[4])
	check_eq(menu.stats_panel().move_name(), String(TranslationServer.translate("ACTION_CRUSHING_BLOW")), "the anvil hilt's move")
	check(rows[0].ends_with("▼"), "slower turn shows a down arrow")
	check(rows[3].ends_with("▲"), "more stagger shows an up arrow")
	menu.free()
	GameState.reset()
