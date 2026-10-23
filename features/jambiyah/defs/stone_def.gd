class_name StoneDef
extends EquipDef
## A gemstone socketed into a jambiyah hilt (content/jambiyah/stones.json).
## Grants stats or a passive perk (docs/design/hilt-stones.md).

var flavour_key: String = ""
var price: int = 0
var stats: Dictionary[StringName, int] = {}


func read(r: DefReader) -> void:
	read_gear(r)
	flavour_key = r.text("flavour_key", "", false)
	price = r.integer("price", 0, 9999, 0, false)
	stats.clear()
	if r.has("stats"):
		var s: DefReader = r.child("stats")
		for k: String in ["max_hp", "max_sp", "attack", "defense", "agility", "hp", "sp"]:
			if s.has(k):
				stats[StringName(k)] = s.integer(k, -999, 999, 0, false)


func perk_problem(_tier: RarityDef) -> String:
	return ""


func references() -> Array[Array]:
	return gear_references()
