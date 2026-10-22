class_name BladeDef
extends EquipDef
## A jambiyah blade: adds to attack, adds knockback to every hit the wielder lands, adds weight.

var attack: int = 0
var knockback: int = 0
var weight: float = 0.0


func read(r: DefReader) -> void:
	read_gear(r)
	attack = r.integer("attack", -99, 999)
	knockback = r.integer("knockback", 0, 10000)
	weight = r.number("weight", -30.0, 30.0)


func references() -> Array[Array]:
	return gear_references()
