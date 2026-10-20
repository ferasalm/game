extends TestCase
## Save data survives a round trip through JSON, and a save from another version is refused.


func test_round_trip_through_json() -> void:
	var state: Node = load("res://core/game_state.gd").new()
	state.set("party", [&"zayd", &"bilqis"] as Array[StringName])
	state.set("area_id", &"ch1_ridge")
	(state.get("flags") as Dictionary)[&"met_bilqis"] = true
	(state.get("counters") as Dictionary)[&"resin_hojari"] = 3
	var saved: String = JSON.stringify(state.call("to_dict"))
	var loaded: Node = load("res://core/game_state.gd").new()
	check_eq(loaded.call("from_dict", JSON.parse_string(saved)), "", "accepted")
	check_eq(JSON.stringify(loaded.call("to_dict")), saved, "same data after the round trip")
	check_eq(loaded.call("from_dict", {"version": 99}), "save version 99, expected 1", "other version refused")
	state.free()
	loaded.free()
