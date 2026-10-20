class_name StandinPortrait
extends RefCounted
## Builds a stand-in portrait Image from a speaker's pixel sprite: head-and-chest rows cropped, scaled up with
## nearest filtering, over a soft backdrop in the speaker colour, plus brow and mouth marks per expression.
## Pure: images only, no nodes. Used until the real painted portraits exist.


static func image(speaker: SpeakerDef, expression: StringName, sprite: SpriteDef, palette: PaletteDef,
		style: DialogueStyleDef) -> Image:
	var base: Image = PixelArt.image(sprite, palette)
	var rows: int = mini(style.standin_rows, base.get_height())
	var crop: Image = base.get_region(Rect2i(0, 0, base.get_width(), rows))
	_draw_marks(crop, speaker, expression, style)
	crop.resize(crop.get_width() * style.standin_scale, crop.get_height() * style.standin_scale, Image.INTERPOLATE_NEAREST)
	var out: Image = _backdrop(crop.get_size(), speaker.color, style.backdrop_alpha)
	out.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i.ZERO)
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


static func _draw_marks(crop: Image, speaker: SpeakerDef, expression: StringName, style: DialogueStyleDef) -> void:
	_stamp(crop, style.brows.get(expression, PackedStringArray()), Vector2i(speaker.face_x, speaker.brow_y), style.mark_color)
	_stamp(crop, style.mouths.get(expression, PackedStringArray()), Vector2i(speaker.face_x, speaker.mouth_y), style.mark_color)


## Draws the '#' cells of a mark; its centre column and middle row land on anchor (sprite pixels).
static func _stamp(target: Image, mark: PackedStringArray, anchor: Vector2i, color: Color) -> void:
	for row: int in mark.size():
		for col: int in mark[row].length():
			var at := Vector2i(anchor.x + col - mark[row].length() / 2, anchor.y + row - mark.size() / 2)
			if mark[row][col] == "#" and Rect2i(Vector2i.ZERO, target.get_size()).has_point(at):
				target.set_pixelv(at, color)
