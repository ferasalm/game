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


## The head icon of a unit for timeline medallions: the character's icon file from content, else a coloured disc
## with the initial (CharacterIcons). Never a crop of sprite pixels. side 0 = party, 1 = enemy tint.
static func head_icon(unit_id: StringName, side: int = 0) -> Control:
	var style: UiStyleDef = Ui.style()
	return CharacterIcons.face(unit_id, style.colour(&"c_party" if side == 0 else &"c_enemy"))
