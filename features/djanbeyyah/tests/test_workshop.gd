extends TestCase
## The loadout fallback, saved equipment, and the workshop menu: it builds headless with every hilt and blade but
## shows only owned ones, selecting anvil + broad and confirming saves "zayd.hilt" / "zayd.blade" and closes
## once, back changes nothing, the panel shows merged numbers.


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


func _own_everything() -> void:
	for kind: String in ["hilt", "blade"]:
		for item_id: StringName in ContentDB.ids(kind):
			Inventory.add(GameState.inventory, item_id)


func _shown(menu: WorkshopMenu) -> Array[StringName]:
	var out: Array[StringName] = []
	for choice: WorkshopChoice in menu.choice_buttons():
		if choice.visible:
			out.append(choice.item_id)
	return out


func test_start_loadout_is_the_grandfather_hilt_and_a_rustwire_blade() -> void:
	check_eq(_start().hilt, &"grandfather_hilt", "start hilt")
	check_eq(_start().blade, &"rustwire_blade", "start blade")
	check_eq(_start().prosthetic, &"salvage_arm", "start prosthetic")


func test_loadout_falls_back_per_slot() -> void:
	var none: Dictionary[StringName, StringName] = {}
	var start: Array[StringName] = [&"grandfather_hilt", &"rustwire_blade"]
	check_eq(Loadout.current(none, _start()), start, "empty: start pair")
	var blade_only: Dictionary[StringName, StringName] = {&"zayd.blade": &"broad_blade"}
	check_eq(Loadout.current(blade_only, _start()), [&"grandfather_hilt", &"broad_blade"] as Array[StringName], "missing hilt")
	var blank: Dictionary[StringName, StringName] = {&"zayd.hilt": &"", &"zayd.blade": &"broad_blade"}
	check_eq(Loadout.current(blank, _start()), [&"grandfather_hilt", &"broad_blade"] as Array[StringName], "empty hilt")
	var both: Dictionary[StringName, StringName] = {&"zayd.hilt": &"anvil_hilt", &"zayd.blade": &"broad_blade"}
	check_eq(Loadout.current(both, _start()), [&"anvil_hilt", &"broad_blade"] as Array[StringName], "saved pair")


func test_menu_builds_with_every_hilt_and_blade() -> void:
	var menu: WorkshopMenu = _menu()
	check(not menu.is_open(), "closed until open()")
	check_eq(menu.choice_buttons().size(), 6, "3 hilts + 3 blades exist")
	menu.open()
	check(menu.is_open(), "open")
	check_eq(menu.shown_pair(), [&"grandfather_hilt", &"rustwire_blade"] as Array[StringName], "starts on the worn pair")
	menu.free()


func test_only_owned_items_are_shown() -> void:
	var menu: WorkshopMenu = _menu()
	menu.open()
	check_eq(_shown(menu), [&"grandfather_hilt", &"rustwire_blade"] as Array[StringName], "no inventory: only what is worn")
	menu.cancel()
	Inventory.add_all(GameState.inventory, [&"swift_hilt", &"keen_blade", &"arc_arm"] as Array[StringName])
	menu.open()
	check_eq(_shown(menu), [&"grandfather_hilt", &"swift_hilt", &"rustwire_blade", &"keen_blade"] as Array[StringName],
		"owned hilts and blades appear; a prosthetic never does")
	menu.free()
	GameState.reset()


func test_anchor_and_broad_confirm_saves_and_closes_once() -> void:
	var menu: WorkshopMenu = _menu()
	var count: Array[int] = _closes(menu)
	_own_everything()
	menu.open()
	menu.select_hilt(&"anvil_hilt")
	menu.select_blade(&"broad_blade")
	check(GameState.equipment.is_empty(), "nothing saved before Confirm")
	menu.confirm()
	menu.confirm()
	check_eq(GameState.equipment[&"zayd.hilt"], &"anvil_hilt", "hilt saved")
	check_eq(GameState.equipment[&"zayd.blade"], &"broad_blade", "blade saved")
	check_eq(count[0], 1, "closed emitted once")
	check(not menu.is_open(), "closed")
	menu.free()
	GameState.reset()


func test_back_action_changes_nothing() -> void:
	var menu: WorkshopMenu = _menu()
	var count: Array[int] = _closes(menu)
	_own_everything()
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
	GameState.equipment[&"zayd.hilt"] = &"anvil_hilt"
	menu.open()
	check_eq(menu.shown_pair(), [&"anvil_hilt", &"rustwire_blade"] as Array[StringName], "saved hilt, start blade")
	menu.free()
	GameState.reset()


func test_panel_shows_the_merged_numbers() -> void:
	var menu: WorkshopMenu = _menu()
	_own_everything()
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
