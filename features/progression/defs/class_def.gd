class_name ClassDef
extends Def
## A hero's RPG class: growth stats added per level above 1 and a passive perk (content/progression/classes.json).

var name_key: String = ""
var desc_key: String = ""
var hero: StringName = &""
var growth: Dictionary[StringName, int] = {}
var passive: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	desc_key = r.text("desc_key")
	hero = r.id("hero")
	passive = r.id("passive")
	growth.clear()
	if r.has("growth"):
		var g: DefReader = r.child("growth")
		growth[&"max_hp"] = g.integer("max_hp", 0, 999, 0, false)
		growth[&"max_sp"] = g.integer("max_sp", 0, 999, 0, false)
		growth[&"attack"] = g.integer("attack", 0, 999, 0, false)
		growth[&"defense"] = g.integer("defense", 0, 999, 0, false)
		growth[&"agility"] = g.integer("agility", 0, 999, 0, false)
		growth[&"luck"] = g.integer("luck", 0, 999, 0, false)


func references() -> Array[Array]:
	return [["combatant", hero], ["perk", passive]]
