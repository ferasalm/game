extends TestCase
## SaveService: round trip, summary, an existing slot is replaced (the rename overwrites on Windows too) with
## the old save kept as .bak, and corrupt files give a clear error.

func _dir() -> String:
	return SaveService.default_dir.path_join("service")


func _service() -> SaveService:
	var service := SaveService.new(_dir())
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


func test_a_relative_save_folder_is_refused() -> void:
	var service := SaveService.new("relative_save_probe/deeper")
	check(not service.write(1, _data(10)), "a relative folder is not written")
	check(service.last_error.contains("user://"), "the error says why (%s)" % service.last_error)
	check(not service.write_thumbnail(1), "nor is a thumbnail")
	check(not DirAccess.dir_exists_absolute("relative_save_probe"), "nothing lands in the working directory")


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
	DirAccess.make_dir_recursive_absolute(_dir())
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


func test_two_different_res_paths_give_two_different_folders() -> void:
	var dir_a: String = SaveService.test_dir_for("res://checkout_a")
	var dir_b: String = SaveService.test_dir_for("res://checkout_b")
	check(dir_a != dir_b, "different res paths give different folders")
	check(dir_a.begins_with("user://test_saves/"), "under user://test_saves/: " + dir_a)
	check(dir_b.begins_with("user://test_saves/"), "under user://test_saves/: " + dir_b)


func test_newest_slot_and_has_any_save() -> void:
	var service: SaveService = _service()
	check(not service.has_any_save(), "no saves at start")
	check(service.write(1, _data(100)), "slot 1 written")
	check(service.has_any_save(), "has save now")
	check_eq(service.newest_slot(), 1, "slot 1 is newest")
	check(service.write(2, _data(200)), "slot 2 written later")
	check_eq(service.newest_slot(), 2, "slot 2 is now newest")
	service.delete(1)
	service.delete(2)


func test_old_slot_1_loads_as_slot_1() -> void:
	var service: SaveService = _service()
	Router.save_dir = _dir()
	Router.scene_reloader = func() -> void: pass
	var old_save: Dictionary = {
		"version": 3,
		"area_id": "souq_rooftops",
		"spawn_id": "sabil",
		"inventory": []
	}
	check(service.write(1, old_save), "wrote legacy slot 1")
	var problem: String = Router.load_slot(1)
	check(problem.is_empty(), "slot 1 loaded without error")
	check_eq(Router.last_slot, 1, "Router.last_slot is 1")
	check_eq(String(GameState.area_id), "souq_rooftops", "area restored")
	service.delete(1)
	Router.save_dir = ""
	Router.scene_reloader = Callable()
