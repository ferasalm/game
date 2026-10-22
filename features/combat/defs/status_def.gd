class_name StatusDef
extends Def
## One status effect: how long it lasts and how it changes timeline speed, interrupt immunity and the
## damage the afflicted unit takes (guarded: 0.6 means 40% less).

var name_key: String = ""
var turns: int = 1
var wait_speed: float = 1.0
var cast_speed: float = 1.0
var interrupt_immune: bool = false
var damage_taken: float = 1.0
var miss_chance: float = 0.0


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	turns = r.integer("turns", 1, 99)
	wait_speed = r.number("wait_speed", 0.1, 5.0, 1.0, false)
	cast_speed = r.number("cast_speed", 0.1, 5.0, 1.0, false)
	interrupt_immune = r.flag("interrupt_immune")
	damage_taken = r.number("damage_taken", 0.1, 5.0, 1.0, false)
	miss_chance = r.number("miss_chance", 0.0, 1.0, 0.0, false)
