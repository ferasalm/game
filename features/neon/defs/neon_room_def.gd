class_name NeonRoomDef
extends Def
## One iso room (content/neon/rooms.json, docs/design/first-playable.md section 2): Feras's painted plate, the walkable
## outline and its holes, occluders cut from the plate (drawn over actors whose feet are above the baseline), the
## spawn, interactables, guard patrols, the room's encounter and the floodlight cone the fuse box kills. Plate pixels.

var plate: String = ""
var size: Vector2 = Vector2.ZERO
var walk: PackedVector2Array = PackedVector2Array()
var holes: Array[PackedVector2Array] = []
var occluders: Array[Dictionary] = []  ## {id: StringName, polygon: PackedVector2Array, baseline: float}
var spawn: Vector2 = Vector2.ZERO
var interactables: Array[Dictionary] = []  ## {id: StringName, pos: Vector2, radius: float, prompt: String}
var guards: Array[Dictionary] = []  ## {id: StringName, path: PackedVector2Array}
var encounter: StringName = &""
var floodlight: PackedVector2Array = PackedVector2Array()


func read(r: DefReader) -> void:
	id = r.id()
	plate = r.text("plate")
	size = _point(r, "size")
	walk = _points(r, "walk")
	for h: DefReader in r.optional_objects("holes"):
		holes.append(_points(h, "polygon"))
	for o: DefReader in r.optional_objects("occluders"):
		occluders.append({"id": o.id(), "polygon": _points(o, "polygon"), "baseline": o.number("baseline", 0.0, 8192.0)})
	spawn = _point(r, "spawn")
	for i: DefReader in r.optional_objects("interactables"):
		interactables.append({"id": i.id(), "pos": _point(i, "pos"), "radius": i.number("radius", 1.0, 1000.0),
			"prompt": i.text("prompt")})
	for g: DefReader in r.optional_objects("guards"):
		guards.append({"id": g.id(), "path": _points(g, "path")})
	encounter = r.id("encounter")
	floodlight = _points(r, "floodlight")


## A flat [x0, y0, x1, y1, ...] list as points (an odd count is reported).
static func _points(r: DefReader, key: String) -> PackedVector2Array:
	var flat: Array[float] = r.float_list(key, -8192.0, 8192.0)
	var out := PackedVector2Array()
	if flat.size() % 2 != 0:
		r.problem(key, "needs pairs of numbers")
		return out
	for i: int in range(0, flat.size(), 2):
		out.append(Vector2(flat[i], flat[i + 1]))
	return out


static func _point(r: DefReader, key: String) -> Vector2:
	var pts: PackedVector2Array = _points(r, key)
	if pts.size() != 1:
		r.problem(key, "needs one x, y pair")
		return Vector2.ZERO
	return pts[0]


func references() -> Array[Array]:
	return [["encounter", encounter]]
