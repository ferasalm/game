extends TestCase
## SaveCodec: a v3 fixture migrates to v6, unknown versions are refused, unknown content ids are dropped with
## a warning, the full v4 state (money, bag, vitals with hp 0, cleared patrols) round trips through GameState,
## and the v5 fixture gains Bilqis's pistol and every hero's ring with nothing else changed.

const FIXTURE: String = "res://core/tests/fixtures/save_v3.json"
const FIXTURE_V5: String = "res://core/tests/fixtures/save_v5.json"


func _v3() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary


func _v5() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_V5)) as Dictionary


func test_v3_fixture_migrates_to_v4() -> void:
	var result: Dictionary = SaveCodec.migrate(_v3())
	check(bool(result["ok"]), "v3 accepted")
	var data: Dictionary = result["data"]
	check_eq(data["version"], 7, "now version 7")
	check_eq((data["place"] as Dictionary)["area"], "souq_rooftops", "area_id moved into place")
	check_eq((data["place"] as Dictionary)["save_point"], "gate", "spawn_id became the save point")
	check(not data.has("area_id") and not data.has("spawn_id"), "the old keys are gone")
	check_eq(data["money"], 0, "a v3 save has no money")
	check((data["bag"] as Dictionary).is_empty() and (data["vitals"] as Dictionary).is_empty(), "no bag, vitals full")
	check_eq((data["inventory"] as Array).size(), 11, "inventory kept plus v5 and v6 start gear")


func test_unknown_versions_are_refused() -> void:
	check(not bool(SaveCodec.migrate({"version": 8})["ok"]), "future version refused")
	check(not bool(SaveCodec.migrate({})["ok"]), "no version refused")
	check_eq(SaveCodec.migrate({"version": 0})["error"], "save version 0, expected 7", "reason names both versions")


func test_unknown_ids_are_dropped_with_a_warning() -> void:
	var data: Dictionary = SaveCodec.migrate(_v3())["data"]
	data["bag"] = {"pink_herb": 2, "moon_dust": 9}
	data["vitals"] = {"rydan": {"hp": 0}, "nobody": {"hp": 5}}
	data["cleared_patrols"] = ["patrol_scouts", "lost_patrol"]
	var known: Dictionary = {
		"item": ["swift_hilt", "keen_blade", "lens_array", "grandfather_hilt", "courier_jacket", "rig_shawl",
			"aqiq_red", "rivet_frame", "rivet_barrel", "silver_band"],
		"consumable": ["pink_herb"], "hero": ["rydan", "bilqis"], "encounter": ["patrol_scouts"]}
	var warnings: PackedStringArray = SaveCodec.sanitize(data, known)
	check_eq(warnings.size(), 4, "one warning each: ghost_item, moon_dust, nobody, lost_patrol (%s)" % warnings)
	check(not (data["inventory"] as Array).has("ghost_item"), "unknown inventory item dropped")
	check_eq(data["bag"], {"pink_herb": 2}, "unknown consumable dropped")
	check((data["vitals"] as Dictionary).has("rydan") and not (data["vitals"] as Dictionary).has("nobody"), "vitals pruned")
	check_eq(data["cleared_patrols"], ["patrol_scouts"], "unknown patrol dropped")


func test_empty_known_lists_check_nothing() -> void:
	var data: Dictionary = SaveCodec.migrate(_v3())["data"]
	check(SaveCodec.sanitize(data, {}).is_empty(), "no content loaded: nothing dropped")


func test_game_state_round_trips_v4() -> void:
	var state: Node = load("res://core/game_state.gd").new()
	state.set("money", 250)
	(state.get("bag") as Dictionary)[&"pink_herb"] = 3
	(state.get("vitals") as Dictionary)[&"rydan"] = {"hp": 0, "sp": 7}
	(state.get("vitals") as Dictionary)[&"bilqis"] = {"hp": 120, "sp": 36}
	(state.get("cleared_patrols") as Array).append(&"patrol_scouts")
	state.set("area_id", &"souq_rooftops")
	state.set("save_point", &"sabil")
	state.set("play_seconds", 61.5)
	state.set("party", [&"rydan", &"bilqis"] as Array[StringName])
	var saved: String = JSON.stringify(state.call("to_dict"))
	var loaded: Node = load("res://core/game_state.gd").new()
	check_eq(loaded.call("from_dict", JSON.parse_string(saved)), "", "accepted")
	check_eq(JSON.stringify(loaded.call("to_dict")), saved, "equal after a round trip")
	check_eq((loaded.get("vitals") as Dictionary)[&"rydan"]["hp"], 0, "hp 0 survives (a downed hero)")
	check_eq(loaded.get("save_point"), &"sabil", "the save point survives")
	state.free()
	loaded.free()


func test_missing_vitals_fields_mean_full() -> void:
	var state: Node = load("res://core/game_state.gd").new()
	var data: Dictionary = SaveCodec.migrate(_v3())["data"]
	data["vitals"] = {"rydan": {"hp": 50}}
	check_eq(state.call("from_dict", data), "", "accepted")
	var entry: Dictionary = (state.get("vitals") as Dictionary)[&"rydan"]
	check(entry.has("hp") and not entry.has("sp"), "only the saved field is kept")
	check_eq(Vitals.sp_of(state.get("vitals"), &"rydan", 24), 24, "a missing sp is full")
	state.free()


