extends TestCase
## T6: the prototype main scene builds headless with rooftop, dialogue box and workshop menu; a simulated patrol
## touch starts a battle and stops exploring; an auto-played battle ends and walking resumes with the patrol reset;
## retry starts a fresh battle; the first workshop visit plays the talk, then the menu; later visits skip the talk.

const DT: float = 1.0 / 60.0


func _make() -> PrototypeMain:
	GameState.reset()
	var main := (load("res://features/prototype/prototype_main.tscn") as PackedScene).instantiate() as PrototypeMain
	main.stage_created.connect(func(stage: BattleStage) -> void:
		stage.auto_play = true
		stage.instant = true)
	tree.root.add_child(main)
	return main


func _touch(main: PrototypeMain) -> void:
	main.rooftop.patrol.position = main.rooftop.player.position + Vector3(0.3, 0.0, 0.0)
	main.rooftop.patrol._physics_process(DT)


func _visit_workshop(main: PrototypeMain) -> void:
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	main.rooftop.player.position = main.rooftop.workshop.position + Vector3(0.5, 0.0, 0.0)
	main.rooftop.workshop._physics_process(DT)
	main.rooftop.workshop._unhandled_input(press)


func _talk_through(main: PrototypeMain) -> int:
	var presses: int = 0
	while main.dialogue.is_playing() and presses < 30:
		main.dialogue.advance()
		presses += 1
	return presses


func test_map_chests_give_their_items_once() -> void:
	var main: PrototypeMain = _make()
	for chest_id: StringName in [&"chest_saila", &"chest_mafraj"]:
		var chest := ContentDB.get_def("chest", chest_id) as ChestDef
		check(chest != null and chest.place == &"rooftop", "map chest %s has a rooftop ChestDef" % chest_id)
		main.rooftop.chest_opened.emit(chest_id)
		check(GameState.inventory.has(chest.item), "opening %s gives %s" % [chest_id, chest.item])
		var count := GameState.inventory.size()
		main.rooftop.chest_opened.emit(chest_id)
		check_eq(GameState.inventory.size(), count, "a chest gives its item only once")
	main.free()


func test_builds_headless() -> void:
	var main: PrototypeMain = _make()
	check(main.rooftop != null and main.rooftop.player != null, "the rooftop is built")
	check(main.dialogue != null and main.menu != null, "dialogue box and workshop menu exist")
	check(main.stage == null, "no battle yet")
	check(not main.dialogue.is_playing() and not main.menu.is_open(), "both idle")
	check(main.rooftop.camera.current, "the rooftop camera is current")
	main.free()


func test_touch_starts_a_battle_and_it_returns_to_walking() -> void:
	var main: PrototypeMain = _make()
	var log: Array = []
	EventBus.battle_started.connect(func(id: StringName) -> void: log.append(["start", id]))
	EventBus.battle_ended.connect(func(id: StringName, won: bool) -> void: log.append(["end", id, won]))
	_touch(main)
	check(main.stage != null and main.stage.is_inside_tree(), "a BattleStage exists in the tree")
	check(not main.rooftop.player.visible, "exploring is off during the battle")
	check_eq((log[0] as Array)[1], &"rooftop_patrol", "battle_started carries the encounter id")
	var result: StringName = main.stage.run_to_end(30000)
	check(result == &"victory" or result == &"defeat", "the battle ends (%s)" % result)
	check(main.stage == null, "the stage is gone after the battle")
	check(main.rooftop.player.visible, "exploring is back on")
	check(not main.rooftop.patrol.visible, "the patrol was reset (hidden until it respawns)")
	check(main.rooftop.camera.current, "the rooftop camera is current again")
	check_eq(log.size(), 2, "battle_started and battle_ended, once each")
	check_eq((log[1] as Array)[2], result == &"victory", "battle_ended carries the outcome")
	main.free()


func test_retry_builds_a_fresh_battle() -> void:
	var main: PrototypeMain = _make()
	_touch(main)
	var first: BattleStage = main.stage
	var ended: Array[bool] = []
	EventBus.battle_ended.connect(func(_id: StringName, _won: bool) -> void: ended.append(true))
	first.ended.emit(&"retry")
	check(main.stage != null and main.stage != first, "a new stage replaced the old one")
	check(not first.is_inside_tree(), "the old stage left the tree")
	check(main.stage.sim != first.sim, "a fresh sim")
	check(ended.is_empty() and not main.rooftop.player.visible, "still in battle, no battle_ended")
	var result: StringName = main.stage.run_to_end(30000)
	check(result == &"victory" or result == &"defeat", "the retried battle ends")
	check(main.stage == null and main.rooftop.player.visible, "and walking resumes")
	main.free()


