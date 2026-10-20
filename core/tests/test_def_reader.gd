extends TestCase
## DefReader int lists and cross-key problems, and the encounter definition built on them.


func _read(data: Dictionary) -> Array:
	var errors := PackedStringArray()
	var reader := DefReader.new(data, "t", errors)
	return [reader, errors]


func test_int_list_reads_whole_numbers_in_range() -> void:
	var pair: Array = _read({"slots": [0, 2, 3.0]})
	check_eq((pair[0] as DefReader).int_list("slots", 0, 3), [0, 2, 3] as Array[int], "values")
	check_eq(pair[1], PackedStringArray(), "no problems")


func test_int_list_reports_bad_items_and_missing_lists() -> void:
	var pair: Array = _read({"slots": [1, 9, "x"], "other": 5})
	var reader := pair[0] as DefReader
	check_eq(reader.int_list("slots", 0, 3), [1] as Array[int], "only the good item is kept")
	check_eq((pair[1] as PackedStringArray).size(), 2, "one problem per bad item")
	check_eq(reader.int_list("other", 0, 3), [] as Array[int], "not a list")
	check_eq((pair[1] as PackedStringArray).size(), 3, "reported")
	check_eq(reader.int_list("absent", 0, 3), [] as Array[int], "missing key reads as empty")


func test_encounter_checks_one_slot_per_enemy() -> void:
	var errors := PackedStringArray()
	var good := EncounterDef.new()
	good.read(DefReader.new({"id": "ok", "name_key": "K", "enemies": ["a", "b"], "enemy_slots": [0, 1],
		"party_slots": [0, 2]}, "t", errors))
	check_eq(errors, PackedStringArray(), "a well-formed encounter reads clean")
	check_eq(good.references(), [["combatant", &"a"], ["combatant", &"b"]] as Array[Array], "points at its enemies")
	var bad := EncounterDef.new()
	bad.read(DefReader.new({"id": "bad", "name_key": "K", "enemies": ["a", "b"], "enemy_slots": [0],
		"party_slots": [0]}, "t", errors))
	check(errors.size() == 1 and errors[0].contains("one slot per enemy"), "slot count mismatch reported")


func test_shipped_encounter_and_rules_are_present() -> void:
	var db: Node = load("res://core/content_db.gd").new()
	db.call("load_all")
	var encounter := db.call("get_def", "encounter", &"rooftop_patrol") as EncounterDef
	var party_slots: Array[int] = [0, 2]
	check(encounter != null and encounter.enemies.size() == 3 and encounter.party_slots == party_slots, "rooftop_patrol")
	var rules := db.call("get_def", "battle_rules", &"default") as BattleRulesDef
	check(rules != null and rules.max_ticks == 20000 and rules.sp_per_act == 3, "default rules")
	db.free()
