class_name PropSplash
extends RefCounted
## Water drops a prop throws up where its stream lands (the sabil): a small burst of additive quads, drawn from
## a CPUParticles3D at `at` (prop space). Content: the "splash" object of a prop entry in content/world/props.json.

var at: Vector3 = Vector3.ZERO
var count: int = 12
var color: Color = Color("#bff0ff")
var energy: float = 2.0
var size: float = 0.05
var speed: float = 1.4
var lifetime: float = 0.55
var radius: float = 0.06
var gravity: float = 5.0


func read(r: DefReader) -> void:
	var where: Array[float] = r.float_list("at", -20.0, 20.0)
	if where.size() == 3:
		at = Vector3(where[0], where[1], where[2])
	count = r.integer("count", 1, 64, count, false)
	color = r.color("color", color, false)
	energy = r.number("energy", 0.1, 8.0, energy, false)
	size = r.number("size", 0.005, 0.5, size, false)
	speed = r.number("speed", 0.1, 8.0, speed, false)
	lifetime = r.number("lifetime", 0.1, 3.0, lifetime, false)
	radius = r.number("radius", 0.0, 1.0, radius, false)
	gravity = r.number("gravity", 0.0, 30.0, gravity, false)
