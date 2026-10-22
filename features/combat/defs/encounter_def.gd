class_name EncounterDef
extends Def
## One battle setup: which enemies stand in which formation slots, which slots the party takes, and the
## guaranteed rewards (equippable loot ids, riyal and consumables, no randomness) granted after a win, and its music.

var name_key: String = ""
var enemies: Array[StringName] = []
var enemy_slots: Array[int] = []
var party_slots: Array[int] = []
var loot: Array[StringName] = []
## Riyal paid for the first win; a repeat win pays rules.repeat_payout of it (items and herbs only the first time).
var money: int = 0
var consumables: Dictionary[StringName, int] = {}
var music: StringName = &""  ## its battle track; empty = the flow's battle_music


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	enemies = r.id_list("enemies")
	enemy_slots = r.int_list("enemy_slots", 0, 3)
	party_slots = r.int_list("party_slots", 0, 3)
	loot = r.id_list("loot")
	money = r.integer("money", 0, 9999, 0, false)
	consumables = CountMap.read(r, "consumables")
	music = StringName(r.text("music", "", false))
	if enemies.is_empty() or enemies.size() != enemy_slots.size():
		r.problem("enemy_slots", "needs one slot per enemy (and at least one enemy)")
	if party_slots.is_empty():
		r.problem("party_slots", "missing")


func references() -> Array[Array]:
	var out: Array[Array] = CountMap.references(consumables)
	for enemy_id: StringName in enemies:
		out.append(["combatant", enemy_id])
	for item_id: StringName in loot:
		out.append(["item", item_id])
	if music != &"":
		out.append(["music", music])
	return out
