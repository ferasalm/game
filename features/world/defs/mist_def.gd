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


func read(r: DefReader) -> void:
	id = r.id()
	height = r.number("height", -5.0, 50.0)
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
