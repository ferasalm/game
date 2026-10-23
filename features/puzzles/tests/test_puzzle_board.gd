class_name TestPuzzleBoard
extends TestCase
## purpose: Tests the grey-box puzzle board: piece moves, nearest piece, saved solves, beams, lens colour,
## water strips, the canyon gauge and hint timing.

const LOCK: StringName = &"puzzle_valve_lock"
const WATER: StringName = &"puzzle_valve_water"


func _fresh() -> PuzzleBoard:
	GameState.flags.erase(LOCK)
	GameState.flags.erase(WATER)
	return PuzzleBoard.new()


func _solve_light(board: PuzzleBoard) -> void:
	board.act(&"yellow")
	board.act(&"blue")
	board.act(&"m1")
	board.act(&"m2")
	board.act(&"m2")


func test_act_changes_matching_state() -> void:
	var board: PuzzleBoard = _fresh()
	board.act(&"red")
	check_eq(board.light_state.shutters.get(&"red", false), true, "red shutter opens")
	board.act(&"m1")
	check_eq(board.light_state.turns.get(&"m1", -1), 1, "m1 turns")
	board.act(&"g1")
	check_eq(board.water_state.open.get(&"g1", true), false, "g1 closes")
	board.act(&"g3")
	check_eq(board.water_state.freed.get(&"g3", false), true, "g3 freed")
	board.act(&"g3")
	check_eq(board.water_state.open.get(&"g3", true), false, "freed g3 closes")
	board.act(&"s1")
	check_eq(board.water_state.spout.get(&"s1", -1), 0, "s1 swings")
	board.free()


func test_nearest_piece_range_and_water_lock() -> void:
	var board: PuzzleBoard = _fresh()
	check_eq(board.nearest_piece(Vector3(-5.5, 0.0, -4.9)), &"red", "red in range")
	check_eq(board.nearest_piece(Vector3(20.0, 0.0, 20.0)), &"", "nothing in range")
	check_eq(board.nearest_piece(Vector3(3.5, 0.0, -2.0)), &"", "water hidden before the lock")
	_solve_light(board)
	check(board.light_solved(), "yellow-blue solves the light lock")
	check_eq(board.nearest_piece(Vector3(3.5, 0.0, -2.0)), &"g1", "water offered after the lock")
	board.free()


func test_solve_sets_flag_and_reloads_solved() -> void:
	var board: PuzzleBoard = _fresh()
	_solve_light(board)
	check_eq(GameState.flags.get(LOCK, false), true, "solving sets the lock flag")
	var loaded: PuzzleBoard = PuzzleBoard.new()
	check(loaded.light_solved(), "a board made after the solve loads solved")
	check_eq(loaded.light_state.shutters.get(&"yellow", false), true, "loaded yellow is open")
	board.free()
	loaded.free()


func test_beam_count_and_lens_colours() -> void:
	var board: PuzzleBoard = _fresh()
	var yard: PuzzleYardDef = board.yard
	check_eq(board.beam_count(), 0, "no beams at start")
	board.act(&"red")
	check_eq(board.beam_count(), 2, "red trace to its open end is two segments")
	check_eq(board.lens_color(), yard.color(&"lens_off"), "bits 0 lens is off")
	board.act(&"red")
	board.act(&"red")
	board.act(&"yellow")
	board.act(&"m1")
	board.act(&"m2")
	board.act(&"m2")
	check_eq(LightLock.lens_bits(board.light_def, board.light_state), 3, "red + yellow gives bits 3")
	check_eq(board.lens_color(), yard.color(&"yellow"), "bits 3 lens is yellow")
	board.act(&"blue")
	check_eq(LightLock.lens_bits(board.light_def, board.light_state), 7, "adding blue gives bits 7")
	check_eq(board.lens_color(), yard.color(&"white"), "bits 7 lens is white")
	board.free()


func test_no_water_before_light_lock() -> void:
	var board: PuzzleBoard = _fresh()
	for node: WaterNodeDef in board.water_def.nodes:
		for target: StringName in node.to:
			check(not board.water_strip_visible(node.id, target),
				"no strip on %s>%s before the lock" % [node.id, target])
	check(absf(board.canyon_gauge()) < 0.001, "gauge stays empty before the lock")
	check(absf(board.water_view.grate_share()) < 0.001, "grate line stays dry before the lock")
	_solve_light(board)
	check(board.water_strip_visible(&"g1", &"dock"), "water flows from the start state after the lock")
	check(absf(board.water_view.grate_share()) > 0.0, "the grate line shows water after the lock")
	board.free()


func test_water_strip_and_gauge() -> void:
	var board: PuzzleBoard = _fresh()
	_solve_light(board)
	check(board.water_strip_visible(&"g1", &"dock"), "g1 edge has water at start")
	check(not board.water_strip_visible(&"s2", &"canyon"), "s2 spills to the grate at start")
	board.water_state.freed[&"g3"] = true
	board.water_state.open[&"g1"] = false
	board.water_state.open[&"g3"] = false
	board.water_state.open[&"g4"] = false
	board.water_state.spout[&"s1"] = 0
	board.water_state.spout[&"s2"] = 0
	board.redraw()
	check(absf(board.canyon_gauge() - 1.0) < 0.001, "full route fills the gauge to 1.0")
	check(board.water_strip_visible(&"s2", &"canyon"), "canyon edge has water")
	check(not board.water_strip_visible(&"g1", &"dock"), "closed g1 edge has no water")
	board.water_state.open[&"g4"] = true
	board.redraw()
	check(absf(board.canyon_gauge() - 0.5) < 0.001, "dock split fills the gauge to 0.5")
	board.free()


func test_hints_once_at_due_times() -> void:
	var board: PuzzleBoard = _fresh()
	board.advance(119.0)
	check_eq(board.hints_due().size(), 0, "no hint before 120 s")
	board.advance(1.0)
	var first: Array[StringName] = board.hints_due()
	check_eq(first.size(), 1, "first hint at 120 s")
	check_eq(first[0], &"PUZZLE_LIGHT_HINT_1", "first hint key")
	board.advance(1.0)
	check_eq(board.hints_due().size(), 0, "first hint is shown once")
	board.advance(119.0)
	var second: Array[StringName] = board.hints_due()
	check_eq(second.size(), 1, "second hint at 240 s")
	check_eq(second[0], &"PUZZLE_LIGHT_HINT_2", "second hint key")
	board.free()
