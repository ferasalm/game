class_name ArenaDef
extends Def
## A battle arena: a floor built as a sibling of the exploring area, far from it (origin), so the fight never
## shares space with the rooftop. The party and enemies are placed around origin; look names a LookDef.

var origin: Vector3 = Vector3.ZERO
var look: StringName = &"night"
var floor_size: Vector3 = Vector3(24.0, 0.5, 24.0)
var floor_color: Color = Color(0.78, 0.7, 0.55)


func read(r: DefReader) -> void:
	id = r.id()
	origin = _vec3(r, "origin")
	floor_size = _vec3(r, "floor_size")
	look = StringName(r.text("look"))
	floor_color = r.color("floor_color")
	if floor_size.x <= 0.0 or floor_size.y <= 0.0 or floor_size.z <= 0.0:
		r.problem("floor_size", "every side must be above 0")


func references() -> Array[Array]:
	return [["look", look]]


static func _vec3(r: DefReader, key: String) -> Vector3:
	var values: Array[float] = r.float_list(key, -100000.0, 100000.0)
	if values.size() != 3:
		r.problem(key, "needs three numbers [x, y, z]")
		return Vector3.ZERO
	return Vector3(values[0], values[1], values[2])
