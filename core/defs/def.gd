class_name Def
extends RefCounted
## Base of every content definition: an id, how it reads itself from JSON, and which other ids it needs.
## Definitions are read-only after loading; anything that changes during play lives in a state object.

var id: StringName = &""


func read(_r: DefReader) -> void:
	pass


## Other definitions this one points to, as [kind, id] pairs, so ContentDB can report dangling ids.
func references() -> Array[Array]:
	return []


## An optional [x, y] list as a Vector2 (zero when absent; a problem when it is not two numbers).
static func vec2(r: DefReader, key: String) -> Vector2:
	if not r.has(key):
		return Vector2.ZERO
	var v: Array[float] = r.float_list(key, -1000.0, 1000.0)
	if v.size() != 2:
		r.problem(key, "not 2 numbers")
		return Vector2.ZERO
	return Vector2(v[0], v[1])


## An optional [x, y, z] list as a Vector3 (zero when absent; a problem when it is not three numbers).
static func vec3(r: DefReader, key: String) -> Vector3:
	if not r.has(key):
		return Vector3.ZERO
	var v: Array[float] = r.float_list(key, -1000.0, 1000.0)
	if v.size() != 3:
		r.problem(key, "not 3 numbers")
		return Vector3.ZERO
	return Vector3(v[0], v[1], v[2])
