class_name SaveService
extends RefCounted
## Save slots on disk: <dir>/slot_N.json, written atomically (tmp file, then rename over the old one, with the
## previous save kept as slot_N.json.bak). Stores plain dictionaries; SaveCodec gives them their meaning.
## `dir` is a constructor argument so tests write somewhere else than the player's saves.

const DEFAULT_DIR: String = "user://saves"
const SLOT_COUNT: int = 3

var dir: String
## Why the last write or read failed ("" after a success).
var last_error: String = ""


func _init(base_dir: String = DEFAULT_DIR) -> void:
	dir = base_dir


func path_for(slot: int) -> String:
	return dir.path_join("slot_%d.json" % slot)


func exists(slot: int) -> bool:
	return FileAccess.file_exists(path_for(slot))


## Writes the dictionary as the slot's new save. Returns true on success; false sets last_error and leaves the
## old save untouched.
func write(slot: int, data: Dictionary) -> bool:
	last_error = ""
	var path: String = path_for(slot)
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		return _fail("cannot create the save folder '%s'" % dir)
	var tmp: String = path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return _fail("cannot write '%s' (error %d)" % [tmp, FileAccess.get_open_error()])
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if exists(slot) and DirAccess.copy_absolute(path, path + ".bak") != OK:
		return _fail("cannot keep a backup of '%s'" % path)
	if DirAccess.rename_absolute(tmp, path) != OK:
		return _fail("cannot move the new save over '%s'" % path)
	return true


## The slot's saved dictionary, or {} with last_error set (missing file, unreadable or corrupt JSON, not an object).
func read(slot: int) -> Dictionary:
	last_error = ""
	if not exists(slot):
		_fail("slot %d has no save" % slot)
		return {}
	return _parse(path_for(slot), "slot %d" % slot)


## The previous save of the slot (slot_N.json.bak), for when the current one is corrupt.
func read_backup(slot: int) -> Dictionary:
	last_error = ""
	if not FileAccess.file_exists(path_for(slot) + ".bak"):
		_fail("slot %d has no backup" % slot)
		return {}
	return _parse(path_for(slot) + ".bak", "backup of slot %d" % slot)


## {"area", "play_seconds", "money"} of the slot, or {} when it is empty or unreadable.
func summary(slot: int) -> Dictionary:
	var data: Dictionary = read(slot)
	return SaveCodec.summary(data) if not data.is_empty() else {}


func delete(slot: int) -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path_for(slot) + suffix):
			DirAccess.remove_absolute(path_for(slot) + suffix)


func _parse(path: String, label: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		_fail("%s is corrupt (line %d: %s)" % [label, json.get_error_line(), json.get_error_message()])
		return {}
	if not (json.data is Dictionary):
		_fail("%s is not a save (not a JSON object)" % label)
		return {}
	return json.data as Dictionary


func _fail(reason: String) -> bool:
	last_error = reason
	return false
