class_name TestStartSteps
extends TestCase
## Tests for StartSteps state transitions and choices.


func test_full_path_to_launch() -> void:
	var steps := StartSteps.new()
	check_eq(steps.state, StartSteps.STATE_TITLE, "starts at TITLE")

	var ok_title: bool = steps.confirm()
	check(ok_title, "confirm on TITLE succeeds")
	check_eq(steps.state, StartSteps.STATE_MENU, "TITLE -> MENU")

	var ok_menu: bool = steps.confirm()
	check(ok_menu, "confirm New Game on MENU succeeds")
	check_eq(steps.state, StartSteps.STATE_WINDOW_PUSH, "MENU -> WINDOW_PUSH")

	steps.clip_done()
	check_eq(steps.state, StartSteps.STATE_PICK, "WINDOW_PUSH -> PICK")

	check_eq(steps.hero, StartSteps.HERO_RYDAN, "default hero is Rydan")
	var ok_pick: bool = steps.confirm()
	check(ok_pick, "confirm Rydan on PICK succeeds")
	check_eq(steps.state, StartSteps.STATE_PANEL, "PICK -> PANEL")

	check_eq(steps.difficulty, StartSteps.DIFF_NORMAL, "default difficulty is normal")
	var ok_panel: bool = steps.confirm()
	check(ok_panel, "confirm on PANEL succeeds")
	check_eq(steps.state, StartSteps.STATE_REACTION, "PANEL -> REACTION")

	steps.clip_done()
	check_eq(steps.state, StartSteps.STATE_LAUNCH, "REACTION -> LAUNCH")

	steps.clip_done()
	check_eq(steps.state, StartSteps.STATE_DONE, "LAUNCH -> DONE")


func test_back_from_each_state() -> void:
	var steps := StartSteps.new()
	check(not steps.back(), "cannot back from TITLE")

	steps.confirm()  # -> MENU
	check_eq(steps.state, StartSteps.STATE_MENU, "at MENU")
	check(steps.back(), "back from MENU succeeds")
	check_eq(steps.state, StartSteps.STATE_TITLE, "MENU back -> TITLE")

	steps.confirm()  # -> MENU
	steps.confirm()  # -> WINDOW_PUSH
	steps.clip_done()  # -> PICK
	check_eq(steps.state, StartSteps.STATE_PICK, "at PICK")
	check(steps.back(), "back from PICK succeeds")
	check_eq(steps.state, StartSteps.STATE_MENU, "PICK back -> MENU")

	steps.confirm()  # -> WINDOW_PUSH
	steps.clip_done()  # -> PICK
	steps.confirm()  # -> PANEL
	check_eq(steps.state, StartSteps.STATE_PANEL, "at PANEL")
	check(steps.back(), "back from PANEL succeeds")
	check_eq(steps.state, StartSteps.STATE_PICK, "PANEL back -> PICK")


func test_bilqis_cannot_be_picked() -> void:
	var steps := StartSteps.new()
	steps.state = StartSteps.STATE_PICK
	check(not steps.select_hero(StartSteps.HERO_BILQIS), "select Bilqis returns false")
	check_eq(steps.hero, StartSteps.HERO_BILQIS, "hero set to Bilqis")
	check(not steps.can_pick_hero(StartSteps.HERO_BILQIS), "cannot pick Bilqis")
	check(not steps.confirm(), "confirm Bilqis rejected")
	check_eq(steps.state, StartSteps.STATE_PICK, "remains in PICK")


func test_difficulty_toggles() -> void:
	var steps := StartSteps.new()
	steps.state = StartSteps.STATE_PANEL
	check_eq(steps.difficulty, StartSteps.DIFF_NORMAL, "starts normal")

	steps.toggle_difficulty()
	check_eq(steps.difficulty, StartSteps.DIFF_HARD, "toggled to hard")

	steps.toggle_difficulty()
	check_eq(steps.difficulty, StartSteps.DIFF_NORMAL, "toggled back to normal")

	steps.set_difficulty(StartSteps.DIFF_HARD)
	check_eq(steps.difficulty, StartSteps.DIFF_HARD, "set to hard directly")


func test_menu_navigation_and_quit() -> void:
	var steps := StartSteps.new()
	steps.state = StartSteps.STATE_MENU
	check_eq(steps.menu_cursor, StartSteps.MENU_NEW_GAME, "menu starts at New Game")

	steps.move_menu(1)
	check_eq(steps.menu_cursor, StartSteps.MENU_QUIT, "moves to Quit")

	steps.move_menu(-1)
	check_eq(steps.menu_cursor, StartSteps.MENU_NEW_GAME, "moves back to New Game")

	steps.select_menu_index(StartSteps.MENU_QUIT)
	check(steps.confirm(), "confirming quit succeeds")
	check(steps.quit_requested, "quit_requested is true")