func test_ambush_side_reaches_the_battle() -> void:
	var main: PrototypeMain = _make()
	main.rooftop.player.facing = Vector3(-1.0, 0.0, 0.0)
	_touch(main)
	check_eq(main.stage.sim.ambush, 1, "the patrol struck from behind")
	main.free()


func test_saved_equipment_is_used() -> void:
	var main: PrototypeMain = _make()
	GameState.equipment[&"zayd.hilt"] = &"anvil_hilt"
	GameState.equipment[&"zayd.blade"] = &"broad_blade"
	GameState.equipment[&"zayd.prosthetic"] = &"arc_arm"
	_touch(main)
	var expected: CombatantDef = BattleLoader.from_db(ContentDB).zayd_with(&"anvil_hilt", &"broad_blade", &"arc_arm")
	var zayd: CombatantDef = main.stage.sim.timeline.find(&"zayd").def
	check_eq(zayd.attack, expected.attack, "Zayd wears the saved blade and prosthetic")
	check_eq(zayd.agility, expected.agility, "and the saved hilt")
	check(zayd.actions.has(&"arc_discharge"), "the prosthetic's tech move is in his list")
	main.free()
	GameState.reset()


func test_first_workshop_visit_talks_then_opens_the_menu() -> void:
	var main: PrototypeMain = _make()
	_visit_workshop(main)
	check(main.dialogue.is_playing(), "the first visit plays the dialogue")
	check(not main.menu.is_open(), "the menu waits for the talk")
	check(not main.rooftop.player.visible, "exploring is off")
	check_eq(_talk_through(main), 8, "four lines, two presses each")
	check(GameState.flags.get(&"workshop_talk_done", false), "the talk is remembered")
	check(main.menu.is_open(), "the menu opens after the talk")
	main.menu.cancel()
	check(main.rooftop.player.visible, "closing the menu resumes exploring")
	_visit_workshop(main)
	check(not main.dialogue.is_playing(), "the second visit skips the talk")
	check(main.menu.is_open(), "and opens the menu at once")
	main.menu.cancel()
	check(main.rooftop.player.visible, "closed again, walking")
	main.free()
	GameState.reset()


func test_a_new_game_owns_the_start_gear() -> void:
	var main: PrototypeMain = _make()
	for item_id: StringName in [&"grandfather_hilt", &"rustwire_blade", &"salvage_arm", &"wrist_rig"]:
		check(GameState.inventory.has(item_id), "owns %s" % item_id)
	check_eq(GameState.inventory.size(), 4, "and nothing else")
	main.free()
	GameState.reset()


func test_the_first_workshop_visit_stocks_the_bench_once() -> void:
	var main: PrototypeMain = _make()
	var got: Array[StringName] = []
	var hook := func(item_id: StringName) -> void: got.append(item_id)
	EventBus.item_obtained.connect(hook)
	_visit_workshop(main)
	check_eq(got, [&"swift_hilt", &"keen_blade"] as Array[StringName], "the Uncommon hilt and blade, announced")
	check(GameState.inventory.has(&"swift_hilt") and GameState.inventory.has(&"keen_blade"), "both owned")
	_talk_through(main)
	main.menu.cancel()
	_visit_workshop(main)
	check_eq(got.size(), 2, "the second visit gives nothing more")
	EventBus.item_obtained.disconnect(hook)
	main.free()
	GameState.reset()


func test_winning_grants_the_loot_once_and_losing_grants_nothing() -> void:
	var main: PrototypeMain = _make()
	var got: Array[StringName] = []
	var hook := func(item_id: StringName) -> void: got.append(item_id)
	EventBus.item_obtained.connect(hook)
	_touch(main)
	main.stage.ended.emit(&"defeat")
	check(not GameState.inventory.has(&"anvil_hilt"), "a defeat drops nothing")
	main.free()
	main = _make()
	_touch(main)
	main.stage.ended.emit(&"victory")
	check(GameState.inventory.has(&"anvil_hilt"), "the patrol's Rare hilt is owned")
	check_eq(got, [&"anvil_hilt"] as Array[StringName], "announced once through item_obtained")
	main._grant([&"anvil_hilt"] as Array[StringName])
	check_eq(got.size(), 1, "owning it already: no second announcement")
	EventBus.item_obtained.disconnect(hook)
	main.free()
	GameState.reset()
