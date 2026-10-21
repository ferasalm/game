class_name TileDef
extends Def
## One kind of block: height in metres, colour (an art-bible palette letter or #hex), whether it blocks walking,
## an optional glow, an optional cap tile drawn on top of it (gypsum trim on a tower) and an optional surface
## pattern (a SurfacePainter texture painted over the colour, 4 m repeat, 32 px = 1 m), or hidden (blocks only).

var height: float = 0.0
var color: String = ""
var solid: bool = false
var glow: float = 0.0
var cap: StringName = &""
var pattern: StringName = &""
## An invisible block: it only blocks walking (a building or prop stands on these cells and draws itself).
var hidden: bool = false


func read(r: DefReader) -> void:
	id = r.id()
	height = r.number("height", 0.01, 20.0)
	color = r.text("color")
	solid = r.flag("solid")
	glow = r.number("glow", 0.0, 8.0, 0.0, false)
	cap = StringName(r.text("cap", "", false))
	pattern = StringName(r.text("pattern", "", false))
	hidden = r.flag("hidden")
	if pattern != &"" and not SurfacePainter.PATTERNS.has(pattern):
		push_error("tile '%s': unknown pattern '%s'" % [id, pattern])
	if color.length() != 1 and not Color.html_is_valid(color):
		push_error("tile '%s': '%s' is not a palette letter or #hex colour" % [id, color])


func references() -> Array[Array]:
	var out: Array[Array] = []
	if cap != &"":
		out.append(["tile", cap])
	return out


## The block's colour: a palette letter looks up the palette, anything else is a #hex.
func to_color(palette: PaletteDef) -> Color:
	if color.length() == 1:
		if palette != null and palette.colors.has(color):
			return palette.colors[color]
		return Color.MAGENTA
	return Color.html(color)
