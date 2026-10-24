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
	(state.get("equipment") as Dictionary)[&"zayd.hilt"] = &"anvil_hilt"
	(state.get("equipment") as Dictionary)[&"zayd.blade"] = &"broad_blade"
	(state.get("equipment") as Dictionary)[&"bilqis.prosthetic"] = &"lens_array"
	(state.get("inventory") as Array).append_array([&"anvil_hilt", &"broad_blade", &"lens_array"])
	var saved: String = JSON.stringify(state.call("to_dict"))
	var loaded: Node = _state()
	check_eq(loaded.call("from_dict", JSON.parse_string(saved)), "", "accepted")
	check_eq(JSON.stringify(loaded.call("to_dict")), saved, "same data after the round trip")
	check_eq((loaded.get("equipment") as Dictionary)[&"zayd.hilt"], &"anvil_hilt", "hilt restored as a StringName")
	check_eq((loaded.get("equipment") as Dictionary)[&"zayd.blade"], &"broad_blade", "blade restored")
	check_eq((loaded.get("equipment") as Dictionary)[&"bilqis.prosthetic"], &"lens_array", "prosthetic restored")
	check_eq((loaded.get("inventory") as Array), [&"anvil_hilt", &"broad_blade", &"lens_array"], "inventory restored")
	state.free()
	loaded.free()


func test_unknown_versions_are_refused() -> void:
	var state: Node = _state()
	check_eq(state.call("from_dict", {"version": 99}), "save version 99, expected 6", "newer version refused")
	check_eq(state.call("from_dict", {"version": 0}), "save version 0, expected 6", "no version refused")
	state.free()


func test_version_one_save_migrates_with_empty_equipment() -> void:
	var state: Node = _state()
	(state.get("equipment") as Dictionary)[&"hilt"] = &"anvil_hilt"
	var old: Dictionary = {"version": 1, "flags": {"met_bilqis": true}, "counters": {}, "party": ["zayd"],
		"area_id": "ch1_ridge", "spawn_id": ""}
	check_eq(state.call("from_dict", old), "", "version 1 accepted")
	check_eq((state.get("equipment") as Dictionary).get(&"zayd.armor"), &"courier_jacket", "start armor given")
	check_eq((state.get("area_id") as StringName), &"ch1_ridge", "other fields kept")
	check_eq((state.call("to_dict") as Dictionary)["version"], 6, "saved again as version 6")
	state.free()


func test_reset_clears_equipment() -> void:
	var state: Node = _state()
	(state.get("equipment") as Dictionary)[&"blade"] = &"broad_blade"
	state.call("reset")
	check((state.get("equipment") as Dictionary).is_empty(), "reset clears equipment")
	state.free()


func test_version_two_save_migrates_slot_keys_and_owns_what_is_worn() -> void:
	var state: Node = _state()
	var old: Dictionary = {"version": 2, "flags": {}, "counters": {}, "party": ["zayd"], "area_id": "", "spawn_id": "",
		"equipment": {"hilt": "anvil_hilt", "blade": "broad_blade"}}
	check_eq(state.call("from_dict", old), "", "version 2 accepted")
	var equipment: Dictionary = state.get("equipment")
	check_eq(equipment.get(&"zayd.hilt"), &"anvil_hilt", "hilt moves to zayd.hilt")
	check_eq(equipment.get(&"zayd.blade"), &"broad_blade", "blade moves to zayd.blade")
	check(not equipment.has(&"hilt") and not equipment.has(&"blade"), "the old keys are gone")
	var inv: Array = state.get("inventory")
	check(inv.has(&"anvil_hilt") and inv.has(&"broad_blade"), "worn items count as owned")
	state.free()


func test_reset_clears_inventory() -> void:
	var state: Node = _state()
	(state.get("inventory") as Array).append(&"keen_blade")
	state.call("reset")
	check((state.get("inventory") as Array).is_empty(), "reset clears the inventory")
	state.free()


func test_version_four_save_migrates_to_version_five() -> void:
	var state: Node = _state()
	var old: Dictionary = {
		"version": 4, "flags": {}, "counters": {}, "party": ["zayd", "bilqis"],
		"place": {"area": "ch1_ridge", "save_point": "sp_1"},
		"equipment": {"zayd.hilt": "grandfather_hilt", "zayd.blade": "rustwire_blade"},
		"inventory": ["grandfather_hilt", "rustwire_blade"],
		"money": 150, "bag": {"pink_herb": 2}, "vitals": {}, "cleared_patrols": [], "play_seconds": 12.0
	}
	check_eq(state.call("from_dict", old), "", "version 4 accepted")
	var equipment: Dictionary = state.get("equipment")
	check_eq(equipment.get(&"zayd.armor"), &"courier_jacket", "start armor courier_jacket equipped on zayd")
	check_eq(equipment.get(&"bilqis.armor"), &"rig_shawl", "start armor rig_shawl equipped on bilqis")
	var inv: Array = state.get("inventory")
	check(inv.has(&"courier_jacket") and inv.has(&"rig_shawl"), "both armors added to inventory")
	check(inv.has(&"aqiq_red"), "Red Aqiq added to inventory")
	var sockets: Dictionary = state.get("sockets")
	check_eq(sockets.get(&"grandfather_hilt"), [&"aqiq_red"], "Red Aqiq socketed in grandfather_hilt")
	var xp: Dictionary = state.get("xp")
	check_eq(xp.get(&"zayd"), 0, "zayd xp 0")
	check_eq(xp.get(&"bilqis"), 0, "bilqis xp 0")
	check_eq((state.call("to_dict") as Dictionary)["version"], 6, "saved as version 6")
	state.free()
