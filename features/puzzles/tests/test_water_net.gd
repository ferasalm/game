class_name TestWaterNet
extends TestCase
## purpose: Tests water routing network logic, unjamming, spout routing, conservation, def errors, and hints.


func _def() -> WaterNetDef:
	return ContentDB.get_def("water_net", &"valve_water") as WaterNetDef


func test_water_start_and_spill_to_grate() -> void:
	var def: WaterNetDef = _def()
	var state: WaterNetState = WaterNetState.start(def)
	var shares0: Dictionary[StringName, float] = WaterNet.outlet_shares(def, state)
	check_eq(shares0.get(&"canyon", 0.0), 0.0, "start canyon 0")

	WaterNet.toggle_gate(state, def, &"g1")
	state.spout[&"s1"] = 0
	WaterNet.toggle_gate(state, def, &"g4")
	state.spout[&"s2"] = 0
	var shares: Dictionary[StringName, float] = WaterNet.outlet_shares(def, state)
	check_eq(shares.get(&"canyon", 0.0), 0.0, "canyon gets 0 when g3 open spills s2")
	check(absf(shares.get(&"grate", 0.0) - 1.0) < 0.001, "grate gets 1.0")


func test_jammed_gate_and_free() -> void:
	var def: WaterNetDef = _def()
	var state: WaterNetState = WaterNetState.start(def)
	check(not WaterNet.toggle_gate(state, def, &"g3"), "toggle on unfreed g3 returns false")
	check_eq(state.open[&"g3"], true, "unfreed g3 stays open")
	check(WaterNet.free_gate(state, def, &"g3"), "free_gate succeeds first time")
	check(WaterNet.toggle_gate(state, def, &"g3"), "toggle shuts freed g3")
	check_eq(state.open[&"g3"], false, "freed g3 is now shut")
	check(not WaterNet.free_gate(state, def, &"g3"), "free_gate twice returns false")


func test_full_route_and_unsolved_dock_split() -> void:
	var def: WaterNetDef = _def()
	var state: WaterNetState = WaterNetState.start(def)
	WaterNet.free_gate(state, def, &"g3")
	WaterNet.toggle_gate(state, def, &"g1")
	WaterNet.toggle_gate(state, def, &"g3")
	WaterNet.toggle_gate(state, def, &"g4")
	state.spout[&"s1"] = 0
	state.spout[&"s2"] = 0

	var s_full: Dictionary[StringName, float] = WaterNet.outlet_shares(def, state)
	check(absf(s_full.get(&"canyon", 0.0) - 1.0) < 0.001, "canyon gets 1.0")
	check(WaterNet.solved(def, state), "full route is solved")

	WaterNet.toggle_gate(state, def, &"g4")
	var s_split: Dictionary[StringName, float] = WaterNet.outlet_shares(def, state)
	check(absf(s_split.get(&"canyon", 0.0) - 0.5) < 0.001, "canyon gets 0.5")
	check(absf(s_split.get(&"dock", 0.0) - 0.5) < 0.001, "dock gets 0.5")
	check(not WaterNet.solved(def, state), "dock split is unsolved")


func test_shares_at_outlets_sum_to_one_or_zero() -> void:
	var def: WaterNetDef = _def()
	var state: WaterNetState = WaterNetState.start(def)
	state.freed[&"g3"] = true

	var gates: Array[StringName] = [&"g1", &"g2", &"g3", &"g4"]
	for g_mask: int in 16:
		for i: int in 4:
			state.open[gates[i]] = (g_mask & (1 << i)) != 0
		for s1_val: int in 2:
			for s2_val: int in 2:
				state.spout[&"s1"] = s1_val
				state.spout[&"s2"] = s2_val
				var s: Dictionary[StringName, float] = WaterNet.outlet_shares(def, state)
				var sum: float = s.get(&"canyon", 0.0) + s.get(&"dock", 0.0) + s.get(&"grate", 0.0)
				check(absf(sum - 1.0) < 0.001 or absf(sum - 0.0) < 0.001, "outlet sum is 1.0 or 0.0")


func test_water_net_def_problems() -> void:
	var bad_id_data: Dictionary = {
		"id": "bad_id",
		"nodes": [
			{"id": "src", "kind": "source", "to": ["unknown_node"]},
			{"id": "out", "kind": "outlet", "reaction": "goal"}
		]
	}
	var errs1 := PackedStringArray()
	WaterNetDef.new().read(DefReader.new(bad_id_data, "test", errs1))
	check("\n".join(errs1).contains("unknown id"), "bad target id reported")

	var cycle_data: Dictionary = {
		"id": "cycle",
		"nodes": [
			{"id": "src", "kind": "source", "to": ["n1"]},
			{"id": "n1", "kind": "split", "to": ["n2"]},
			{"id": "n2", "kind": "gate", "to": ["n1"], "open": true}
		]
	}
	var errs2 := PackedStringArray()
	WaterNetDef.new().read(DefReader.new(cycle_data, "test", errs2))
	check("\n".join(errs2).contains("cycle"), "cycle reported")

	var two_src_data: Dictionary = {
		"id": "two_src",
		"nodes": [
			{"id": "s1", "kind": "source", "to": ["out"]},
			{"id": "s2", "kind": "source", "to": ["out"]},
			{"id": "out", "kind": "outlet", "reaction": "goal"}
		]
	}
	var errs3 := PackedStringArray()
	WaterNetDef.new().read(DefReader.new(two_src_data, "test", errs3))
	check("\n".join(errs3).contains("1 source"), "two sources reported")


func test_hints_due() -> void:
	var hint_secs: Array[int] = [120, 240]
	check_eq(PuzzleHints.hints_due(hint_secs, 119.0), 0, "0 hints due at 119 s")
	check_eq(PuzzleHints.hints_due(hint_secs, 120.0), 1, "1 hint due at 120 s")
	check_eq(PuzzleHints.hints_due(hint_secs, 239.0), 1, "1 hint due at 239 s")
	check_eq(PuzzleHints.hints_due(hint_secs, 240.0), 2, "2 hints due at 240 s")
