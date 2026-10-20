class_name AreaDef
extends Def
## A level as data: equal-width rows of tile characters, a legend (character -> tile id) and four markers
## (S spawn, W workshop bench, P patrol start, Q patrol end) that each appear once and stand on floor.

const SPAWN: String = "S"
const WORKSHOP: String = "W"
const PATROL_START: String = "P"
const PATROL_END: String = "Q"
const MARKERS: Array[String] = ["S", "W", "P", "Q"]

var name_key: String = ""
var encounter: StringName = &""
var rows: PackedStringArray = PackedStringArray()
var legend: Dictionary[String, String] = {}


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	encounter = StringName(r.text("encounter"))
	rows = r.text_list("rows")
	legend = r.text_map("legend")


func references() -> Array[Array]:
	var out: Array[Array] = []
	for tile_id: String in legend.values():
		out.append(["tile", StringName(tile_id)])
	return out


func width() -> int:
	return rows[0].length() if not rows.is_empty() else 0


func depth() -> int:
	return rows.size()


## The tile id standing at column x, row z (empty when outside or unknown).
func tile_id_at(x: int, z: int) -> StringName:
	if z < 0 or z >= rows.size() or x < 0 or x >= rows[z].length():
		return &""
	return StringName(legend.get(rows[z][x], ""))


## Column and row of a marker, or (-1, -1) when it is missing.
func find_marker(marker: String) -> Vector2i:
	for z: int in rows.size():
		var x: int = rows[z].find(marker)
		if x >= 0:
			return Vector2i(x, z)
	return Vector2i(-1, -1)


## Every layout problem: unequal row widths, characters without a legend entry, markers not present once.
func problems() -> PackedStringArray:
	var out := PackedStringArray()
	if rows.is_empty():
		out.append("no rows")
	for z: int in rows.size():
		if rows[z].length() != width():
			out.append("row %d is %d wide, row 0 is %d" % [z, rows[z].length(), width()])
		for ch: String in rows[z]:
			if not legend.has(ch):
				out.append("row %d: '%s' is not in the legend" % [z, ch])
	for marker: String in MARKERS:
		var count: int = "".join(rows).count(marker)
		if count != 1:
			out.append("marker %s appears %d times (must be once)" % [marker, count])
	return out
