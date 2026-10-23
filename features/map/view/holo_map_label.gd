class_name HoloMapLabel
extends RefCounted
## purpose: One map label candidate with a rect that can be pushed away from others.

var text: String = ""
var pos: Vector2 = Vector2.ZERO
var anchor: Vector2 = Vector2.ZERO
var size: Vector2 = Vector2.ZERO
var color: Color = Color.WHITE
var font_size: int = 16
var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER

var rect: Rect2:
	get:
		return Rect2(pos - size * 0.5, size)
