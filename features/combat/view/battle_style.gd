class_name BattleStyle
extends RefCounted
## Small builders for the battle screen's look (labels, bars, names, head icons). The look itself comes from the
## shared UI style (features/ui); the BattleViewDef only sizes the layout. Pure view helpers: no rules here.


## A translated player-facing string (static code cannot call tr()).
static func text(key: String) -> String:
	return Ui.text(key)


static func label(content: String, variant: StringName = &"", colour: Color = Color.TRANSPARENT) -> Label:
	return Ui.label(content, variant, colour)


## kind: &"HpBar" (red to orange) or &"SpBar" (blue to cyan).
static func bar(view: BattleViewDef, kind: StringName) -> ProgressBar:
	var out := ProgressBar.new()
	out.theme_type_variation = kind
	out.show_percentage = false
	out.custom_minimum_size = Vector2(0.0, view.bar_height)
	out.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	out.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
