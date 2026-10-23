class_name PuzzleDefCoords
extends RefCounted
## purpose: Typed optional [x, y] and [x, y, z] reads used by the puzzle definitions.


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
