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


## A slim HP / SP bar of the given pixel height (the strips and cards).
static func thin_bar(kind: StringName, height: int) -> ProgressBar:
	var out := ProgressBar.new()
	out.theme_type_variation = kind
	out.show_percentage = false
	out.custom_minimum_size = Vector2(0.0, height)
	out.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	out.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	out.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return out


## A command-menu row made compact: smaller text and tighter top and bottom padding, the rest of the style kept.
static func compact_button(button: Button, view: BattleViewDef) -> void:
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled", &"hover_pressed"]:
		var box := Ui.theme().get_stylebox(state, &"Button").duplicate() as StyleBoxFlat
		box.content_margin_top = view.menu_pad_v
		box.content_margin_bottom = view.menu_pad_v
		button.add_theme_stylebox_override(state, box)
	button.add_theme_font_size_override("font_size", view.menu_font)


## A framed panel with tighter inner padding (the turn panel's card and menus).
static func tight_panel(panel: PanelContainer, kind: StringName, view: BattleViewDef) -> void:
	var box := Ui.theme().get_stylebox(&"panel", kind).duplicate() as StyleBox
	box.set_content_margin_all(view.panel_margin)
	panel.add_theme_stylebox_override("panel", box)


## A panel with no frame of its own (it sits inside the turn panel's frame).
static func bare_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())


## The unit's display name; two of the same kind on one side get a letter ("Concession Enforcer B").
static func unit_name(sim: BattleSim, unit: UnitState) -> String:
	var base: String = text(unit.def.name_key)
	var letter: String = UnitLetters.of(sim.timeline.units, unit)
	return base if letter.is_empty() else text("BATTLE_UNIT_LETTERED") % [base, letter]


## The head icon of a unit for timeline medallions: the character's icon file from content, else a coloured disc
## with the initial (CharacterIcons). Never a crop of sprite pixels. side 0 = party, 1 = enemy tint.
static func head_icon(unit_id: StringName, side: int = 0) -> Control:
	var style: UiStyleDef = Ui.style()
	return CharacterIcons.face(unit_id, style.colour(&"c_party" if side == 0 else &"c_enemy"))
