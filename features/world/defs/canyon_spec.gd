class_name CanyonSpec
extends RefCounted
## The sunken street (al-Saila) under the area: two walls from bottom_y up to top_y between x0 and x1 (the street's
## width) over the area's z range z0..z1, continued extend metres beyond both ends up to ext_top_y only, with a
## stone base of base_height under a brick upper wall and a thin water channel down the middle.

var x0: float = 17.0
var x1: float = 19.0
var z0: float = 0.0
var z1: float = 18.0
var bottom_y: float = -18.0
var top_y: float = 0.0
var ext_top_y: float = -4.0
var extend: float = 24.0
var base_height: float = 7.0
var wall_pattern: StringName = &"brick"
var base_pattern: StringName = &"basalt"
var channel_width: float = 0.3
var channel_color: Color = Color.WHITE
var channel_glow: float = 0.6


func read(r: DefReader) -> void:
	x0 = r.number("x0", -500.0, 500.0)
	x1 = r.number("x1", -500.0, 500.0)
	z0 = r.number("z0", -500.0, 500.0)
	z1 = r.number("z1", -500.0, 500.0)
	bottom_y = r.number("bottom_y", -100.0, 0.0)
	top_y = r.number("top_y", -50.0, 50.0)
	ext_top_y = r.number("ext_top_y", -100.0, 50.0, ext_top_y, false)
	extend = r.number("extend", 0.0, 500.0, extend, false)
	base_height = r.number("base_height", 0.0, 100.0, base_height, false)
	wall_pattern = StringName(r.text("wall_pattern", "brick", false))
	base_pattern = StringName(r.text("base_pattern", "basalt", false))
	channel_width = r.number("channel_width", 0.0, 5.0, channel_width, false)
	channel_color = r.color("channel_color", Color.WHITE, false)
	channel_glow = r.number("channel_glow", 0.0, 8.0, channel_glow, false)
	if x1 <= x0 or z1 <= z0:
		r.problem("x1", "x1 and z1 must be larger than x0 and z0")
	for pattern: StringName in [wall_pattern, base_pattern]:
		if not SurfacePainter.PATTERNS.has(pattern):
			r.problem("wall_pattern", "unknown pattern '%s'" % pattern)
