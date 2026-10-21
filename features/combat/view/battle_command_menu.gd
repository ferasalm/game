class_name BattleCommandMenu
extends PanelContainer
## The command menu (bottom left) for the hero waiting at COMMAND: first one Button per move (unaffordable ones
## disabled; name, SP cost, a "cancels" / target tag; the focused move's description below), then one Button
## per valid target (foes or allies; self and all-moves skip this list). The back action (ui_cancel) returns from targets to moves. The sim answers every rule question.

## The player committed to this move and target (the stage calls BattleSim.choose).
signal chosen(action: ActionDef, target_id: StringName)
## The focused target changed (&"" when leaving the target list); the stage moves the 3D marker.
signal target_focused(unit_id: StringName)
## The Items entry was pressed: the HUD opens the item list (BattleItemMenu).
signal items_requested

const ITEMS_ID: StringName = &"items"  ## the action_id meta of the Items entry (it is not a move)

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
var _items_button: Button


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
	var box := VBoxContainer.new()
	add_child(box)
	_title = BattleStyle.label("", &"TitleLabel")
	box.add_child(_title)
	box.add_child(Ui.divider())
	_list = VBoxContainer.new()
	box.add_child(_list)
	box.add_child(Ui.divider())
	_desc = BattleStyle.label("", &"MutedLabel")
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(view.menu_width - view.margin * 2.0, Ui.style().size(&"s_cmd_desc_h"))
	box.add_child(_desc)
	_notice = BattleStyle.label("", &"SmallLabel", Ui.style().colour(&"c_bad"))
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
	var out: Array[Button] = []
	if _open and _move == null:
		for button: Button in _buttons:
			if button != _items_button:
				out.append(button)
	return out


## The Items entry (null while the target list shows).
func items_button() -> Button:
	return _items_button if _open and _move == null else null


## Back from the item list: the move list shows again with the cursor on Items.
func return_from_items() -> void:
	if _open:
		_show_moves(null)
		if _items_button != null and not _items_button.disabled:
			_items_button.grab_focus()


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
		var button: Button = _add_button(BattleStyle.text(action.name_key), BattleMenuChips.for_move(action))
		button.set_meta("action_id", action_id)
		button.disabled = not affordable.has(action)
		button.pressed.connect(_pick_move.bind(action))
		button.focus_entered.connect(_describe.bind(action))
	_add_items_entry()
	_focus(focus_move.id if focus_move != null else &"", "action_id")


func _add_items_entry() -> void:
	_items_button = _add_button(BattleStyle.text("BATTLE_ITEMS"), BattleMenuChips.for_items(_sim.items.free_count()))
	_items_button.set_meta("action_id", ITEMS_ID)
	_items_button.disabled = not _sim.items.any_available()
	_items_button.pressed.connect(items_requested.emit)


func _pick_move(action: ActionDef) -> void:
	if not action.needs_picker():
		chosen.emit(action, &"")  # self and all-moves skip the target list
		return
	_move = action
	_clear()
	_title.text = BattleStyle.text("UI_PICK_TARGET")
	for target: UnitState in _sim.valid_targets(_hero, action):
		var button: Button = _add_button(BattleStyle.unit_name(_sim, target), BattleMenuChips.for_target(_sim, _hero, action, target))
		button.set_meta("unit_id", target.unit_id)
		button.pressed.connect(confirm.bind(target.unit_id))
		button.focus_entered.connect(_emit_focus.bind(target.unit_id))
	_focus(&"", "unit_id")


## The target was confirmed (a target button pressed): the stage commits the choice to the sim.
func confirm(target_id: StringName) -> void:
	if _open and _move != null:
		chosen.emit(_move, target_id)


func _emit_focus(unit_id: StringName) -> void:
	target_focused.emit(unit_id)


func _describe(action: ActionDef) -> void:
	_desc.text = BattleStyle.text(action.desc_key) if not action.desc_key.is_empty() else ""


func _add_button(content: String, chips: Array[Control]) -> Button:
	var button: Button = BattleMenuChips.button(_list, content, chips)
	_buttons.append(button)
	return button


func _focus(preferred_id: StringName, meta_key: String) -> void:
	var first: Button = BattleMenuChips.first_enabled(_buttons, preferred_id, meta_key)
	if first != null:
		first.grab_focus()


func _clear() -> void:
	for button: Button in _buttons:
		_list.remove_child(button)
		button.queue_free()
	_buttons.clear()
	_items_button = null
	_desc.text = ""
	_notice.text = ""
