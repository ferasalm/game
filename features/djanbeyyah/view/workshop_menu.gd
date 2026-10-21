class_name WorkshopMenu
extends CanvasLayer
## The djanbeyyah bench: pick 1 of 2 hilts and 1 of 2 blades, see how Zayd's numbers change, Confirm to save the
## pair in GameState.equipment. The back action leaves without saving. Built in code from content/djanbeyyah.
## Use: add it to the scene, call open(), listen to closed. Keyboard, mouse and pad work through Button focus.

## Emitted once each time the menu closes (Confirm or back).
signal closed

var _style: WorkshopStyleDef
var _base: CombatantDef
var _start: LoadoutDef
var _hilts: Dictionary[StringName, HiltDef] = {}
var _blades: Dictionary[StringName, BladeDef] = {}
var _choices: Dictionary[StringName, WorkshopChoice] = {}
var _worn: Array[StringName] = []
var _staged: Array[StringName] = []
var _shown: Array[StringName] = []
var _rows: Array[StatRow] = []
var _panel: WorkshopStatsPanel
var _back: ColorRect
var _opened_frame: int = -1


func _ready() -> void:
	visible = false
	_style = ContentDB.get_def("workshop_style", &"default") as WorkshopStyleDef
	_base = ContentDB.get_def("combatant", _style.fighter) as CombatantDef
	_start = ContentDB.get_def("loadout", &"zayd_start") as LoadoutDef
	for hilt_id: StringName in ContentDB.ids("hilt"):
		_hilts[hilt_id] = ContentDB.get_def("hilt", hilt_id) as HiltDef
	for blade_id: StringName in ContentDB.ids("blade"):
		_blades[blade_id] = ContentDB.get_def("blade", blade_id) as BladeDef
	_build()


## Shows the bench with the worn pair staged, and puts focus on the worn hilt.
func open() -> void:
	_worn = Loadout.current(GameState.equipment, _start)
	_staged = _worn.duplicate()
	for choice_id: StringName in _choices:
		var choice: WorkshopChoice = _choices[choice_id]
		choice.mark_current(_worn.has(choice_id))
		choice.mark_staged(_staged.has(choice_id))
	_preview(_staged)
	AudioDirector.play_ui(&"menu_open")
	visible = true
	_opened_frame = Engine.get_process_frames()
	_choices[_worn[0]].grab_focus()


func is_open() -> bool:
	return visible


## Stages a hilt / blade (what pressing it does).
func select_hilt(hilt_id: StringName) -> void:
	_stage(0, hilt_id, _hilts)


func select_blade(blade_id: StringName) -> void:
	_stage(1, blade_id, _blades)


## Saves the staged pair into GameState.equipment and closes.
func confirm() -> void:
	if not visible:
		return
	AudioDirector.play_ui(&"menu_confirm")
	GameState.equipment[&"hilt"] = _staged[0]
	GameState.equipment[&"blade"] = _staged[1]
	_close()


## Closes without changing anything.
func cancel() -> void:
	if visible:
		AudioDirector.play_ui(&"menu_cancel")
		_close()


## The choice buttons, hilts first then blades.
func choice_buttons() -> Array[WorkshopChoice]:
	var out: Array[WorkshopChoice] = []
	for hilt_id: StringName in _hilts:
		out.append(_choices[hilt_id])
	for blade_id: StringName in _blades:
		out.append(_choices[blade_id])
	return out


## [hilt_id, blade_id] that the stats panel currently describes.
func shown_pair() -> Array[StringName]:
	return _shown


## The rows currently in the stats panel.
func shown_rows() -> Array[StatRow]:
	return _rows


func stats_panel() -> WorkshopStatsPanel:
	return _panel


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"back") or event.is_action_pressed(&"ui_cancel")):
		cancel()
		get_viewport().set_input_as_handled()


func _stage(slot: int, item_id: StringName, table: Dictionary) -> void:
	if not table.has(item_id):
		push_warning("WorkshopMenu: unknown part '%s'" % item_id)
		return
	_staged[slot] = item_id
	for choice_id: StringName in table:
		_choices[choice_id].mark_staged(choice_id == item_id)
	_preview(_staged)


func _on_pressed(choice: WorkshopChoice) -> void:
	if Engine.get_process_frames() == _opened_frame:
		return
	AudioDirector.play_ui(&"menu_confirm")
	if _hilts.has(choice.item_id):
		select_hilt(choice.item_id)
	else:
		select_blade(choice.item_id)


func _on_focused(choice: WorkshopChoice) -> void:
	AudioDirector.play_ui(&"menu_move")
	var pair: Array[StringName] = _staged.duplicate()
	pair[0 if _hilts.has(choice.item_id) else 1] = choice.item_id
	_preview(pair)


func _preview(pair: Array[StringName]) -> void:
	_shown = pair.duplicate()
	var hilt: HiltDef = _hilts[pair[0]]
	_rows = WorkshopStats.rows(_base, Djanbeyyah.equip(_base, hilt, _blades[pair[1]]))
	var move := ContentDB.get_def("action", hilt.ability) as ActionDef
	_panel.show_pair(_rows, tr(move.name_key), tr("MOVE_DESC_" + String(hilt.ability).to_upper()))


func _close() -> void:
	visible = false
	closed.emit()


func _build() -> void:
	_back = ColorRect.new()
	_back.color = _style.backdrop
	add_child(_back)
	var page := WorkshopPage.new()
	page.build(_style, _hilts, _blades)
	_back.add_child(page)
	_panel = page.panel
	_choices = page.choices
	for choice: WorkshopChoice in _choices.values():
		choice.pressed.connect(_on_pressed.bind(choice))
		choice.focus_entered.connect(_on_focused.bind(choice))
	page.confirm_button.pressed.connect(confirm)
	page.confirm_button.focus_entered.connect(_on_confirm_focused)
	get_viewport().size_changed.connect(_fit)
	_fit()


## Draws the layout for design_width x design_height; a smaller window scales the whole menu down to fit.
func _fit() -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	var factor: float = minf(1.0, minf(size.x / _style.design_width, size.y / _style.design_height))
	scale = Vector2(factor, factor)
	_back.size = size / factor


func _on_confirm_focused() -> void:
	_preview(_staged)
