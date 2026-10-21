class_name CharacterIcons
extends RefCounted
## Head icons for timeline medallions and party cards. The image path per character comes from content
## (ui_style `icons`); a missing or unreadable file gives a coloured disc with the character's initial instead.
## Characters are live 3D models now, so no icon is ever cropped from sprite pixels.

const DISC_SIDE: int = 64  ## texels of the fallback disc (engine value; it is scaled to the icon size)

static var _cache: Dictionary[String, Texture2D] = {}


## The real icon of a character id, or null when its file does not exist.
static func texture(character: StringName) -> Texture2D:
	var path: String = Ui.style().icons.get(String(character), "")
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	if not _cache.has(path):
		var loaded: Image = Image.load_from_file(path)
		if loaded == null:
			return null
		_cache[path] = ImageTexture.create_from_image(loaded)
	return _cache[path]


static func clear_cache() -> void:
	_cache.clear()


## First letter of the character's translated name ("?" when unknown).
static func initial(character: StringName) -> String:
	var def := ContentDB.get_def("combatant", character) as CombatantDef
	var shown: String = Ui.text(def.name_key) if def != null else ""
	return shown.left(1).to_upper() if not shown.is_empty() else "?"


## A filled circle in `colour`, soft at the rim, on a transparent square.
static func disc(colour: Color) -> Texture2D:
	var out := Image.create_empty(DISC_SIDE, DISC_SIDE, false, Image.FORMAT_RGBA8)
	var centre := Vector2(DISC_SIDE, DISC_SIDE) * 0.5
	var radius: float = DISC_SIDE * 0.5
	for y: int in DISC_SIDE:
		for x: int in DISC_SIDE:
			var edge: float = clampf((radius - Vector2(x + 0.5, y + 0.5).distance_to(centre)) / 1.5, 0.0, 1.0)
			out.set_pixel(x, y, Color(colour, edge))
	return ImageTexture.create_from_image(out)


## A square Control showing the character: the real icon, else a disc in `tint` carrying the initial.
static func face(character: StringName, tint: Color) -> Control:
	var real: Texture2D = texture(character)
	var holder := TextureRect.new()
	holder.texture = real if real != null else disc(tint.darkened(0.45))
	holder.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	holder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	holder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if real == null:
		var letter: Label = Ui.label(initial(character), &"NameLabel", Ui.style().colour(&"c_text"))
		letter.set_anchors_preset(Control.PRESET_FULL_RECT)
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		holder.add_child(letter)
	return holder
