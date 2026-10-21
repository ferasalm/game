class_name Vitals
extends RefCounted
## Carried HP and SP per hero: {hero id: {"hp": int, "sp": int}}. A hero with no entry (or a missing field) is at
## full; hp 0 is allowed (a downed hero). Pure helpers over a plain dictionary (GameState.vitals, a battle's
## start/after vitals).


static func hp_of(vitals: Dictionary, hero: StringName, max_hp: int) -> int:
	var entry: Dictionary = vitals.get(hero, {})
	return clampi(int(entry.get("hp", max_hp)), 0, max_hp)


static func sp_of(vitals: Dictionary, hero: StringName, max_sp: int) -> int:
	var entry: Dictionary = vitals.get(hero, {})
	return clampi(int(entry.get("sp", max_sp)), 0, max_sp)


static func store(vitals: Dictionary, hero: StringName, hp: int, sp: int) -> void:
	vitals[hero] = {"hp": hp, "sp": sp}


## A deep copy that is safe to hand to a battle or keep as a retry snapshot.
static func copy(vitals: Dictionary) -> Dictionary:
	return vitals.duplicate(true)


## Everybody back to full (the sabil): an empty dictionary means full.
static func refill(vitals: Dictionary) -> void:
	vitals.clear()


## Current values never exceed the new maxima (a gear change lowers the maximum; it never raises the current).
static func clamp_to(vitals: Dictionary, hero: StringName, max_hp: int, max_sp: int) -> void:
	if vitals.has(hero):
		store(vitals, hero, hp_of(vitals, hero, max_hp), sp_of(vitals, hero, max_sp))
