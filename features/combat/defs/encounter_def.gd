class_name EncounterDef
extends Def
## One battle setup: which enemies stand in which formation slots, and which slots the party takes.

var name_key: String = ""
var enemies: Array[StringName] = []
var enemy_slots: Array[int] = []
var party_slots: Array[int] = []


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	enemies = r.id_list("enemies")
	enemy_slots = r.int_list("enemy_slots", 0, 3)
	party_slots = r.int_list("party_slots", 0, 3)
	if enemies.is_empty() or enemies.size() != enemy_slots.size():
		r.problem("enemy_slots", "needs one slot per enemy (and at least one enemy)")
	if party_slots.is_empty():
		r.problem("party_slots", "missing")


func references() -> Array[Array]:
	var out: Array[Array] = []
	for enemy_id: StringName in enemies:
		out.append(["combatant", enemy_id])
	return out
