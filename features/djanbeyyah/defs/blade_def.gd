class_name BladeDef
extends Def
## A djanbeyyah blade: adds to attack, adds knockback to every hit the wielder lands, adds weight.

var name_key: String = ""
var desc_key: String = ""
var attack: int = 0
var knockback: int = 0
var weight: float = 0.0


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	desc_key = r.text("desc_key")
	attack = r.integer("attack", -99, 999)
	knockback = r.integer("knockback", 0, 10000)
	weight = r.number("weight", -30.0, 30.0)
