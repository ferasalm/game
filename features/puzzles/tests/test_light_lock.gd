class_name TestLightLock
extends TestCase
## purpose: Tests qamariya light lock puzzle logic, state, beam tracing, routes, loops, and def validation.


func _def() -> LightLockDef:
	return ContentDB.get_def("light_lock", &"valve_lock") as LightLockDef


func test_start_state_and_all_shutters_open() -> void:
	var def: LightLockDef = _def()
	var state: LightLockState = LightLockState.start(def)
	check_eq(LightLock.lens_bits(def, state), 0, "start lens_bits 0")
	check(not LightLock.solved(def, state), "start not solved")

	LightLock.toggle_shutter(state, &"red")
	LightLock.toggle_shutter(state, &"green")
	LightLock.toggle_shutter(state, &"blue")
	LightLock.toggle_shutter(state, &"yellow")
	check_eq(LightLock.lens_bits(def, state), 0, "all shutters open at start turns: lens_bits 0")
	check(not LightLock.solved(def, state), "all shutters open at start turns: not solved")


func test_yellow_blue_route_solved() -> void:
	var def: LightLockDef = _def()
	var state: LightLockState = LightLockState.start(def)
	LightLock.toggle_shutter(state, &"yellow")
	LightLock.toggle_shutter(state, &"blue")
	LightLock.turn_mirror(state, &"m1")
	LightLock.turn_mirror(state, &"m2")
	LightLock.turn_mirror(state, &"m2")
	check_eq(LightLock.lens_bits(def, state), 7, "yellow + blue gives 7")
	check(LightLock.solved(def, state), "yellow + blue solved")


func test_three_colours_route_solved() -> void:
	var def: LightLockDef = _def()
	var state: LightLockState = LightLockState.start(def)
	LightLock.toggle_shutter(state, &"red")
	LightLock.toggle_shutter(state, &"green")
	LightLock.toggle_shutter(state, &"blue")
	LightLock.turn_mirror(state, &"m1")
	LightLock.turn_mirror(state, &"m2")
	LightLock.turn_mirror(state, &"m2")
	LightLock.turn_mirror(state, &"m3")
	check_eq(LightLock.lens_bits(def, state), 7, "three colours gives 7")
	check(LightLock.solved(def, state), "three colours solved")


func test_near_misses() -> void:
	var def: LightLockDef = _def()
	var s1: LightLockState = LightLockState.start(def)
	LightLock.toggle_shutter(s1, &"red")
	LightLock.toggle_shutter(s1, &"yellow")
	LightLock.turn_mirror(s1, &"m1")
	LightLock.turn_mirror(s1, &"m2")
	LightLock.turn_mirror(s1, &"m2")
	check_eq(LightLock.lens_bits(def, s1), 3, "red + yellow gives 3")
	check(not LightLock.solved(def, s1), "red + yellow not solved")

	var s2: LightLockState = LightLockState.start(def)
	LightLock.toggle_shutter(s2, &"green")
	LightLock.toggle_shutter(s2, &"yellow")
	LightLock.turn_mirror(s2, &"m3")
	LightLock.turn_mirror(s2, &"m2")
	LightLock.turn_mirror(s2, &"m2")
	check_eq(LightLock.lens_bits(def, s2), 3, "green + yellow gives 3")
	check(not LightLock.solved(def, s2), "green + yellow not solved")


func test_loop_and_undo() -> void:
	var def: LightLockDef = _def()
	var state: LightLockState = LightLockState.start(def)
	LightLock.toggle_shutter(state, &"red")
	LightLock.turn_mirror(state, &"m1")
	LightLock.turn_mirror(state, &"m1")
	LightLock.turn_mirror(state, &"m1")
	LightLock.turn_mirror(state, &"m3")
	LightLock.turn_mirror(state, &"m3")

	var path: Array[StringName] = LightLock.trace(def, state, &"red")
	check(not path.is_empty(), "trace stopped and produced path")
	check(path.back() != &"lens", "loop path does not end at lens")
	check_eq(LightLock.lens_bits(def, state), 0, "loop excludes red beam")

	LightLock.toggle_shutter(state, &"red")
	LightLock.turn_mirror(state, &"m1")
	LightLock.turn_mirror(state, &"m3")
	LightLock.turn_mirror(state, &"m3")
	check_eq(state.shutters[&"red"], false, "shutter returned to closed")
	check_eq(state.turns[&"m1"], 0, "m1 returned to turn 0")
	check_eq(state.turns[&"m3"], 0, "m3 returned to turn 0")


func test_def_validation_reports_problems() -> void:
	var bad_target_dict: Dictionary = {
		"id": "bad_target",
		"windows": [{"id": "red", "bits": 1, "target": "missing_mirror"}],
		"mirrors": [{"id": "m1", "targets": ["", "", "", ""], "start": 0}]
	}
	var errs1 := PackedStringArray()
	var d1 := LightLockDef.new()
	d1.read(DefReader.new(bad_target_dict, "test", errs1))
	check("\n".join(errs1).contains("no id"), "bad target id reported")

	var bad_bits_dict: Dictionary = {
		"id": "bad_bits",
		"windows": [{"id": "red", "bits": 9, "target": "m1"}],
		"mirrors": [{"id": "m1", "targets": ["", "", "", ""], "start": 0}]
	}
	var errs2 := PackedStringArray()
	var d2 := LightLockDef.new()
	d2.read(DefReader.new(bad_bits_dict, "test", errs2))
	check("\n".join(errs2).contains("outside 1..7") or "\n".join(errs2).contains("bits"), "bad bits reported")

	var bad_mir_dict: Dictionary = {
		"id": "bad_mir",
		"windows": [{"id": "red", "bits": 1, "target": "m1"}],
		"mirrors": [{"id": "m1", "targets": ["", ""], "start": 0}]
	}
	var errs3 := PackedStringArray()
	var d3 := LightLockDef.new()
	d3.read(DefReader.new(bad_mir_dict, "test", errs3))
	check("\n".join(errs3).contains("4 targets"), "!= 4 targets reported")
