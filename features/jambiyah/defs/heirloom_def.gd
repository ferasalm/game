class_name HeirloomDef
extends Def
## Maps heirloom restoration rank to open stone slots and story flags (content/jambiyah/heirloom.json).

var rank: int = 1
var slots: int = 1
var flag: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	rank = r.integer("rank", 1, 10, 1, false)
	slots = r.integer("slots", 1, 10, 1, false)
	flag = StringName(r.text("flag", "", false))
