class_name CombatantDef
extends Def
## One kind of fighter (a party member or an enemy type): base stats and the actions it can use.
## Several enemies can share one CombatantDef; each gets its own UnitState in battle.

const AGILITY_MIN: int = 1
const AGILITY_MAX: int = 99
const CAST_SPEED_MIN: float = 0.5
const CAST_SPEED_MAX: float = 2.0

var name_key: String = ""
var max_hp: int = 1
var max_sp: int = 0
var attack: int = 0
var defense: int = 0
var agility: int = 1
var weight: float = 0.0
var interrupt_resist: float = 0.0
## Multiplies every move's cast speed (the djanbeyyah hilt sets it).
var cast_speed: float = 1.0
## Added to the knockback of every hit this fighter lands (the djanbeyyah blade sets it).
var knockback_bonus: int = 0
var actions: Array[StringName] = []


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	max_hp = r.integer("max_hp", 1, 99999)
	max_sp = r.integer("max_sp", 0, 999)
	attack = r.integer("attack", 0, 999)
	defense = r.integer("defense", 0, 999)
	agility = r.integer("agility", AGILITY_MIN, AGILITY_MAX)
	weight = r.number("weight", 0.0, 30.0)
	interrupt_resist = r.number("interrupt_resist", 0.0, 0.9, 0.0, false)
	cast_speed = r.number("cast_speed", CAST_SPEED_MIN, CAST_SPEED_MAX, 1.0, false)
	knockback_bonus = r.integer("knockback_bonus", 0, 10000, 0, false)
	actions = r.id_list("actions")


func references() -> Array[Array]:
	var out: Array[Array] = []
	for action_id: StringName in actions:
		out.append(["action", action_id])
	return out
