extends Node
## Everything a save file holds (autoload GameState). Plain data only: nodes read and write it, never own it.
## to_dict()/from_dict() are the save format; bump SAVE_VERSION and add a migration when the shape changes.

const SAVE_VERSION: int = 2
## Oldest save shape still accepted; from_dict migrates it (version 1 had no equipment).
const OLDEST_VERSION: int = 1

var flags: Dictionary[StringName, bool] = {}
## Worn djanbeyyah parts: &"hilt" and &"blade" -> content ids. Empty means the starting pair.
var equipment: Dictionary[StringName, StringName] = {}
var counters: Dictionary[StringName, int] = {}
var party: Array[StringName] = []
var area_id: StringName = &""
var spawn_id: StringName = &""


func reset() -> void:
	flags.clear()
	equipment.clear()
	counters.clear()
	party.clear()
	area_id = &""
	spawn_id = &""


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"flags": flags.duplicate(),
		"equipment": equipment.duplicate(),
		"counters": counters.duplicate(),
		"party": party.duplicate(),
		"area_id": String(area_id),
		"spawn_id": String(spawn_id),
	}


## Returns "" on success, else the reason the data was refused (the state is then unchanged).
func from_dict(data: Dictionary) -> String:
	var version: int = int(data.get("version", 0))
	if version < OLDEST_VERSION or version > SAVE_VERSION:
		return "save version %d, expected %d" % [version, SAVE_VERSION]
	reset()
	for slot: Variant in (data.get("equipment", {}) as Dictionary):
		equipment[StringName(str(slot))] = StringName(str(data["equipment"][slot]))
	for key: Variant in (data.get("flags", {}) as Dictionary):
		flags[StringName(str(key))] = bool(data["flags"][key])
	for key: Variant in (data.get("counters", {}) as Dictionary):
		counters[StringName(str(key))] = int(data["counters"][key])
	for member: Variant in (data.get("party", []) as Array):
		party.append(StringName(str(member)))
	area_id = StringName(str(data.get("area_id", "")))
	spawn_id = StringName(str(data.get("spawn_id", "")))
	return ""
