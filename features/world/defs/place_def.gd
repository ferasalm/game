class_name PlaceDef
extends Def
## Stub (v0.3 registry, filled by the level builder): a named spot in an area (sabil, stall, workshop, vista) at a
## grid cell, so code finds it by id instead of by node path.

var area: StringName = &""
var kind: StringName = &""
var cell: Vector2i = Vector2i.ZERO


func read(r: DefReader) -> void:
	id = r.id()
	area = StringName(r.text("area", "", false))
	kind = StringName(r.text("kind", "", false))
	var cells: Array[int] = r.int_list("cell", -1000, 1000)
	if cells.size() == 2:
		cell = Vector2i(cells[0], cells[1])
