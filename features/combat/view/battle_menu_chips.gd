class_name BattleMenuChips
extends RefCounted
## The small tags on the right edge of a command-menu button: SP cost (cyan), "cancels" (magenta), the target
## scope of a self / all move, and for a target the HP and a "will interrupt" warning. Pure view helpers.


static func for_move(action: ActionDef) -> Array[Control]:
	var chips: Array[Control] = []
	var style: UiStyleDef = Ui.style()
	if action.cancels_cast:
		chips.append(_chip("[%s]" % Ui.text("UI_CANCELS"), style.colour(&"c_magenta")))
	if action.target != &"foe" and action.target != &"ally":
		var scope: String = Ui.text("UI_TARGET_" + String(action.target).to_upper())
		chips.append(_chip("[%s]" % scope, style.colour(&"c_gypsum_dim")))
	if action.sp_cost > 0:
		chips.append(_chip("%d %s" % [action.sp_cost, Ui.text("UI_SP")], style.colour(&"c_cyan")))
	return chips


## The herbs still free to use, on the Items entry.
static func for_items(held: int) -> Array[Control]:
	var chips: Array[Control] = []
	chips.append(_chip("x%d" % held, Ui.style().colour(&"c_gypsum_dim")))
	return chips


static func for_target(sim: BattleSim, hero: UnitState, action: ActionDef, target: UnitState) -> Array[Control]:
	var style: UiStyleDef = Ui.style()
	var chips: Array[Control] = []
	if action.cancels_cast and sim.lands_before(hero, action, target):
		chips.append(_chip("[%s]" % Ui.text("UI_WILL_INTERRUPT"), style.colour(&"c_magenta")))
	chips.append(_chip("%s %d" % [Ui.text("UI_HP"), target.hp], style.colour(&"c_hp_b")))
	return chips


## A menu Button in `list`: left text, chips on the right edge, menu sounds, hover grabs focus.
static func button(list: Control, content: String, chips: Array[Control]) -> Button:
	var out := Button.new()
	out.text = content
	out.alignment = HORIZONTAL_ALIGNMENT_LEFT
	out.custom_minimum_size.y = Ui.style().size(&"s_button_h")
	out.add_child(Ui.chip_row(chips))
	list.add_child(out)
	out.focus_entered.connect(AudioDirector.play_ui.bind(&"menu_move"))
	out.pressed.connect(AudioDirector.play_ui.bind(&"menu_confirm"))
	out.mouse_entered.connect(func() -> void: if not out.disabled: out.grab_focus())
	return out


## The button to focus first: the one whose meta equals preferred_id, else the first enabled one.
static func first_enabled(buttons: Array[Button], preferred_id: StringName, meta_key: String) -> Button:
	var first: Button = null
	for candidate: Button in buttons:
		if candidate.disabled:
			continue
		first = first if first != null else candidate
		if preferred_id != &"" and candidate.get_meta(meta_key) == preferred_id:
			first = candidate
	return first


static func _chip(content: String, colour: Color) -> Label:
	return Ui.label(content, &"NumberLabel", colour)
