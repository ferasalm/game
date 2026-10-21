class_name UiOrnament
extends RefCounted
## Procedurally painted UI textures from the UiStyleDef (no image files): the nine-patch frames (a thin brass line,
## a thin gypsum line inside it and a small diamond in each corner, like the carved plaster of a Sana'a
## tower-house), and the zigzag frieze band that divides sections. Cached; call clear_cache() after a style change.

static var _cache: Dictionary[String, Texture2D] = {}


static func clear_cache() -> void:
	_cache.clear()


## A nine-patch frame of kind &"panel" (double line + corner diamonds), &"plate" (brighter, for name plates) or
## &"inset" (one dim line, no ornaments). Its slice margin is style.size(&"s_frame_cell") on every side.
static func frame(style: UiStyleDef, kind: StringName) -> Texture2D:
	var key: String = "frame_%s" % kind
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(_paint_frame(style, kind))
	return _cache[key]


## One period of the zigzag frieze (a row of hanging triangles under a thin line); tile it horizontally.
static func frieze(style: UiStyleDef) -> Texture2D:
	if not _cache.has("frieze"):
		_cache["frieze"] = ImageTexture.create_from_image(_paint_frieze(style))
	return _cache["frieze"]


## A small solid diamond (used as separators and the timeline's command mark).
static func diamond(style: UiStyleDef, colour_key: StringName, radius: int) -> Texture2D:
	var key: String = "diamond_%s_%d" % [colour_key, radius]
	if not _cache.has(key):
		var side: int = radius * 2 + 1
		var img := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
		for y: int in side:
			for x: int in side:
				if absi(x - radius) + absi(y - radius) <= radius:
					img.set_pixel(x, y, style.colour(colour_key))
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


static func _paint_frame(style: UiStyleDef, kind: StringName) -> Image:
	var cell: int = style.size(&"s_frame_cell")
	var side: int = cell * 3
	var line: int = style.size(&"s_frame_line")
	var inner: int = 1 + line + style.size(&"s_frame_gap")
	var outer_colour: Color = style.colour(&"c_brass" if kind == &"plate" else &"c_brass_dim")
	var back: Color = style.colour(&"c_indigo") if kind == &"plate" else style.colour(&"c_glass")
	var img := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	for y: int in side:
		for x: int in side:
			var edge: int = mini(mini(x, y), mini(side - 1 - x, side - 1 - y))
			var paint: Color = back
			if edge < 1:
				paint = Color.TRANSPARENT
			elif edge < 1 + line:
				paint = outer_colour
			elif edge == inner and kind != &"inset":
				paint = style.colour(&"c_gypsum_dim")
			img.set_pixel(x, y, paint)
	if kind != &"inset":
		_corners(img, style, inner, side)
	return img


static func _corners(img: Image, style: UiStyleDef, at: int, side: int) -> void:
	var radius: int = style.size(&"s_ornament")
	for centre: Vector2i in [Vector2i(at, at), Vector2i(side - 1 - at, at), Vector2i(at, side - 1 - at),
			Vector2i(side - 1 - at, side - 1 - at)]:
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				var reach: int = absi(dx) + absi(dy)
				var paint: Color = Color.TRANSPARENT
				if reach <= radius:
					paint = style.colour(&"c_brass")
				if reach <= radius - 3:
					paint = style.colour(&"c_glass_deep")
				if reach <= radius - 5:
					paint = style.colour(&"c_gypsum")
				var at_pixel := Vector2i(centre.x + dx, centre.y + dy)
				if paint.a > 0.0 and Rect2i(Vector2i.ZERO, img.get_size()).has_point(at_pixel):
					img.set_pixel(at_pixel.x, at_pixel.y, paint)


static func _paint_frieze(style: UiStyleDef) -> Image:
	var period: int = style.size(&"s_frieze_period")
	var height: int = style.size(&"s_frieze_h")
	var img := Image.create_empty(period, height, false, Image.FORMAT_RGBA8)
	for y: int in height:
		for x: int in period:
			var span: float = (period / 2.0) * (1.0 - float(y) / height)
			if y == 0:
				img.set_pixel(x, y, style.colour(&"c_brass_dim"))
			elif absf(x + 0.5 - period / 2.0) <= span:
				img.set_pixel(x, y, style.colour(&"c_gypsum_dim"))
	return img
