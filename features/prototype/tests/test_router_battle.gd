extends TestCase
## The Router's battle round trip: the area is hidden and stopped while the arena fights, then restored; Retry and
## defeat restore the pre-battle snapshot; vitals and herbs carry (a downed hero stands up after a victory); the first
## win pays everything and a repeat pays half.


func _hero_hp(main: PrototypeMain, hero: StringName) -> int:
	return main.stage.sim.timeline.find(hero).hp


func _fight_again(main: PrototypeMain) -> void:
	main.rooftop.encounter_touched.emit(&"rooftop_patrol", false)


func test_round_trip_hides_the_rooftop_and_brings_it_back() -> void:
	var h := FlowHarness.new(tree)
	var main: PrototypeMain = h.make_main()
	h.touch(main)
	var runner: BattleRunner = null
	for child: Node in main.get_children():
		if child is BattleRunner:
			runner = child as BattleRunner
	check(runner != null and runner.stage == main.stage, "the arena runner is the rooftop's sibling")
	var arena := ContentDB.get_def("arena", &"rooftop_arena") as ArenaDef
	check_eq(runner.arena.position, arena.origin, "the arena sits at its far origin")
	check(not main.rooftop.visible and main.rooftop.process_mode == Node.PROCESS_MODE_DISABLED, "the rooftop is hidden and stopped")
	check(main.rooftop.is_inside_tree(), "but still in the tree")
	check(main.stage.camera.current and main.stage.camera.environment != null, "the arena camera has its own environment")
	var result: StringName = main.stage.run_to_end(30000)
	check(result == &"victory" or result == &"defeat", "the fight ends")
	check(main.rooftop.visible and main.rooftop.process_mode == Node.PROCESS_MODE_INHERIT, "the rooftop is back and enabled")
	check_eq(main.rooftop.patrol.visible, not GameState.cleared_patrols.has(main.rooftop.patrol.encounter_id),
		"a beaten patrol is gone until the sabil; one that won is back at its start")
	check(main.rooftop.camera.current, "the rooftop camera is current again")
	check(main.stage == null and not main.get_children().any(func(n: Node) -> bool: return n is BattleRunner), "no arena left")
	check(Router.is_exploring(), "and the flow explores again")
	main.free()
	h.finish()


func test_retry_restores_the_snapshot_and_reseeds() -> void:
	var h := FlowHarness.new(tree)
	GameState.start_new()
	GameState.money = 77
	GameState.set_bag({&"pink_herb": 2})
	GameState.set_vitals({&"zayd": {"hp": 120, "sp": 5}})
	var main: PrototypeMain = h.make_main()
	h.touch(main)
	var first: BattleStage = main.stage
	check_eq(_hero_hp(main, &"zayd"), 120, "Zayd enters with his carried HP")
	GameState.money = 5
	GameState.set_bag({})
	GameState.set_vitals({})
	first.ended.emit(&"retry")
	check_eq(GameState.money, 77, "Retry gives the purse back")
	check_eq(GameState.bag, {&"pink_herb": 2} as Dictionary, "and the herbs")
	check_eq(Vitals.hp_of(GameState.vitals, &"zayd", 999), 120, "and the vitals")
	check(main.stage != null and main.stage != first, "a new stage replaced the old one")
	check_eq(main.stage.sim.setup.seed, first.sim.setup.seed + 1, "the retry is not a replay")
	check_eq(_hero_hp(main, &"zayd"), 120, "the retried fight starts from the snapshot")
	check(h.outcomes.is_empty() and Router.state == Router.STATE_BATTLE, "no outcome yet, still in battle")
	main.stage.ended.emit(&"defeat")
	check_eq(h.outcomes[0].result, &"defeat", "a defeat ends the fight")
	check_eq(GameState.money, 77, "a defeat loses no money")
	check(Router.is_exploring(), "and returns to the area")
	main.free()
	h.finish()


func test_vitals_carry_and_a_downed_hero_stands_up_after_victory() -> void:
	var h := FlowHarness.new(tree)
	GameState.start_new()
	var main: PrototypeMain = h.make_main()
	h.touch(main)
	var sim: BattleSim = main.stage.sim
	sim.timeline.find(&"zayd").hp = 0
	sim.timeline.find(&"bilqis").hp = 40
	sim.timeline.find(&"bilqis").sp = 3
	main.stage.ended.emit(&"victory")
	check_eq(Vitals.hp_of(GameState.vitals, &"zayd", 999), 31, "the downed hero stands at ko_stand_hp + level up gain")
	check_eq(Vitals.hp_of(GameState.vitals, &"bilqis", 999), 60, "a living hero keeps her HP + level up gain")
	check_eq(Vitals.sp_of(GameState.vitals, &"bilqis", 999), 7, "and her SP + level up gain")
	_fight_again(main)
	check_eq(_hero_hp(main, &"zayd"), 31, "the next fight starts with that 31 HP")
	check_eq(_hero_hp(main, &"bilqis"), 60, "and her HP")
	main.stage.ended.emit(&"defeat")
	check_eq(Vitals.hp_of(GameState.vitals, &"zayd", 999), 31, "a defeat restores the snapshot, not the wounds")
	main.free()
	h.finish()


func test_the_first_win_pays_everything_and_a_repeat_half() -> void:
	var h := FlowHarness.new(tree)
	GameState.start_new()
	var start: int = GameState.money
	var main: PrototypeMain = h.make_main()
	h.touch(main)
	main.stage.ended.emit(&"victory")
	check_eq(GameState.money, start + 70, "the first win pays the encounter's riyal")
	check(GameState.inventory.has(&"anvil_hilt"), "and its loot")
	check(h.outcomes[0].rewarded and h.outcomes[0].money == 70, "the outcome reports it")
	check_eq(GameState.cleared_patrols, [&"rooftop_patrol"] as Array[StringName], "the patrol is cleared")
	_fight_again(main)
	main.stage.ended.emit(&"victory")
	check_eq(GameState.money, start + 105, "a repeat win pays half")
	check(h.outcomes[1].items.is_empty(), "and no loot")
	check_eq(GameState.cleared_patrols.size(), 1, "the patrol is listed once")
	_fight_again(main)
	main.stage.ended.emit(&"defeat")
	check_eq(GameState.money, start + 105, "a defeat pays nothing")
	check(not h.outcomes[2].rewarded, "and the outcome says so")
	main.free()
	h.finish()


func test_a_fight_during_the_opening_shot_stays_a_fight() -> void:
	var h := FlowHarness.new(tree)
	var main: PrototypeMain = h.make_main()
	check_eq(Router.state, Router.STATE_TITLE, "the opening shot is still playing")
	h.touch(main)
	check_eq(Router.state, Router.STATE_BATTLE, "the battle is a battle, not exploring")
	main.stage.ended.emit(&"defeat")
	check(Router.is_exploring(), "afterwards the flow explores")
	main.free()
	h.finish()