func test_a_v3_fixture_loads_into_game_state_and_drops_ghosts() -> void:
	var state: Node = load("res://core/game_state.gd").new()
	check_eq(state.call("from_dict", _v3()), "", "accepted")
	check(not (state.get("inventory") as Array).has(&"ghost_item"), "unknown item dropped on load")
	check_eq((state.get("load_warnings") as PackedStringArray).size(), 1, "and reported once")
	check_eq(state.get("area_id"), &"souq_rooftops", "area restored")
	state.free()


func test_v5_fixture_migrates_to_v6_with_the_new_slots_filled() -> void:
	var result: Dictionary = SaveCodec.migrate(_v5())
	check(bool(result["ok"]), "v5 accepted")
	var data: Dictionary = result["data"]
	check_eq(data["version"], 7, "now version 7")
	var equipment: Dictionary = data["equipment"]
	check_eq(equipment["bilqis.frame"], "rivet_frame", "Bilqis wears the rivet frame")
	check_eq(equipment["bilqis.barrel"], "rivet_barrel", "and the rivet barrel")
	check_eq(equipment["rydan.accessory"], "silver_band", "Rydan wears the Common ring")
	check_eq(equipment["bilqis.accessory"], "silver_band", "and so does Bilqis")
	var owned: Array = data["inventory"]
	check(owned.has("rivet_frame") and owned.has("rivet_barrel") and owned.has("silver_band"), "start items owned")
	check_eq(owned.count("silver_band"), 1, "one ring instance in the inventory")


func test_v5_migration_changes_nothing_else() -> void:
	var before: Dictionary = _v5()
	var data: Dictionary = SaveCodec.migrate(before)["data"]
	check_eq(data["money"], before["money"], "money kept")
	check_eq(data["bag"], before["bag"], "bag kept")
	check_eq(data["vitals"], _as_v7(before["vitals"]), "vitals kept")
	check_eq(data["xp"], _as_v7(before["xp"]), "xp kept")
	check_eq(data["sockets"], before["sockets"], "hilt sockets kept")
	check_eq(data["upgrades"], before["upgrades"], "upgrades kept")
	check_eq(data["materials"], before["materials"], "materials kept")
	check_eq(data["party"], _as_v7(before["party"]), "party kept")
	check_eq(data["place"], before["place"], "place kept")
	check_eq(data["counters"], before["counters"], "counters kept")
	check_eq(data["cleared_patrols"], before["cleared_patrols"], "cleared patrols kept")
	check_eq(data["play_seconds"], before["play_seconds"], "play time kept")
	check_eq(data["flags"], before["flags"], "flags kept")
	var worn: Dictionary = _as_v7(before["equipment"])
	for slot: Variant in worn:
		check_eq((data["equipment"] as Dictionary)[slot], worn[slot], "the old slot %s kept" % slot)
	for item: Variant in (before["inventory"] as Array):
		check((data["inventory"] as Array).has(item), "still owns %s" % item)


func test_v5_fixture_names_rydan_everywhere() -> void:
	var data: Dictionary = SaveCodec.migrate(_v5())["data"]
	var text: String = JSON.stringify(data)
	check(not text.contains(String(SaveCodec.LEGACY_HERO)), "no legacy hero id left: %s" % text)
	check_eq(data["party"], ["rydan", "bilqis"], "party")
	check_eq(int(data["xp"]["rydan"]), 120, "xp")
	check_eq(int(data["vitals"]["rydan"]["hp"]), 312, "vitals")
	check_eq(data["equipment"]["rydan.hilt"], "grandfather_hilt", "worn hilt")
	var state: Node = load("res://core/game_state.gd").new()
	check_eq(state.call("from_dict", _v5()), "", "accepted")
	check(state.get("party").has(&"rydan") and state.get("xp").has(&"rydan"), "GameState names rydan")
	state.free()


## The v5 value as version 7 writes it: the legacy hero id renamed (party entries, hero keys, "<hero>." slots).
func _as_v7(value: Variant) -> Variant:
	var legacy: String = '"%s' % SaveCodec.LEGACY_HERO
	return JSON.parse_string(JSON.stringify(value).replace(legacy, '"%s' % SaveCodec.START_HERO))


func test_v5_fixture_loads_into_game_state_and_round_trips() -> void:
	var state: Node = load("res://core/game_state.gd").new()
	check_eq(state.call("from_dict", _v5()), "", "accepted")
	var equipment: Dictionary = state.get("equipment")
	check_eq(equipment.get(&"bilqis.frame"), &"rivet_frame", "frame slot filled on load")
	check_eq(equipment.get(&"bilqis.barrel"), &"rivet_barrel", "barrel slot filled on load")
	check_eq(equipment.get(&"rydan.accessory"), &"silver_band", "Rydan's ring slot filled on load")
	check_eq(equipment.get(&"bilqis.accessory"), &"silver_band", "Bilqis's ring slot filled on load")
	var saved: String = JSON.stringify(state.call("to_dict"))
	var reloaded: Node = load("res://core/game_state.gd").new()
	check_eq(reloaded.call("from_dict", JSON.parse_string(saved)), "", "saves again at version 7")
	check_eq(JSON.stringify(reloaded.call("to_dict")), saved, "same data after the round trip")
	state.free()
	reloaded.free()
