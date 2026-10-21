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


static func for_target(sim: BattleSim, hero: UnitState, action: ActionDef, target: UnitState) -> Array[Control]:
	var style: UiStyleDef = Ui.style()
	var chips: Array[Control] = []
	if action.cancels_cast and sim.lands_before(hero, action, target):
		chips.append(_chip("[%s]" % Ui.text("UI_WILL_INTERRUPT"), style.colour(&"c_magenta")))
	chips.append(_chip("%s %d" % [Ui.text("UI_HP"), target.hp], style.colour(&"c_hp_b")))
	return chips


static func _chip(content: String, colour: Color) -> Label:
	return Ui.label(content, &"NumberLabel", colour)
