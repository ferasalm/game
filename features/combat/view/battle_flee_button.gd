class_name BattleFleeButton
extends RefCounted
## Helper to build the FLEE command-menu button (extracted to keep battle_command_menu.gd under 200 lines).

static func add_to(menu: BattleCommandMenu, list: VBoxContainer, buttons: Array[Button]) -> Button:
	var sim: BattleSim = menu._sim
	var flee_action: ActionDef = sim.actions.get(&"flee") as ActionDef
	if flee_action == null:
		return null
	var can_flee_now: bool = true
	if sim.setup != null and sim.setup.can_flee == false:
		can_flee_now = false
	var button: Button = menu._add_button(BattleStyle.text("UI_FLEE"), BattleMenuChips.for_move(flee_action))
	button.set_meta("action_id", flee_action.id)
	button.disabled = not can_flee_now
	if not can_flee_now:
		button.tooltip_text = BattleStyle.text("UI_CANT_FLEE")
	button.pressed.connect(menu._pick_move.bind(flee_action))
	button.focus_entered.connect(menu._describe.bind(flee_action))
	return button
