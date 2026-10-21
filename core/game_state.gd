extends Node
## Everything a save file holds (autoload GameState). Plain data only: nodes read and write it, never own it.
## to_dict()/from_dict() are the save format; bump SAVE_VERSION and add a migration when the shape changes.

const SAVE_VERSION: int = 3
## Oldest save shape still accepted; from_dict migrates it (version 1 had no equipment, version 2 no inventory).
const OLDEST_VERSION: int = 1

var flags: Dictionary[StringName, bool] = {}
## Worn gear per hero and part: &"zayd.hilt", &"zayd.blade", &"zayd.prosthetic", &"bilqis.prosthetic" ->
## content ids. A missing slot means the hero's starting gear (content/djanbeyyah/loadouts.json).
var equipment: Dictionary[StringName, StringName] = {}
## Unique items the party owns (hilts, blades, prosthetics), each id at most once (Inventory.add).
var inventory: Array[StringName] = []
var counters: Dictionary[StringName, int] = {}
var party: Array[StringName] = []
var area_id: StringName = &""
var spawn_id: StringName = &""


func reset() -> void:
	flags.clear()
	equipment.clear()
	inventory.clear()
	counters.clear()
	party.clear()
	area_id = &""
	spawn_id = &""


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"flags": flags.duplicate(),
		"equipment": equipment.duplicate(),
		"inventory": inventory.duplicate(),
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
		# Version 2 saved the djanbeyyah as "hilt" / "blade"; from version 3 slots are "<hero>.<part>".
		var key := StringName(("zayd." if version < 3 else "") + str(slot))
		equipment[key] = StringName(str(data["equipment"][slot]))
	for item: Variant in (data.get("inventory", []) as Array):
		inventory.append(StringName(str(item)))
	if version < 3:
		for worn: StringName in equipment.values():
			if not inventory.has(worn):
				inventory.append(worn)  # what a version-2 hero wears is owned
	for key: Variant in (data.get("flags", {}) as Dictionary):
		flags[StringName(str(key))] = bool(data["flags"][key])
	for key: Variant in (data.get("counters", {}) as Dictionary):
		counters[StringName(str(key))] = int(data["counters"][key])
	for member: Variant in (data.get("party", []) as Array):
		party.append(StringName(str(member)))
	area_id = StringName(str(data.get("area_id", "")))
	spawn_id = StringName(str(data.get("spawn_id", "")))
	return ""
