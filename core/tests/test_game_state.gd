extends TestCase
## Save data survives a round trip through JSON, a version-1 save migrates, and an unknown version is refused.


func _state() -> Node:
	return load("res://core/game_state.gd").new()


func test_round_trip_through_json() -> void:
	var state: Node = _state()
	state.set("party", [&"zayd", &"bilqis"] as Array[StringName])
	state.set("area_id", &"ch1_ridge")
	(state.get("flags") as Dictionary)[&"met_bilqis"] = true
	(state.get("counters") as Dictionary)[&"resin_hojari"] = 3
	(state.get("equipment") as Dictionary)[&"hilt"] = &"anvil_hilt"
	(state.get("equipment") as Dictionary)[&"blade"] = &"broad_blade"
	var saved: String = JSON.stringify(state.call("to_dict"))
	var loaded: Node = _state()
	check_eq(loaded.call("from_dict", JSON.parse_string(saved)), "", "accepted")
	check_eq(JSON.stringify(loaded.call("to_dict")), saved, "same data after the round trip")
	check_eq((loaded.get("equipment") as Dictionary)[&"hilt"], &"anvil_hilt", "hilt restored as a StringName")
	check_eq((loaded.get("equipment") as Dictionary)[&"blade"], &"broad_blade", "blade restored")
	state.free()
	loaded.free()


func test_unknown_versions_are_refused() -> void:
	var state: Node = _state()
	check_eq(state.call("from_dict", {"version": 99}), "save version 99, expected 2", "newer version refused")
	check_eq(state.call("from_dict", {"version": 0}), "save version 0, expected 2", "no version refused")
	state.free()


func test_version_one_save_migrates_with_empty_equipment() -> void:
	var state: Node = _state()
	(state.get("equipment") as Dictionary)[&"hilt"] = &"anvil_hilt"
	var old: Dictionary = {"version": 1, "flags": {"met_bilqis": true}, "counters": {}, "party": ["zayd"],
		"area_id": "ch1_ridge", "spawn_id": ""}
	check_eq(state.call("from_dict", old), "", "version 1 accepted")
	check((state.get("equipment") as Dictionary).is_empty(), "equipment empty after migration")
	check_eq((state.get("area_id") as StringName), &"ch1_ridge", "other fields kept")
	check_eq((state.call("to_dict") as Dictionary)["version"], 2, "saved again as version 2")
	state.free()


func test_reset_clears_equipment() -> void:
	var state: Node = _state()
	(state.get("equipment") as Dictionary)[&"blade"] = &"broad_blade"
	state.call("reset")
	check((state.get("equipment") as Dictionary).is_empty(), "reset clears equipment")
	state.free()
