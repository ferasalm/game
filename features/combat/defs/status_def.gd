class_name StatusDef
extends Def
## One status effect: how long it lasts and how it changes timeline speed and interrupt immunity.

var name_key: String = ""
var turns: int = 1
var wait_speed: float = 1.0
var cast_speed: float = 1.0
var interrupt_immune: bool = false


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	turns = r.integer("turns", 1, 99)
	wait_speed = r.number("wait_speed", 0.1, 5.0, 1.0, false)
	cast_speed = r.number("cast_speed", 0.1, 5.0, 1.0, false)
	interrupt_immune = r.flag("interrupt_immune")
