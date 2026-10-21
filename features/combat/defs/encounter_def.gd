class_name EncounterDef
extends Def
## One battle setup: which enemies stand in which formation slots, which slots the party takes, and the
## guaranteed loot (item ids, no randomness) granted after a win.

var name_key: String = ""
var enemies: Array[StringName] = []
var enemy_slots: Array[int] = []
var party_slots: Array[int] = []
var loot: Array[StringName] = []


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	enemies = r.id_list("enemies")
	enemy_slots = r.int_list("enemy_slots", 0, 3)
	party_slots = r.int_list("party_slots", 0, 3)
	loot = r.id_list("loot")
	if enemies.is_empty() or enemies.size() != enemy_slots.size():
		r.problem("enemy_slots", "needs one slot per enemy (and at least one enemy)")
	if party_slots.is_empty():
		r.problem("party_slots", "missing")


func references() -> Array[Array]:
	var out: Array[Array] = []
	for enemy_id: StringName in enemies:
		out.append(["combatant", enemy_id])
	for item_id: StringName in loot:
		out.append(["item", item_id])
	return out
