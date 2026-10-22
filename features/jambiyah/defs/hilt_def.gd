class_name HiltDef
extends EquipDef
## A jambiyah hilt: adds to agility, multiplies cast speed, adds weight, and grants exactly one move.

var agility: int = 0
var cast_speed: float = 1.0
var weight: float = 0.0
var ability: StringName = &""


func read(r: DefReader) -> void:
	read_gear(r)
	agility = r.integer("agility", -50, 50)
	cast_speed = r.number("cast_speed", CombatantDef.CAST_SPEED_MIN, CombatantDef.CAST_SPEED_MAX)
	weight = r.number("weight", -30.0, 30.0)
	ability = r.id("ability")


func references() -> Array[Array]:
	var out: Array[Array] = gear_references()
	out.append(["action", ability])
	return out
