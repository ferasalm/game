class_name SkylineBand
extends RefCounted
## One depth band of the skyline: city blocks on a jittered grid between min_dist and max_dist metres from the
## play area's edge. A "detailed" band uses tower-house buildings; a "far" band uses unshaded dotted boxes.

const KINDS: Array[StringName] = [&"detailed", &"far"]

var id: StringName = &""
var kind: StringName = &"detailed"
var min_dist: float = 0.0
var max_dist: float = 0.0
var cell: float = 9.0
var fill: float = 0.8
var building_ids: Array[StringName] = []
var width_range: Vector2 = Vector2(6.0, 12.0)
var height_range: Vector2 = Vector2(15.0, 40.0)


func read(r: DefReader) -> void:
	id = r.id()
	kind = r.one_of("kind", KINDS)
	min_dist = r.number("min_dist", 0.0, 500.0)
	max_dist = r.number("max_dist", 1.0, 800.0)
	cell = r.number("cell", 4.0, 60.0)
	fill = r.number("fill", 0.0, 1.0)
	building_ids = r.id_list("building_ids")
	width_range = Vector2(r.number("width_min", 1.0, 60.0, 6.0, false), r.number("width_max", 1.0, 60.0, 12.0, false))
	height_range = Vector2(r.number("height_min", 1.0, 400.0, 15.0, false), r.number("height_max", 1.0, 400.0, 40.0, false))
	if max_dist <= min_dist:
		r.problem("max_dist", "must be larger than min_dist")
	if kind == &"detailed" and building_ids.is_empty():
		r.problem("building_ids", "a detailed band needs buildings")
