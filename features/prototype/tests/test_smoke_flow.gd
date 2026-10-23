extends TestCase
## Smoke test of the whole flow, headless through the Router: a new game, a fight on auto-play, the outcome applied to
## GameState, a save, a load that restores exactly that state. (Shop and sabil come with Phase 2.)


func _snapshot() -> String:
	return JSON.stringify(GameState.to_dict(), "", true)


func test_new_game_fight_save_load_round_trip() -> void:
	var h := FlowHarness.new(tree)
	Router.new_game()
	check_eq(h.reloads, 1, "a new game reloads the scene once")
	check(GameState.money > 0 and not GameState.party.is_empty(), "start_new gave the purse and the party")
	var main: PrototypeMain = h.make_main()
	check(Router.is_exploring(), "a new game skips the title and explores at once")
	check(not Router.take_skip_title(), "the main scene consumed the skip flag")
	h.touch(main)
	check_eq(Router.state, Router.STATE_BATTLE, "the touch started a battle")
	var result: StringName = main.stage.run_to_end(30000)
	check(result == &"victory" or result == &"defeat", "the fight ends (%s)" % result)
	check_eq(h.outcomes.size(), 1, "one outcome came back")
	check_eq(h.outcomes[0].result, result, "and it names the result")
	check(Router.is_exploring() and main.stage == null, "back to exploring, the stage is gone")
	if result == &"victory":
		check(h.outcomes[0].rewarded and GameState.cleared_patrols.has(&"rooftop_patrol"), "a win is paid and cleared")
		check(GameState.flags.get(Rewards.paid_flag(&"rooftop_patrol"), false), "the first win sets its paid flag")
	var saved: String = _snapshot()
	check_eq(Router.save_slot(1), "", "the save works")
	check(Router.has_save(1), "and the slot exists")
	GameState.reset()
	check(_snapshot() != saved, "the state really changed")
	check_eq(Router.load_slot(1), "", "the load works")
	check_eq(_snapshot(), saved, "the loaded game equals the saved one")
	check_eq(h.reloads, 2, "a load reloads the scene")
	check(Router.take_skip_title(), "and skips the title the next time")
	main.free()
	h.finish()


func test_loading_a_missing_slot_says_why_and_changes_nothing() -> void:
	var h := FlowHarness.new(tree)
	GameState.start_new()
	var before: String = _snapshot()
	check(not Router.load_slot(1).is_empty(), "no save: an error text")
	check_eq(_snapshot(), before, "the state is untouched")
	check_eq(h.reloads, 0, "and the scene is not reloaded")
	h.finish()


func test_going_to_the_title_forgets_the_run() -> void:
	var h := FlowHarness.new(tree)
	GameState.start_new()
	Router.state = Router.STATE_EXPLORING
	Router.go_to_title()
	check_eq(Router.state, Router.STATE_TITLE, "the flow is at the title")
	check(GameState.party.is_empty() and GameState.money == 0, "the run is forgotten")
	check(not Router.take_skip_title(), "the title is shown, not skipped")
	check_eq(h.reloads, 1, "the scene reloads")
	h.finish()


func test_the_main_scene_starts_a_fresh_game_from_an_empty_state() -> void:
	var h := FlowHarness.new(tree)
	var main: PrototypeMain = h.make_main(&"")
	check_eq(Router.state, Router.STATE_TITLE, "a plain start shows the title")
	check(GameState.money > 0 and GameState.party.size() == 2, "and starts the new-game purse and party")
	check_eq(main.rooftop.area_id, &"souq_rooftops_v4", "default start is souq_rooftops_v4")
	check_eq(GameState.area_id, main.rooftop.area_id, "the area id is recorded for the save")
	main.free()
	h.finish()
