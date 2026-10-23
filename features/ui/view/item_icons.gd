class_name ItemIcons
extends RefCounted
## Resolves item icon textures from content paths; where the image file is missing, draws a rarity-coloured
## disc with the item's first letter. Reused by shop cells and shop detail.

const DEFAULT_SIDE: int = 96
static var _disc_cache: Dictionary[String, Texture2D] = {}
static var _icon_cache: Dictionary[String, Texture2D] = {}


## The expected file path for an item's icon.
static func icon_path(def: ConsumableDef) -> String:
	if def == null or def.icon.is_empty():
		return ""
	return "res://assets/icons/%s.png" % def.icon


## Loads the icon file texture, or null when the file does not exist.
static func texture(def: ConsumableDef) -> Texture2D:
	var path: String = icon_path(def)
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	if not _icon_cache.has(path):
		var img: Image = Image.load_from_file(path)
		if img == null:
			return null
		_icon_cache[path] = ImageTexture.create_from_image(img)
	return _icon_cache[path]


## First letter of the item's translated name ("?" when unknown).
static func initial(def: ConsumableDef) -> String:
	if def == null:
		return "?"
	var shown: String = Ui.text(def.name_key)
	return shown.left(1).to_upper() if not shown.is_empty() else "?"


## Draws a rarity-coloured disc of the given size.
static func disc(colour: Color, side: int = DEFAULT_SIDE) -> Texture2D:
	var key: String = "%s_%d" % [colour.to_html(), side]
	if _disc_cache.has(key):
		return _disc_cache[key]
	var out: Image = Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	var centre := Vector2(side, side) * 0.5
	var radius: float = side * 0.5
	for y: int in side:
		for x: int in side:
			var edge: float = clampf((radius - Vector2(x + 0.5, y + 0.5).distance_to(centre)) / 1.5, 0.0, 1.0)
			out.set_pixel(x, y, Color(colour, edge))
	var tex: ImageTexture = ImageTexture.create_from_image(out)
	_disc_cache[key] = tex
	return tex


## Sets the icon texture on target TextureRect; applies disc fallback with initial if file is missing.
static func apply(target: TextureRect, def: ConsumableDef, side: int = DEFAULT_SIDE) -> void:
	if target == null:
		return
	target.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	target.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	target.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var real: Texture2D = texture(def)
	var old_label: Label = null
	for child: Node in target.get_children():
		if child is Label and child.name == &"InitialLabel":
			old_label = child as Label
			break
	if real != null:
		target.texture = real
		if old_label != null:
			old_label.queue_free()
		return
	var rarity_id: StringName = def.rarity if (def != null and "rarity" in def) else &""
	var rarity_col: Color = UiRarity.colour(rarity_id)
	target.texture = disc(rarity_col.darkened(0.2), side)
	var letter_lbl: Label = old_label as Label
	if letter_lbl == null:
		letter_lbl = Label.new()
		letter_lbl.name = "InitialLabel"
		letter_lbl.theme_type_variation = &"TitleLabel"
		letter_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		letter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		target.add_child(letter_lbl)
	letter_lbl.text = initial(def)
	letter_lbl.add_theme_color_override("font_color", Ui.style().colour(&"c_text"))


static func clear_cache() -> void:
	_disc_cache.clear()
	_icon_cache.clear()
