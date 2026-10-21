class_name StandinPortrait
extends RefCounted
## Builds a stand-in portrait Image for a speaker without painted art: a soft glow in the speaker colour, a disc in
## that colour and brow and mouth marks per expression. It no longer crops sprite pixels (characters are live 3D
## models now). The image is standin_rows pixels square, scaled up by standin_scale with nearest filtering. Pure.

const DISC_RADIUS: float = 0.34  ## disc radius as a fraction of the side
const BROW_ROW: float = 0.4  ## where the brow mark is centred, fraction of the side from the top
const MOUTH_ROW: float = 0.6  ## where the mouth mark is centred


static func image(speaker: SpeakerDef, expression: StringName, style: DialogueStyleDef) -> Image:
	var side: int = style.standin_rows
	var out: Image = _backdrop(Vector2i(side, side), speaker.color, style.backdrop_alpha)
	_disc(out, speaker.color)
	var middle: int = side / 2
	_stamp(out, style.brows.get(expression, PackedStringArray()), Vector2i(middle, roundi(side * BROW_ROW)), style.mark_color)
	_stamp(out, style.mouths.get(expression, PackedStringArray()), Vector2i(middle, roundi(side * MOUTH_ROW)), style.mark_color)
	out.resize(side * style.standin_scale, side * style.standin_scale, Image.INTERPOLATE_NEAREST)
	return out


## A radial fade: speaker colour in the middle, fully transparent at the edge.
static func _backdrop(size: Vector2i, color: Color, alpha: float) -> Image:
	var out := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var centre := Vector2(size) * 0.5
	var radius: float = minf(centre.x, centre.y)
	for y: int in size.y:
		for x: int in size.x:
			var t: float = clampf(1.0 - Vector2(x, y).distance_to(centre) / radius, 0.0, 1.0)
			out.set_pixel(x, y, Color(color, alpha * t * t * (3.0 - 2.0 * t)))
	return out


static func _disc(target: Image, color: Color) -> void:
	var side: int = target.get_width()
	var centre := Vector2(side, side) * 0.5
	for y: int in side:
		for x: int in side:
			if Vector2(x + 0.5, y + 0.5).distance_to(centre) <= side * DISC_RADIUS:
				target.set_pixel(x, y, color.lightened(0.1))


## Draws the '#' cells of a mark; its centre column and middle row land on anchor.
static func _stamp(target: Image, mark: PackedStringArray, anchor: Vector2i, color: Color) -> void:
	for row: int in mark.size():
		for col: int in mark[row].length():
			var at := Vector2i(anchor.x + col - mark[row].length() / 2, anchor.y + row - mark.size() / 2)
			if mark[row][col] == "#" and Rect2i(Vector2i.ZERO, target.get_size()).has_point(at):
				target.set_pixelv(at, color)
