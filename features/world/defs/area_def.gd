class_name AreaDef
extends Def
## A level as data: equal-width rows of tile characters, a legend (character -> tile id) and four markers
## (S spawn, W workshop bench, P patrol start, Q patrol end) that each appear once and stand on floor.
## Optional: mist layer ids and a vista zone (cells x0, z0, x1, z1, inclusive) where the camera shows the sky.

const SPAWN: String = "S"
const WORKSHOP: String = "W"
const PATROL_START: String = "P"
const PATROL_END: String = "Q"
const MARKERS: Array[String] = ["S", "W", "P", "Q"]

var name_key: String = ""
var encounter: StringName = &""
var rows: PackedStringArray = PackedStringArray()
var legend: Dictionary[String, String] = {}
var mist: Array[StringName] = []
## The vista zone in cells; an empty rect (size 0) means the area has none.
var vista: Rect2i = Rect2i()
## Dressing: tower-houses (ref = building id), props (ref = prop id), practical lights and neon signs.
var buildings: Array[Placement] = []
var props: Array[Placement] = []
var lights: Array[LightSpec] = []
var signs: Array[SignSpec] = []
## At most this many real OmniLights near the player; they fade in or out light_fade per second.
var light_budget: int = 8
var light_fade: float = 3.0


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	encounter = StringName(r.text("encounter"))
	rows = r.text_list("rows")
	legend = r.text_map("legend")
	mist = r.id_list("mist")
	var cells: Array[int] = r.int_list("vista", 0, 500)
	if cells.size() == 4:
		vista = Rect2i(cells[0], cells[1], cells[2] - cells[0] + 1, cells[3] - cells[1] + 1)
	elif not cells.is_empty():
		r.problem("vista", "needs 4 numbers: x0, z0, x1, z1")
	_read_dressing(r)


func references() -> Array[Array]:
	var out: Array[Array] = []
	for tile_id: String in legend.values():
		out.append(["tile", StringName(tile_id)])
	for mist_id: StringName in mist:
		out.append(["mist", mist_id])
	for b: Placement in buildings:
		out.append(["building", b.ref])
	for p: Placement in props:
		out.append(["prop", p.ref])
	return out


func _read_dressing(r: DefReader) -> void:
	light_budget = r.integer("light_budget", 0, 8, 8, false)
	light_fade = r.number("light_fade", 0.1, 20.0, 3.0, false)
	for reader: DefReader in r.optional_objects("buildings"):
		buildings.append(_placement(reader))
	for reader: DefReader in r.optional_objects("props"):
		props.append(_placement(reader))
	for reader: DefReader in r.optional_objects("lights"):
		var light := LightSpec.new()
		light.read(reader)
		lights.append(light)
	for reader: DefReader in r.optional_objects("signs"):
		var sign_spec := SignSpec.new()
		sign_spec.read(reader)
		signs.append(sign_spec)


func _placement(reader: DefReader) -> Placement:
	var out := Placement.new()
	out.read(reader)
	return out


func width() -> int:
	return rows[0].length() if not rows.is_empty() else 0


func depth() -> int:
	return rows.size()


## The vista zone on the floor plane (x, z in metres; one cell is one metre); empty when there is none.
func vista_world() -> Rect2:
	return Rect2(vista)


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
	if vista.has_area() and not Rect2i(0, 0, width(), depth()).encloses(vista):
		out.append("the vista zone sticks out of the area")
	for marker: String in MARKERS:
		var count: int = "".join(rows).count(marker)
		if count != 1:
			out.append("marker %s appears %d times (must be once)" % [marker, count])
	return out
