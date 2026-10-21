extends TestCase
## The command menu with tech moves: an ally move lists the allies (not the foes), self and all-moves skip the
## target list and commit at once, and the party is built from saved gear.


func _stage(battle_seed: int) -> BattleStage:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var gear: Dictionary[StringName, StringName] = {&"zayd.prosthetic": &"cradle_spine", &"bilqis.prosthetic": &"lens_array"}
	var stage := BattleStage.new()
	stage.instant = true
	tree.root.add_child(stage)
	stage.start(loader.make_sim_for(loader.party_from_equipment(gear), battle_seed), Vector3.ZERO)
	stage.run_to_end(30000)
	return stage


func _press(stage: BattleStage, action_id: StringName) -> void:
	for button: Button in stage.hud.menu.move_buttons():
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
		var stage: BattleStage = _stage(battle_seed)
		var hero: UnitState = stage.sim.waiting_hero()
		if hero != null and hero.def.id == &"zayd" and not seen.has(&"self"):
			seen[&"self"] = true
			_press(stage, &"reactive_guard")
			check_eq(hero.action.id, &"reactive_guard", "a self move commits without a target list")
			check_eq(hero.targets, [&"zayd"] as Array[StringName], "aimed at the caster")
			check(not stage.hud.menu.is_open(), "the menu closed")
		elif hero != null and hero.def.id == &"bilqis":
			if not seen.has(&"ally"):
				seen[&"ally"] = true
				_press(stage, &"nanite_mend")
				check_eq(_unit_ids(stage.hud.menu.target_buttons()), [&"zayd", &"bilqis"] as Array[StringName], "allies, in timeline order")
				stage.hud.menu.target_buttons()[0].pressed.emit()
				check_eq(hero.targets, [&"zayd"] as Array[StringName], "healing Zayd")
			elif not seen.has(&"all"):
				seen[&"all"] = true
				_press(stage, &"overclock_link")
				check_eq(hero.action.id, &"overclock_link", "an all-allies move commits at once")
				check_eq(hero.targets.size(), 2, "aimed at both heroes")
		stage.free()
		if seen.size() == 3:
			break
	check(seen.has(&"self") and seen.has(&"ally"), "both a self move and an ally move were exercised")
