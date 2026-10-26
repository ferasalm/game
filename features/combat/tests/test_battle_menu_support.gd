extends TestCase
## The command menu with tech moves: an ally move lists the allies (not the foes), self and all-moves skip the
## target list and commit at once, and the party is built from saved gear.


func _sim(battle_seed: int) -> BattleSim:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var gear: Dictionary[StringName, StringName] = {&"zayd.prosthetic": &"cradle_spine", &"bilqis.prosthetic": &"lens_array"}
	return loader.make_sim_for(loader.party_from_equipment(gear), battle_seed)


func _wait_for_hero(sim: BattleSim) -> UnitState:
	var guard: int = 30000
	while sim.result == &"" and guard > 0 and sim.waiting_hero() == null:
		sim.step()
		guard -= 1
	return sim.waiting_hero()


func _menu_for(sim: BattleSim, hero: UnitState) -> BattleCommandMenu:
	var view := ContentDB.get_def("battle_view", &"default") as BattleViewDef
	var menu := BattleCommandMenu.new()
	tree.root.add_child(menu)
	menu.setup(sim, view)
	menu.chosen.connect(func(action: ActionDef, target_id: StringName) -> void:
		var reason: String = sim.choose(hero.unit_id, action, target_id)
		if reason.is_empty():
			menu.close()
		else:
			menu.show_notice(reason))
	menu.open(hero)
	return menu


func _press(menu: BattleCommandMenu, action_id: StringName) -> void:
	for button: Button in menu.move_buttons():
		if button.get_meta("action_id") == action_id:
			button.pressed.emit()


func _unit_ids(buttons: Array[Button]) -> Array[StringName]:
	var out: Array[StringName] = []
	for button: Button in buttons:
		out.append(button.get_meta("unit_id") as StringName)
	return out


func test_ally_move_lists_allies_and_self_and_all_moves_skip_the_list() -> void:
	var seen: Dictionary[StringName, bool] = {}
	for battle_seed: int in range(1, 12):
		var sim: BattleSim = _sim(battle_seed)
		var hero: UnitState = _wait_for_hero(sim)
		if hero == null:
			continue
		var menu: BattleCommandMenu = _menu_for(sim, hero)
		if hero.def.id == &"zayd" and not seen.has(&"self"):
			seen[&"self"] = true
			_press(menu, &"reactive_guard")
			check_eq(hero.action.id, &"reactive_guard", "a self move commits without a target list")
			check_eq(hero.targets, [&"zayd"] as Array[StringName], "aimed at the caster")
			check(not menu.is_open(), "the menu closed")
		elif hero.def.id == &"bilqis":
			if not seen.has(&"ally"):
				seen[&"ally"] = true
				_press(menu, &"nanite_mend")
				check_eq(_unit_ids(menu.target_buttons()), [&"zayd", &"bilqis"] as Array[StringName], "allies, in timeline order")
				menu.target_buttons()[0].pressed.emit()
				check_eq(hero.targets, [&"zayd"] as Array[StringName], "healing Zayd")
			elif not seen.has(&"all"):
				seen[&"all"] = true
				_press(menu, &"overclock_link")
				check_eq(hero.action.id, &"overclock_link", "an all-allies move commits at once")
				check_eq(hero.targets.size(), 2, "aimed at both heroes")
		menu.free()
		if seen.size() == 3:
			break
	check(seen.has(&"self") and seen.has(&"ally"), "both a self move and an ally move were exercised")
