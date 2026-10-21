extends TestCase
## The Router outside battles: the play-time clock (not while paused or at the title, real seconds under a slowed
## time scale), busy and can_save, unstuck to the last place the player stood still, and the saved chest state.


func test_play_time_counts_only_while_the_game_runs() -> void:
	GameState.reset()
	Router.state = Router.STATE_EXPLORING
	Router.tick(1.0)
	check_eq(GameState.play_seconds, 1.0, "exploring counts")
	tree.paused = true
	Router.tick(1.0)
	tree.paused = false
	check_eq(GameState.play_seconds, 1.0, "a paused game does not count")
	Engine.time_scale = 0.5
	Router.tick(0.5)
	Engine.time_scale = 1.0
	check_eq(GameState.play_seconds, 2.0, "a slowed frame counts its real seconds")
	Router.state = Router.STATE_TITLE
	Router.tick(5.0)
	check_eq(GameState.play_seconds, 2.0, "the title does not count")
	Router.state = Router.STATE_BATTLE
	Router.tick(1.0)
	check_eq(GameState.play_seconds, 3.0, "a battle counts")
	Router.state = Router.STATE_TITLE
	GameState.reset()


func test_busy_blocks_saving_until_it_ends() -> void:
	Router.state = Router.STATE_EXPLORING
	check(Router.can_save(), "exploring with no screen: saving is allowed")
	Router.set_busy(true)
	check(not Router.can_save() and not Router.is_exploring(), "busy: no saving, no pause menu")
	Router.set_busy(false)
	check(Router.can_save(), "and allowed again afterwards")
	Router.state = Router.STATE_BATTLE
	check(not Router.can_save(), "never during a battle")
	Router.set_busy(true)
	check_eq(Router.state, Router.STATE_BATTLE, "set_busy leaves a battle alone")
	Router.state = Router.STATE_TITLE


func test_unstuck_returns_to_the_last_place_he_stood_still() -> void:
	var h := FlowHarness.new(tree)
	var main: PrototypeMain = h.make_main()
	var spot: Vector3 = main.rooftop.player.position + Vector3(6.0, 0.0, 0.0)
	main.rooftop.player.position = spot
	for i: int in 4:
		main.rooftop._process(1.0)
	main.rooftop.player.position = spot + Vector3(9.0, 0.0, 0.0)
	Router.unstuck()
	check((main.rooftop.player.position - spot).length() < 0.01, "Zayd is back at the spot he rested at")
	check(main.rooftop.follower.position.distance_to(spot) < 5.0, "Bilqis is beside him")
	main.free()
	h.finish()


func test_a_chest_opened_in_the_save_is_built_open() -> void:
	var h := FlowHarness.new(tree)
	GameState.start_new()
	GameState.flags[Chests.flag(&"chest_saila")] = true
	var main: PrototypeMain = h.make_main()
	var opened: Chest = main.rooftop.dressing.chest(&"chest_saila")
	var closed: Chest = main.rooftop.dressing.chest(&"chest_mafraj")
	check(opened.is_open and opened.lid_progress() == 1.0, "the saved chest is open, lid at rest")
	check(opened.hinge.rotation.x < 0.0, "with its lid up")
	check(not closed.is_open and closed.lid_progress() == 0.0, "the other chest is still closed")
	main.free()
	h.finish()
