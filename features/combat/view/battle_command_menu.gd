class_name BattleCommandMenu
extends PanelContainer
## The command menu (bottom left) for the hero waiting at COMMAND: first one Button per move (unaffordable ones
## disabled; name, SP cost, a "cancels" / target tag; the focused move's description below), then one Button
## per valid target (foes or allies; self and all-moves skip this list). The back action (ui_cancel) returns from targets to moves. The sim answers every rule question.

## The player committed to this move and target (the stage calls BattleSim.choose).
signal chosen(action: ActionDef, target_id: StringName)
## The focused target changed (&"" when leaving the target list); the stage moves the 3D marker.
signal target_focused(unit_id: StringName)

var _sim: BattleSim
var _view: BattleViewDef
var _hero: UnitState = null
var _move: ActionDef = null
var _open: bool = false
var _title: Label
var _list: VBoxContainer
var _desc: Label
var _notice: Label
var _buttons: Array[Button] = []


func setup(sim: BattleSim, view: BattleViewDef) -> void:
	_sim = sim
	_view = view
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = view.margin
	offset_bottom = -view.margin
	offset_top = -view.margin
	offset_right = view.margin + view.menu_width
	add_theme_stylebox_override("panel", BattleStyle.panel(view, view.highlight_color))
	var box := VBoxContainer.new()
	add_child(box)
	_title = BattleStyle.label("", view.highlight_color)
	box.add_child(_title)
	_list = VBoxContainer.new()
	box.add_child(_list)
	_desc = BattleStyle.label("")
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size.x = view.menu_width - view.margin * 2.0
	box.add_child(_desc)
	_notice = BattleStyle.label("", view.enemy_color)
	box.add_child(_notice)
	visible = false


func is_open() -> bool:
	return _open


func hero() -> UnitState:
	return _hero


func open(waiting: UnitState) -> void:
	_hero = waiting
	_open = true
	visible = true
	_show_moves(null)


func close() -> void:
	_open = false
	visible = false
	_move = null
	_clear()


## The move buttons (empty while the target list shows). Each has meta "action_id".
func move_buttons() -> Array[Button]:
	return _buttons if _open and _move == null else ([] as Array[Button])


## The target buttons (empty while the move list shows). Each has meta "unit_id".
func target_buttons() -> Array[Button]:
	return _buttons if _open and _move != null else ([] as Array[Button])


func show_notice(content: String) -> void:
	_notice.text = content


## Back from the target list to the move list.
func back() -> void:
	if _open and _move != null:
		AudioDirector.play_ui(&"menu_cancel")
		var previous: ActionDef = _move
		target_focused.emit(&"")
		_show_moves(previous)


func _unhandled_input(event: InputEvent) -> void:
	if _open and _move != null and event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()


func _show_moves(focus_move: ActionDef) -> void:
	_move = null
	_clear()
	_title.text = BattleStyle.unit_name(_sim, _hero)
	var affordable: Array[ActionDef] = _sim.choices_for(_hero)
	for action_id: StringName in _hero.def.actions:
		var action: ActionDef = _sim.actions.get(action_id) as ActionDef
		if action == null:
			continue
		var button: Button = _add_button(_move_text(action))
		button.set_meta("action_id", action_id)
		button.disabled = not affordable.has(action)
		button.pressed.connect(_pick_move.bind(action))
		button.focus_entered.connect(_describe.bind(action))
	_focus(focus_move.id if focus_move != null else &"", "action_id")


func _pick_move(action: ActionDef) -> void:
	if not action.needs_picker():
		chosen.emit(action, &"")  # self and all-moves skip the target list
		return
	_move = action
	_clear()
	_title.text = BattleStyle.text("UI_PICK_TARGET")
	for target: UnitState in _sim.valid_targets(_hero, action):
		var button: Button = _add_button(_target_text(action, target))
		button.set_meta("unit_id", target.unit_id)
		button.pressed.connect(confirm.bind(target.unit_id))
		button.focus_entered.connect(_emit_focus.bind(target.unit_id))
	_focus(&"", "unit_id")


## The target was confirmed (a target button pressed): the stage commits the choice to the sim.
func confirm(target_id: StringName) -> void:
	if _open and _move != null:
		chosen.emit(_move, target_id)


func _move_text(action: ActionDef) -> String:
	var line: String = BattleStyle.text(action.name_key)
	if action.sp_cost > 0:
		line += "   %d %s" % [action.sp_cost, BattleStyle.text("UI_SP")]
	if action.cancels_cast:
		line += "   [%s]" % BattleStyle.text("UI_CANCELS")
	if action.target != &"foe" and action.target != &"ally":
		line += "   [%s]" % BattleStyle.text("UI_TARGET_" + String(action.target).to_upper())
	return line


func _target_text(action: ActionDef, target: UnitState) -> String:
	var line: String = "%s   %s %d" % [BattleStyle.unit_name(_sim, target), BattleStyle.text("UI_HP"), target.hp]
	if action.cancels_cast and _sim.lands_before(_hero, action, target):
		line += "   [%s]" % BattleStyle.text("UI_WILL_INTERRUPT")
	return line


func _emit_focus(unit_id: StringName) -> void:
	target_focused.emit(unit_id)


func _describe(action: ActionDef) -> void:
	_desc.text = BattleStyle.text(action.desc_key) if not action.desc_key.is_empty() else ""


func _add_button(content: String) -> Button:
	var button := Button.new()
	button.text = content
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_list.add_child(button)
	_buttons.append(button)
	button.focus_entered.connect(AudioDirector.play_ui.bind(&"menu_move"))
	button.pressed.connect(AudioDirector.play_ui.bind(&"menu_confirm"))
	button.mouse_entered.connect(func() -> void: if not button.disabled: button.grab_focus())
	return button


func _focus(preferred_id: StringName, meta_key: String) -> void:
	var first: Button = null
	for button: Button in _buttons:
		if button.disabled:
			continue
		first = first if first != null else button
		if preferred_id != &"" and button.get_meta(meta_key) == preferred_id:
			first = button
	if first != null:
		first.grab_focus()


func _clear() -> void:
	for button: Button in _buttons:
		_list.remove_child(button)
		button.queue_free()
	_buttons.clear()
	_desc.text = ""
	_notice.text = ""
