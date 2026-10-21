class_name MistDef
extends Def
## One drifting mist layer (content/world/mist.json): a flat transparent plane at a height, scrolling noise
## between two thresholds, faded where it meets geometry, near the camera and at the plane's edges.

var height: float = 0.0
var color: Color = Color.WHITE
var opacity: float = 0.5
## Noise tiling per metre, scroll speed in metres per second, and the noise thresholds that make patches.
var noise_scale: float = 0.1
var speed: Vector2 = Vector2.ZERO
var low: float = 0.4
var high: float = 0.8
var depth_fade: float = 0.5
var near_fade: float = 4.0
var edge_fade: float = 0.2
var margin: float = 10.0
var noise_seed: int = 1
var noise_size: int = 256
## Optional footprint in metres (x0, z0, x1, z1); empty = the whole area plus margin. A hole (same form) is a rectangle
## the mist keeps clear (the walkable roof), faded over hole_fade metres.
var rect: Rect2 = Rect2()
var hole: Rect2 = Rect2()
var hole_fade: float = 2.0
## stack planes, step metres apart upwards from height: thin sheets that read as a fog volume.
var stack: int = 1
var step: float = 0.0


func read(r: DefReader) -> void:
	id = r.id()
	height = r.number("height", -50.0, 50.0)
	color = r.color("color")
	opacity = r.number("opacity", 0.0, 1.0)
	noise_scale = r.number("noise_scale", 0.005, 5.0)
	speed = Vector2(r.number("speed_x", -5.0, 5.0), r.number("speed_z", -5.0, 5.0))
	low = r.number("low", 0.0, 1.0)
	high = r.number("high", 0.0, 1.0)
	depth_fade = r.number("depth_fade", 0.01, 20.0)
	near_fade = r.number("near_fade", 0.0, 50.0)
	edge_fade = r.number("edge_fade", 0.01, 0.5)
	margin = r.number("margin", 0.0, 100.0)
	noise_seed = r.integer("noise_seed", 0, 100000)
	noise_size = r.integer("noise_size", 32, 1024)
	if high <= low:
		r.problem("high", "must be above low")
	rect = _rect(r, "rect")
	hole = _rect(r, "hole")
	hole_fade = r.number("hole_fade", 0.1, 20.0, 2.0, false)
	stack = r.integer("stack", 1, 12, 1, false)
	step = r.number("step", 0.0, 20.0, 0.0, false)


func _rect(r: DefReader, key: String) -> Rect2:
	var v: Array[float] = r.float_list(key, -2000.0, 2000.0)
	if v.size() == 4:
		return Rect2(v[0], v[1], v[2] - v[0], v[3] - v[1])
	if not v.is_empty():
		r.problem(key, "needs 4 numbers: x0, z0, x1, z1")
	return Rect2()
