class_name BattleStyle
extends RefCounted
## Small builders for the battle screen's look (panels, labels, bars, names, head icons) from a BattleViewDef.
## Pure view helpers: no rules are decided here.


## A translated player-facing string (static code cannot call tr()).
static func text(key: String) -> String:
	return String(TranslationServer.translate(StringName(key)))


static func panel(view: BattleViewDef, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = view.panel_color
	box.border_color = border
	var edge: int = roundi(view.margin / 8.0)
	box.set_border_width_all(edge)
	box.set_corner_radius_all(edge)
	box.set_content_margin_all(roundi(view.margin / 2.0))
	return box


static func label(content: String, color: Color = Color.WHITE) -> Label:
	var out := Label.new()
	out.text = content
	out.add_theme_color_override("font_color", color)
	return out


static func bar(view: BattleViewDef, fill: Color) -> ProgressBar:
	var out := ProgressBar.new()
	out.show_percentage = false
	out.custom_minimum_size = Vector2(0.0, view.bar_height)
	out.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	out.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var back := StyleBoxFlat.new()
	back.bg_color = view.panel_color.darkened(0.5)
	var front := StyleBoxFlat.new()
	front.bg_color = fill
	out.add_theme_stylebox_override("background", back)
	out.add_theme_stylebox_override("fill", front)
	return out


## The unit's display name; two of the same kind on one side get a number ("Concession Enforcer 2").
static func unit_name(sim: BattleSim, unit: UnitState) -> String:
	var base: String = text(unit.def.name_key)
	var same: Array[UnitState] = []
	for other: UnitState in sim.timeline.units:
		if other.side == unit.side and other.def.id == unit.def.id:
			same.append(other)
	if same.size() < 2:
		return base
	return text("UI_UNIT_NUMBERED") % [base, same.find(unit) + 1]


## A square crop of the sprite's head pixels (the top of its opaque area) for timeline icons.
static func head_icon(sprite_id: StringName) -> ImageTexture:
	var def := ContentDB.get_def("sprite", sprite_id) as SpriteDef
	var palette: PaletteDef = null
	if def != null:
		palette = ContentDB.get_def("palette", def.palette) as PaletteDef
	if def == null or palette == null:
		return ImageTexture.create_from_image(PixelArt.placeholder(1, 1))
	var img: Image = PixelArt.image(def, palette)
	var used: Rect2i = img.get_used_rect()
	if used.size.x == 0 or used.size.y == 0:
		return ImageTexture.create_from_image(img)
	var side: int = mini(used.size.x, used.size.y)
	var left: int = used.position.x + roundi((used.size.x - side) / 2.0)
	return ImageTexture.create_from_image(img.get_region(Rect2i(left, used.position.y, side, side)))
