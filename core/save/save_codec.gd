class_name SaveCodec
extends RefCounted
## Pure save format: migrate() lifts any old save dictionary to the current version one step at a time
## (_v1_to_v2, _v2_to_v3, _v3_to_v4), and sanitize() drops content ids the game no longer knows.
## No file or node access: GameState reads and writes the result, SaveService stores it.

const VERSION: int = 5
## Oldest save shape still accepted (version 1 had no equipment, version 2 no inventory).
const OLDEST: int = 1
const START_HERO: StringName = &"zayd"


## Returns {"ok": true, "data": <version-5 dictionary>} or {"ok": false, "error": "<reason>"}.
static func migrate(raw: Dictionary) -> Dictionary:
	var version: int = int(raw.get("version", 0))
	if version < OLDEST or version > VERSION:
		return {"ok": false, "error": "save version %d, expected %d" % [version, VERSION]}
	var data: Dictionary = raw.duplicate(true)
	if version == 1:
		data = _v1_to_v2(data)
		version = 2
	if version == 2:
		data = _v2_to_v3(data)
		version = 3
	if version == 3:
		data = _v3_to_v4(data)
		version = 4
	if version == 4:
		data = _v4_to_v5(data)
	data["version"] = VERSION
	return {"ok": true, "data": data}


static func _v1_to_v2(data: Dictionary) -> Dictionary:
	data["equipment"] = {}  # version 1 saves had no equipment
	return data


## Version 2 saved the jambiyah as "hilt" / "blade"; from version 3 slots are "<hero>.<part>" and a worn item is owned.
static func _v2_to_v3(data: Dictionary) -> Dictionary:
	var equipment: Dictionary = {}
	var owned: Array = (data.get("inventory", []) as Array).duplicate()
	for slot: Variant in (data.get("equipment", {}) as Dictionary):
		var worn: String = str(data["equipment"][slot])
		equipment["%s.%s" % [START_HERO, slot]] = worn
		if not owned.has(worn):
			owned.append(worn)
	data["equipment"] = equipment
	data["inventory"] = owned
	return data


## Version 4 adds money, the consumable bag, carried vitals, the play time, patrols cleared since the last sabil
## drink and the place (area plus save point; version 3's spawn_id was never used as a place).
static func _v3_to_v4(data: Dictionary) -> Dictionary:
	data["place"] = {"area": str(data.get("area_id", "")), "save_point": str(data.get("spawn_id", ""))}
	data.erase("area_id")
	data.erase("spawn_id")
	data["money"] = 0
	data["bag"] = {}
	data["vitals"] = {}
	data["cleared_patrols"] = []
	data["play_seconds"] = 0.0
	return data


## Version 5 adds hero progression xp, hilt sockets, item upgrades, materials, and gives start armor.
static func _v4_to_v5(data: Dictionary) -> Dictionary:
	var xp: Dictionary = {}
	for member: Variant in (data.get("party", []) as Array):
		xp[str(member)] = 0
	data["xp"] = xp
	var owned: Array = (data.get("inventory", []) as Array).duplicate()
	var equipment: Dictionary = (data.get("equipment", {}) as Dictionary).duplicate()
	equipment["zayd.armor"] = "courier_jacket"
	equipment["bilqis.armor"] = "rig_shawl"
	for arm: String in ["courier_jacket", "rig_shawl", "aqiq_red"]:
		if not owned.has(arm):
			owned.append(arm)
	data["equipment"] = equipment
	data["inventory"] = owned
	data["sockets"] = {"grandfather_hilt": ["aqiq_red"]}
	data["upgrades"] = {}
	data["materials"] = {}
	return data


## Drops ids not in known and returns the problems (one line each). known maps a category to its valid ids:
## "item" (inventory, equipment values), "consumable" (bag keys), "hero" (party, vitals keys), "encounter"
## (cleared_patrols). A category that is absent or empty is not checked (content not loaded).
static func sanitize(data: Dictionary, known: Dictionary) -> PackedStringArray:
	var warnings := PackedStringArray()
	_drop_array(data, "inventory", known.get("item", []), warnings)
	_drop_array(data, "party", known.get("hero", []), warnings)
	_drop_array(data, "cleared_patrols", known.get("encounter", []), warnings)
	_drop_keys(data, "bag", known.get("consumable", []), warnings)
	_drop_keys(data, "vitals", known.get("hero", []), warnings)
	_drop_keys(data, "xp", known.get("hero", []), warnings)
	var equipment: Dictionary = data.get("equipment", {})
	var valid: Array = known.get("item", [])
	for slot: Variant in equipment.keys():
		if not valid.is_empty() and not valid.has(str(equipment[slot])):
			warnings.append("equipment %s: unknown item '%s' dropped" % [slot, equipment[slot]])
			equipment.erase(slot)
	return warnings


static func _drop_array(data: Dictionary, key: String, valid: Array, warnings: PackedStringArray) -> void:
	if valid.is_empty():
		return
	var kept: Array = []
	for entry: Variant in (data.get(key, []) as Array):
		if valid.has(str(entry)):
			kept.append(entry)
		else:
			warnings.append("%s: unknown id '%s' dropped" % [key, entry])
	data[key] = kept


static func _drop_keys(data: Dictionary, key: String, valid: Array, warnings: PackedStringArray) -> void:
	if valid.is_empty():
		return
	var table: Dictionary = data.get(key, {})
	for entry: Variant in table.keys():
		if not valid.has(str(entry)):
			warnings.append("%s: unknown id '%s' dropped" % [key, entry])
			table.erase(entry)


## The few numbers a slot list shows: {"area", "play_seconds", "money"}.
static func summary(data: Dictionary) -> Dictionary:
	var place: Dictionary = data.get("place", {})
	return {
		"area": str(place.get("area", "")),
		"play_seconds": float(data.get("play_seconds", 0.0)),
		"money": int(data.get("money", 0)),
	}
