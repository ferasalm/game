class_name BattleItemMenu
extends PanelContainer
## The Items list of the command menu (in the turn panel, in place of the move list): one row per herb the bag holds (name, the
## count still free, its effect), then the targets of the picked herb (the party herb skips them). Back returns
## from the targets to the rows, and from the rows to the command menu. The sim answers every rule question.

## The player committed to this herb and target (&"" for the whole-party herb); the stage calls BattleSim.choose_item.
signal chosen(item_id: StringName, target_id: StringName)
## The focused target changed (&"" when leaving the target list); the stage moves the 3D marker.
signal target_focused(unit_id: StringName)
## The line under the menu changed: the focused herb's effect, or (warning) why a choice was refused.
signal help_changed(text: String, warning: bool)
## Back out of the row list: the command menu shows again.
signal closed

var _sim: BattleSim
var _view: BattleViewDef
var _hero: UnitState
var _item: ConsumableDef = null
var _open: bool = false
var _title: Label
var _list: VBoxContainer
var _help: String = ""
var _rows: Array[Button] = []


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


func open(hero: UnitState) -> void:
	_hero = hero
	_open = true
	visible = true
	_show_rows(null)


func close() -> void:
	_open = false
	visible = false
	_item = null
	_clear()


## The herb rows (empty while the target list shows). Each has meta "item_id".
func item_buttons() -> Array[Button]:
	return _rows if _open and _item == null else ([] as Array[Button])


## The target buttons (empty while the row list shows). Each has meta "unit_id".
func target_buttons() -> Array[Button]:
	return _rows if _open and _item != null else ([] as Array[Button])


## Shows why a choice was refused (under the rows).
func show_notice(content: String) -> void:
	_say(content, true)


## The help line now showing (an herb's effect, or why a choice was refused).
func help_text() -> String:
	return _help


func _say(content: String, warning: bool) -> void:
	_help = content
	help_changed.emit(content, warning)


## Back one level: targets to rows, rows to the command menu.
func back() -> void:
	if not _open:
		return
	AudioDirector.play_ui(&"menu_cancel")
	if _item != null:
		var previous: ConsumableDef = _item
		target_focused.emit(&"")
		_show_rows(previous)
	else:
		close()
		closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()


func _show_rows(focus_item: ConsumableDef) -> void:
	_item = null
	_clear()
	_title.add_theme_font_size_override("font_size", _view.menu_font + 4)
	_title.text = BattleStyle.text("BATTLE_ITEMS")
	var colour: Color = Ui.style().colour(&"c_gypsum")
	for def: ConsumableDef in _sim.items.listed():
		var row: ListRow = Ui.list_row(null, BattleStyle.text(def.name_key), _sim.items.available(def.id), colour,
			_effect_tag(def)) as ListRow
		row.set_meta("item_id", def.id)
		row.custom_minimum_size.y = _view.turn_row_h
		BattleStyle.compact_button(row, _view)
		row.set_enabled(_sim.items.available(def.id) > 0 and not _sim.items.valid_targets(_hero, def).is_empty())
		row.pressed.connect(_pick.bind(def))
		row.focus_entered.connect(_describe.bind(def))
		_list.add_child(row)
		_rows.append(row)
	var first: Button = BattleMenuChips.first_enabled(_rows, focus_item.id if focus_item != null else &"", "item_id")
	if first != null:
		first.grab_focus()


func _pick(def: ConsumableDef) -> void:
	if def.target == &"all_allies":
		chosen.emit(def.id, &"")
		return
	_item = def
	_clear()
	_title.add_theme_font_size_override("font_size", _view.menu_font + 4)
	_title.text = BattleStyle.text("UI_PICK_TARGET")
	for target: UnitState in _sim.items.valid_targets(_hero, def):
		var button: Button = BattleMenuChips.button(_list, BattleStyle.unit_name(_sim, target),
			[Ui.label("%s %d" % [Ui.text("UI_HP"), target.hp], &"NumberLabel", Ui.style().colour(&"c_hp_b"))] as Array[Control],
			_view)
		button.set_meta("unit_id", target.unit_id)
		button.pressed.connect(confirm.bind(target.unit_id))
		button.focus_entered.connect(target_focused.emit.bind(target.unit_id))
		_rows.append(button)
	var first: Button = BattleMenuChips.first_enabled(_rows, &"", "unit_id")
	if first != null:
		first.grab_focus()


## A target was confirmed (its button pressed): the stage commits the choice to the sim.
func confirm(target_id: StringName) -> void:
	if _open and _item != null:
		chosen.emit(_item.id, target_id)


func _describe(def: ConsumableDef) -> void:
	_say(BattleStyle.text(def.desc_key) if not def.desc_key.is_empty() else "", false)


## The herb's main effect as a short tag: "HP +120", "SP +12", "Revives in battle".
func _effect_tag(def: ConsumableDef) -> String:
	if def.revive:
		return Ui.text("ITEMS_EFFECT_REVIVE")
	if def.hp > 0:
		return Ui.text("ITEMS_EFFECT_HP") % def.hp
	return Ui.text("ITEMS_EFFECT_SP") % def.sp


func _clear() -> void:
	for button: Button in _rows:
		_list.remove_child(button)
		button.queue_free()
	_rows.clear()
	_say("", false)
