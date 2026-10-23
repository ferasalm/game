class_name PortraitFaces
extends RefCounted
## purpose: Caches uncropped painted hero portraits. Falls back to CharacterIcons.texture.

static var _cache: Dictionary[StringName, Texture2D] = {}


## The uncropped painted portrait texture of hero, or CharacterIcons.texture fallback.
static func texture(hero: StringName) -> Texture2D:
	if _cache.has(hero):
		return _cache[hero]
	var path: String = "res://assets/portraits/%s_neutral.png" % hero
	if FileAccess.file_exists(path):
		var img: Image = Image.load_from_file(path)
		if img != null:
			var tex: ImageTexture = ImageTexture.create_from_image(img)
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


static func clear_cache() -> void:
	_cache.clear()
