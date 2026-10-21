class_name SkylineLandmark
extends RefCounted
## One landmark placed by data: kind, position on the ground (x east, z south; the play area is x 0..26,
## z 0..18 and -Z is north), facing in degrees, main size (height or length in metres), a part count, a seed
## and a radius kept free of ordinary city blocks.

const KINDS: Array[StringName] = [&"minaret", &"gate", &"ridge", &"megacity", &"village"]

var kind: StringName = &"minaret"
var x: float = 0.0
var z: float = 0.0
var yaw: float = 0.0
var size: float = 30.0
var count: int = 1
var seed_value: int = 1
var clear_radius: float = 0.0


func read(r: DefReader) -> void:
	kind = r.one_of("kind", KINDS)
	x = r.number("x", -2000.0, 2000.0)
	z = r.number("z", -2000.0, 2000.0)
	yaw = r.number("yaw", -360.0, 360.0, 0.0, false)
	size = r.number("size", 1.0, 1000.0)
	count = r.integer("count", 1, 60, 1, false)
	seed_value = r.integer("seed", 0, 99999, 1, false)
	clear_radius = r.number("clear_radius", 0.0, 300.0, 0.0, false)


func position() -> Vector3:
	return Vector3(x, 0.0, z)
