extends TestCase
## SaveService: round trip, summary, an existing slot is replaced (the rename overwrites on Windows too) with
## the old save kept as .bak, and corrupt files give a clear error.

const DIR: String = "user://test_saves_service"


func _service() -> SaveService:
	var service := SaveService.new(DIR)
	for slot: int in [1, 2]:
		service.delete(slot)
	return service


func _data(money: int) -> Dictionary:
	return {"version": 4, "money": money, "play_seconds": 12.5, "place": {"area": "souq_rooftops", "save_point": ""}}


func test_round_trip_and_summary() -> void:
	var service: SaveService = _service()
	check(not service.exists(1), "no save yet")
	check(service.write(1, _data(80)), "written (%s)" % service.last_error)
	check(service.exists(1), "the slot exists")
	var back: Dictionary = service.read(1)
	check(int(back["money"]) == 80 and int(back["version"]) == 4 and back["play_seconds"] == 12.5, "same data back")
	var summary: Dictionary = service.summary(1)
	check_eq(summary, {"area": "souq_rooftops", "play_seconds": 12.5, "money": 80}, "slot summary")
	service.delete(1)


func test_writing_again_overwrites_and_keeps_a_backup() -> void:
	var service: SaveService = _service()
	check(service.write(1, _data(10)), "first write")
	check(service.write(1, _data(20)), "second write over the first (%s)" % service.last_error)
	check_eq(int(service.read(1)["money"]), 20, "the new save is in the slot")
	check_eq(int(service.read_backup(1)["money"]), 10, "the old save is the .bak")
	check(not FileAccess.file_exists(service.path_for(1) + ".tmp"), "no tmp file left behind")
	service.delete(1)


func test_missing_slot_and_corrupt_json_give_clear_errors() -> void:
	var service: SaveService = _service()
	check(service.read(2).is_empty(), "an empty slot reads as {}")
	check_eq(service.last_error, "slot 2 has no save", "and says why")
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open(service.path_for(2), FileAccess.WRITE)
	file.store_string("{\"version\": 4, \"money\": ")
	file.close()
	check(service.read(2).is_empty(), "a truncated file reads as {}")
	check(service.last_error.begins_with("slot 2 is corrupt"), "named corrupt: " + service.last_error)
	check(service.summary(2).is_empty(), "no summary for a corrupt slot")
	file = FileAccess.open(service.path_for(2), FileAccess.WRITE)
	file.store_string("[1, 2]")
	file.close()
	check(service.read(2).is_empty() and service.last_error.contains("not a save"), "an array is not a save")
	service.delete(2)
