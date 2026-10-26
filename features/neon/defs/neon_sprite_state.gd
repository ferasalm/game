class_name NeonSpriteState
extends RefCounted
## One state of a NeonSpriteSetDef: the sheet (8 direction rows x frames), frame size, the feet pivot inside a frame,
## playback speed, whether it loops, and the frame on which an attack or cast lands (-1 = none).

var state: StringName = &""
var sheet: String = ""
var frame_size: Vector2i = Vector2i.ZERO
var frames: int = 1
var fps: float = 10.0
var loop: bool = false
var pivot: Vector2 = Vector2.ZERO
var impact: int = -1


func read(r: DefReader) -> void:
	state = r.id("state")
	sheet = r.text("sheet")
	frame_size = Vector2i(r.integer("frame_w", 1, 1024), r.integer("frame_h", 1, 1024))
	frames = r.integer("frames", 1, 64)
	fps = r.number("fps", 0.5, 60.0)
	loop = r.flag("loop")
	var p: Array[float] = r.float_list("pivot", 0.0, 1024.0)
	if p.size() == 2:
		pivot = Vector2(p[0], p[1])
	else:
		r.problem("pivot", "needs two numbers")
	impact = r.integer("impact", -1, 63, -1, false)


## Seconds the state takes once through.
func duration() -> float:
	return float(frames) / fps
