class_name WorkshopStyleDef
extends Def
## Layout (pixels at 1920x1080), font sizes and colours of the workshop menu, and which fighter it compares.

var fighter: StringName = &""
## The screen size the layout is drawn for; smaller windows shrink the whole menu to fit.
var design_width: int = 0
var design_height: int = 0
var margin: int = 0
var gap: int = 0
var column_width: int = 0
var button_height: int = 0
var stats_width: int = 0
var title_size: int = 0
var heading_size: int = 0
var button_size: int = 0
var desc_size: int = 0
var stat_size: int = 0
var ability_size: int = 0
var confirm_width: int = 0
var confirm_height: int = 0
var border: int = 0
var backdrop: Color = Color.BLACK
var panel: Color = Color.BLACK
var text: Color = Color.WHITE
var muted: Color = Color.WHITE
var current: Color = Color.WHITE
var up: Color = Color.WHITE
var down: Color = Color.WHITE
var neutral: Color = Color.WHITE


func read(r: DefReader) -> void:
	id = r.id()
	fighter = r.id("fighter")
	design_width = r.integer("design_width", 320, 7680)
	design_height = r.integer("design_height", 240, 4320)
	margin = r.integer("margin", 0, 400)
	gap = r.integer("gap", 0, 200)
	column_width = r.integer("column_width", 100, 1200)
	button_height = r.integer("button_height", 40, 400)
	stats_width = r.integer("stats_width", 100, 1600)
	title_size = r.integer("title_size", 8, 200)
	heading_size = r.integer("heading_size", 8, 200)
	button_size = r.integer("button_size", 8, 200)
	desc_size = r.integer("desc_size", 8, 200)
	stat_size = r.integer("stat_size", 8, 200)
	ability_size = r.integer("ability_size", 8, 200)
	confirm_width = r.integer("confirm_width", 50, 1000)
	confirm_height = r.integer("confirm_height", 30, 400)
	border = r.integer("border", 0, 30)
	backdrop = _color(r, "backdrop")
	panel = _color(r, "panel")
	text = _color(r, "text")
	muted = _color(r, "muted")
	current = _color(r, "current")
	up = _color(r, "up")
	down = _color(r, "down")
	neutral = _color(r, "neutral")


func references() -> Array[Array]:
	return [["combatant", fighter]]


func _color(r: DefReader, key: String) -> Color:
	var hex: String = r.text(key)
	if Color.html_is_valid(hex):
		return Color.html(hex)
	push_error("workshop style '%s': %s '%s' is not a colour" % [id, key, hex])
	return Color.MAGENTA
