class_name HoloMapLabel
extends RefCounted
## purpose: One map label candidate with a rect that can be pushed away from others.

const PADDING: float = 4.0

var text: String = ""
var pos: Vector2 = Vector2.ZERO
var anchor: Vector2 = Vector2.ZERO
var size: Vector2 = Vector2.ZERO
var color: Color = Color.WHITE
var font_size: int = 16
var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER

var musnad_text: String = ""
var musnad_font: Font = null
var musnad_font_size: int = 20
var is_boxed: bool = false
var box_bg_color: Color = Color("#08101c")
var box_border_color: Color = Color("#3fe0ff")
var box_bg_alpha: float = 0.80

var rect: Rect2:
	get:
		return Rect2(pos - size * 0.5, size).grow(PADDING)

var glyph_rect: Rect2:
	get:
		return Rect2(pos - size * 0.5, size)
