class_name Placement
extends RefCounted
## Where one building or prop stands in an area: the content id (ref), an optional name for it (chests), the
## position (x, z on the floor; y absolute, or the floor height when absent) and a yaw in degrees.

var ref: StringName = &""
var name: StringName = &""
var pos: Vector3 = Vector3.ZERO
var has_y: bool = false
var yaw: float = 0.0


func read(r: DefReader) -> void:
	ref = StringName(r.text("ref"))
	name = StringName(r.text("id", "", false))
	has_y = r.has("y")
	pos = Vector3(r.number("x", -500.0, 500.0), r.number("y", -50.0, 100.0, 0.0, false), r.number("z", -500.0, 500.0))
	yaw = r.number("yaw", -360.0, 360.0, 0.0, false)
