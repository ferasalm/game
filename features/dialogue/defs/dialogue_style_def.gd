class_name DialogueStyleDef
extends Def
## Look and timing of the dialogue box (fractions of the screen, pixels, colours, speed) and the pixel marks
## (brows, mouth) that make the stand-in portraits show an expression. A mark is rows of '#' and '.'; its centre
## column and middle row sit on the speaker's face anchor.

var box_height: float = 0.0
var box_margin: int = 0
var box_color: Color = Color.BLACK
var portrait_height: float = 0.0
var portrait_width: float = 0.0
var text_left: float = 0.0
var pad: int = 0
var name_size: int = 0
var text_size: int = 0
var text_color: Color = Color.WHITE
var chars_per_second: float = 0.0
var arrow_size: int = 0
var arrow_bob: float = 0.0
var arrow_speed: float = 0.0
var arrow_color: Color = Color.WHITE
var standin_rows: int = 0
var standin_scale: int = 0
var backdrop_alpha: float = 0.0
var mark_color: Color = Color.BLACK
var brows: Dictionary[StringName, PackedStringArray] = {}
var mouths: Dictionary[StringName, PackedStringArray] = {}


func read(r: DefReader) -> void:
	id = r.id()
	box_height = r.number("box_height", 0.05, 0.6)
	box_margin = r.integer("box_margin", 0, 200)
	box_color = _color(r, "box_color")
	box_color.a = r.number("box_alpha", 0.0, 1.0)
	portrait_height = r.number("portrait_height", 0.1, 0.95)
	portrait_width = r.number("portrait_width", 0.05, 0.6)
	text_left = r.number("text_left", 0.0, 0.8)
	pad = r.integer("pad", 0, 200)
	name_size = r.integer("name_size", 8, 120)
	text_size = r.integer("text_size", 8, 120)
	text_color = _color(r, "text_color")
	chars_per_second = r.number("chars_per_second", 1.0, 1000.0)
	arrow_size = r.integer("arrow_size", 4, 100)
	arrow_bob = r.number("arrow_bob", 0.0, 50.0)
	arrow_speed = r.number("arrow_speed", 0.0, 50.0)
	arrow_color = _color(r, "arrow_color")
	standin_rows = r.integer("standin_rows", 4, 64)
	standin_scale = r.integer("standin_scale", 1, 64)
	backdrop_alpha = r.number("backdrop_alpha", 0.0, 1.0)
	mark_color = _color(r, "mark_color")
	for expression: StringName in DialogueLine.EXPRESSIONS:
		brows[expression] = r.text_list("brows_" + expression)
		mouths[expression] = r.text_list("mouth_" + expression)


func _color(r: DefReader, key: String) -> Color:
	var hex: String = r.text(key)
	if Color.html_is_valid(hex):
		return Color.html(hex)
	push_error("dialogue style '%s': %s '%s' is not a colour" % [id, key, hex])
	return Color.MAGENTA
