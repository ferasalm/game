class_name PortraitFaces
extends RefCounted
## purpose: Caches painted hero portraits (cropped head and uncropped bust). Falls back to CharacterIcons.

const HEAD_RATIO: float = 0.38

static var _cache: Dictionary[StringName, Texture2D] = {}
static var _bust_cache: Dictionary[StringName, Texture2D] = {}


## The cropped head texture of hero, or CharacterIcons.texture fallback.
static func texture(hero: StringName) -> Texture2D:
	if _cache.has(hero):
		return _cache[hero]
	var path: String = "res://assets/portraits/%s_neutral.png" % hero
	if FileAccess.file_exists(path):
		var img: Image = Image.load_from_file(path)
		if img != null:
			var side: int = int(round(float(img.get_height()) * HEAD_RATIO))
			var x: int = maxi(0, (img.get_width() - side) / 2)
			var cropped: Image = img.get_region(Rect2i(x, 0, side, side))
			var tex: ImageTexture = ImageTexture.create_from_image(cropped)
			_cache[hero] = tex
			return tex
	var fallback: Texture2D = CharacterIcons.texture(hero)
	if fallback != null:
		_cache[hero] = fallback
	return fallback


## Square face display: painted portrait head, or CharacterIcons.face fallback.
static func face(hero: StringName, tint: Color = Color.WHITE) -> Control:
	var tex: Texture2D = texture(hero)
	if tex == null:
		return CharacterIcons.face(hero, tint)
	var holder := TextureRect.new()
	holder.texture = tex
	holder.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	holder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	holder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return holder


## The uncropped painted bust texture of hero, or CharacterIcons.texture fallback.
static func bust_texture(hero: StringName) -> Texture2D:
	if _bust_cache.has(hero):
		return _bust_cache[hero]
	var path: String = "res://assets/portraits/%s_neutral.png" % hero
	if FileAccess.file_exists(path):
		var img: Image = Image.load_from_file(path)
		if img != null:
			var tex: ImageTexture = ImageTexture.create_from_image(img)
			_bust_cache[hero] = tex
			return tex
	var fallback: Texture2D = CharacterIcons.texture(hero)
	if fallback != null:
		_bust_cache[hero] = fallback
	return fallback


## Whole bust display: uncropped painted portrait, or CharacterIcons.face fallback.
static func bust(hero: StringName, tint: Color = Color.WHITE) -> Control:
	var tex: Texture2D = bust_texture(hero)
	if tex == null:
		return CharacterIcons.face(hero, tint)
	var holder := TextureRect.new()
	holder.texture = tex
	holder.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	holder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	holder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return holder


static func clear_cache() -> void:
	_cache.clear()
	_bust_cache.clear()

