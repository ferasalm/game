class_name RouterSaves
extends RefCounted
## Helper for Router save operations: slot checks and file I/O delegates.


static func has_save(dir: String, slot: int) -> bool:
	return SaveService.new(dir).exists(slot)


static func has_any_save(dir: String) -> bool:
	return SaveService.new(dir).has_any_save()


static func newest_slot(dir: String) -> int:
	return SaveService.new(dir).newest_slot()


static func save_slot(dir: String, slot: int) -> String:
	var service := SaveService.new(dir)
	var ok: bool = service.write(slot, GameState.to_dict())
	if ok:
		var img: Image = null
		if DisplayServer.get_name() != "headless" and Engine.get_main_loop() is SceneTree:
			var root: Viewport = (Engine.get_main_loop() as SceneTree).root
			if root != null and root.get_texture() != null:
				img = root.get_texture().get_image()
		service.write_thumbnail(slot, img)
		return ""
	return service.last_error


static func load_slot_data(dir: String, slot: int) -> Array:
	var service := SaveService.new(dir)
	var data: Dictionary = service.read(slot)
	if data.is_empty():
		var why: String = service.last_error
		data = service.read_backup(slot)
		if data.is_empty():
			return [{}, why]
		push_warning("Router: slot %d was damaged, loaded its backup" % slot)
	return [data, ""]
