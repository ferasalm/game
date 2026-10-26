class_name BattleCommandMenu
extends PanelContainer
## The compact command menu (in the turn panel, beside the hero) for the hero waiting at COMMAND: first one Button per move (unaffordable ones
## disabled; name, SP cost, a "cancels" / target tag; the focused move's description below), then one Button
## per valid target (foes or allies; self and all-moves skip this list). The back action (ui_cancel) returns from targets to moves. The sim answers every rule question.

## The player committed to this move and target (the stage calls BattleSim.choose).
signal chosen(action: ActionDef, target_id: StringName)
## The focused target changed (&"" when leaving the target list); the stage moves the 3D marker.
signal target_focused(unit_id: StringName)
## The line under the menu changed: the focused move's description, or (warning) why a choice was refused.
signal help_changed(text: String, warning: bool)
## The Items entry was pressed: the HUD opens the item list.
signal items_requested

const ITEMS_ID: StringName = &"items"  ## the action_id meta of the Items entry (it is not a move)
const FLEE_ID: StringName = &"flee"  ## the action_id meta of the FLEE entry (it is not a move)

var _sim: BattleSim
var _view: BattleViewDef
var _hero: UnitState = null
var _move: ActionDef = null
var _open: bool = false
var _title: Label
var _list: VBoxContainer
var _help: String = ""
var _buttons: Array[Button] = []
var _items_button: Button
var _flee_button: Button


func setup(sim: BattleSim, view: BattleViewDef) -> void:
	_sim = sim
	_view = view
	BattleStyle.bare_panel(self)
	var box := VBoxContainer.new()
	add_child(box)
	_title = BattleStyle.label("", &"TitleLabel")
	box.add_child(_title)
	_list = VBoxContainer.new()
	box.add_child(_list)
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
			if button != _items_button and button != _flee_button:
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
	_say(content, true)


## The help line now showing (a move's description, or why a choice was refused).
func help_text() -> String:
	return _help


func _say(content: String, warning: bool) -> void:
	_help = content
	help_changed.emit(content, warning)


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
	_title.visible = false  # the hero's card above names them
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
	# The FLEE entry.
	_flee_button = BattleFleeButton.add_to(self, _list, _buttons)


func _pick_move(action: ActionDef) -> void:
	if not action.needs_picker():
		chosen.emit(action, &"")  # self and all-moves skip the target list
		return
	_move = action
	_clear()
	_title.visible = true
	_title.add_theme_font_size_override("font_size", _view.menu_font + 4)
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
	_say(BattleStyle.text(action.desc_key) if not action.desc_key.is_empty() else "", false)


func _add_button(content: String, chips: Array[Control]) -> Button:
	var button: Button = BattleMenuChips.button(_list, content, chips, _view)
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
	_flee_button = null
	_say("", false)
