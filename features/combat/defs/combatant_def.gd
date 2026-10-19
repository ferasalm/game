class_name CombatantDef
extends Def
## One kind of fighter (a party member or an enemy type): base stats and the actions it can use.
## Several enemies can share one CombatantDef; each gets its own UnitState in battle.

var name_key: String = ""
var max_hp: int = 1
var max_sp: int = 0
var attack: int = 0
var defense: int = 0
var agility: int = 1
var weight: float = 0.0
var interrupt_resist: float = 0.0
var actions: Array[StringName] = []


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	max_hp = r.integer("max_hp", 1, 99999)
	max_sp = r.integer("max_sp", 0, 999)
	attack = r.integer("attack", 0, 999)
	defense = r.integer("defense", 0, 999)
	agility = r.integer("agility", 1, 99)
	weight = r.number("weight", 0.0, 30.0)
	interrupt_resist = r.number("interrupt_resist", 0.0, 0.9, 0.0, false)
	actions = r.id_list("actions")


func references() -> Array[Array]:
	var out: Array[Array] = []
	for action_id: StringName in actions:
		out.append(["action", action_id])
	return out
