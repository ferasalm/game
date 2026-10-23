class_name FocusShotDef
extends Def
## purpose: Defines camera framing parameters for spot interaction focus zooms.

var offset: Vector3 = Vector3.ZERO
var look_at: Vector3 = Vector3.ZERO
var fov: float = 40.0


func read(r: DefReader) -> void:
	id = r.id()
	offset = _vec(r.float_list("offset", -100.0, 100.0))
	look_at = _vec(r.float_list("look_at", -100.0, 100.0))
	fov = r.number("fov", 10.0, 120.0, 40.0, false)


func _vec(list: Array[float]) -> Vector3:
	return Vector3(list[0], list[1], list[2]) if list.size() == 3 else Vector3.ZERO
