class_name PropPart
extends RefCounted
## One solid piece of a prop: a box (size = width, height, depth; at = centre) or a frustum (size = bottom radius,
## top radius, height; at = base centre), a palette letter, an optional yaw/tilt (degrees), and how it is drawn:
## glow (unshaded, boosted, blooms), blink (a glow that pulses), pattern (a painted tile texture instead of the
## letter), group (a named sub-mesh that can move, such as a chest lid).

const SHAPES: Array[StringName] = [&"box", &"frustum"]

var shape: StringName = &"box"
var at: Vector3 = Vector3.ZERO
var size: Vector3 = Vector3.ONE
var color: String = "e"
var yaw: float = 0.0
var tilt: Vector3 = Vector3.ZERO
var sides: int = 8
var glow: bool = false
var blink: bool = false
var pattern: StringName = &""
var group: StringName = &"body"


func read(r: DefReader) -> void:
	shape = StringName(r.text("shape", "box", false))
	if not SHAPES.has(shape):
		r.problem("shape", "'%s' is not one of %s" % [shape, SHAPES])
	at = _vec(r.float_list("at", -100.0, 100.0))
	size = _vec(r.float_list("size", 0.0, 100.0))
	color = r.text("color")
	yaw = r.number("yaw", -360.0, 360.0, 0.0, false)
	tilt = _vec(r.float_list("tilt", -360.0, 360.0))
	sides = r.integer("sides", 3, 16, 8, false)
	glow = r.flag("glow")
	blink = r.flag("blink")
	pattern = StringName(r.text("pattern", "", false))
	group = StringName(r.text("group", "body", false))
	if pattern != &"" and not SurfacePainter.PATTERNS.has(pattern):
		r.problem("pattern", "unknown pattern '%s'" % pattern)


func _vec(list: Array[float]) -> Vector3:
	return Vector3(list[0], list[1], list[2]) if list.size() == 3 else Vector3.ZERO
