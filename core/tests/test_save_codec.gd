extends TestCase
## SaveCodec: a v3 fixture migrates to v4, unknown versions are refused, unknown content ids are dropped with a
## warning, and the full v4 state (money, bag, vitals with hp 0, cleared patrols) round trips through GameState.

const FIXTURE: String = "res://core/tests/fixtures/save_v3.json"


func _v3() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary


func test_v3_fixture_migrates_to_v4() -> void:
	var result: Dictionary = SaveCodec.migrate(_v3())
	check(bool(result["ok"]), "v3 accepted")
	var data: Dictionary = result["data"]
	check_eq(data["version"], 4, "now version 4")
	check_eq((data["place"] as Dictionary)["area"], "souq_rooftops", "area_id moved into place")
	check_eq((data["place"] as Dictionary)["save_point"], "gate", "spawn_id became the save point")
	check(not data.has("area_id") and not data.has("spawn_id"), "the old keys are gone")
	check_eq(data["money"], 0, "a v3 save has no money")
	check((data["bag"] as Dictionary).is_empty() and (data["vitals"] as Dictionary).is_empty(), "no bag, vitals full")
	check_eq((data["inventory"] as Array).size(), 5, "inventory kept")


func test_unknown_versions_are_refused() -> void:
	check(not bool(SaveCodec.migrate({"version": 5})["ok"]), "future version refused")
	check(not bool(SaveCodec.migrate({})["ok"]), "no version refused")
	check_eq(SaveCodec.migrate({"version": 0})["error"], "save version 0, expected 4", "reason names both versions")


func test_unknown_ids_are_dropped_with_a_warning() -> void:
	var data: Dictionary = SaveCodec.migrate(_v3())["data"]
	data["bag"] = {"pink_herb": 2, "moon_dust": 9}
	data["vitals"] = {"zayd": {"hp": 0}, "nobody": {"hp": 5}}
	data["cleared_patrols"] = ["patrol_scouts", "lost_patrol"]
	var known: Dictionary = {
		"item": ["swift_hilt", "keen_blade", "lens_array", "grandfather_hilt"], "consumable": ["pink_herb"],
		"hero": ["zayd", "bilqis"], "encounter": ["patrol_scouts"]}
	var warnings: PackedStringArray = SaveCodec.sanitize(data, known)
	check_eq(warnings.size(), 4, "one warning each: ghost_item, moon_dust, nobody, lost_patrol (%s)" % warnings)
	check(not (data["inventory"] as Array).has("ghost_item"), "unknown inventory item dropped")
	check_eq(data["bag"], {"pink_herb": 2}, "unknown consumable dropped")
	check((data["vitals"] as Dictionary).has("zayd") and not (data["vitals"] as Dictionary).has("nobody"), "vitals pruned")
	check_eq(data["cleared_patrols"], ["patrol_scouts"], "unknown patrol dropped")


func test_empty_known_lists_check_nothing() -> void:
	var data: Dictionary = SaveCodec.migrate(_v3())["data"]
	check(SaveCodec.sanitize(data, {}).is_empty(), "no content loaded: nothing dropped")


func test_game_state_round_trips_v4() -> void:
	var state: Node = load("res://core/game_state.gd").new()
	state.set("money", 250)
	(state.get("bag") as Dictionary)[&"pink_herb"] = 3
	(state.get("vitals") as Dictionary)[&"zayd"] = {"hp": 0, "sp": 7}
	(state.get("vitals") as Dictionary)[&"bilqis"] = {"hp": 120, "sp": 36}
	(state.get("cleared_patrols") as Array).append(&"patrol_scouts")
	state.set("area_id", &"souq_rooftops")
	state.set("save_point", &"sabil")
	state.set("play_seconds", 61.5)
	state.set("party", [&"zayd", &"bilqis"] as Array[StringName])
	var saved: String = JSON.stringify(state.call("to_dict"))
	var loaded: Node = load("res://core/game_state.gd").new()
	check_eq(loaded.call("from_dict", JSON.parse_string(saved)), "", "accepted")
	check_eq(JSON.stringify(loaded.call("to_dict")), saved, "equal after a round trip")
	check_eq((loaded.get("vitals") as Dictionary)[&"zayd"]["hp"], 0, "hp 0 survives (a downed hero)")
	check_eq(loaded.get("save_point"), &"sabil", "the save point survives")
	state.free()
	loaded.free()


func test_missing_vitals_fields_mean_full() -> void:
	var state: Node = load("res://core/game_state.gd").new()
	var data: Dictionary = SaveCodec.migrate(_v3())["data"]
	data["vitals"] = {"zayd": {"hp": 50}}
	check_eq(state.call("from_dict", data), "", "accepted")
	var entry: Dictionary = (state.get("vitals") as Dictionary)[&"zayd"]
	check(entry.has("hp") and not entry.has("sp"), "only the saved field is kept")
	check_eq(Vitals.sp_of(state.get("vitals"), &"zayd", 24), 24, "a missing sp is full")
	state.free()


func test_a_v3_fixture_loads_into_game_state_and_drops_ghosts() -> void:
	var state: Node = load("res://core/game_state.gd").new()
	check_eq(state.call("from_dict", _v3()), "", "accepted")
	check(not (state.get("inventory") as Array).has(&"ghost_item"), "unknown item dropped on load")
	check_eq((state.get("load_warnings") as PackedStringArray).size(), 1, "and reported once")
	check_eq(state.get("area_id"), &"souq_rooftops", "area restored")
	state.free()
