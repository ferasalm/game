class_name BattleEndPanel
extends PanelContainer
## The end-of-battle panel in the middle of the screen. Victory: the spoils (new items in their rarity colours,
## from set_loot) and Continue. Defeat: Retry or Back to the rooftop.

## The player's pick: &"victory" (continue), &"retry" or &"defeat" (back to the rooftop).
signal picked(result: StringName)

var _view: BattleViewDef
var _title: Label
var _loot_box: VBoxContainer
var _row: HBoxContainer
var _buttons: Array[Button] = []
var _loot: Array[StringName] = []
var _shown_loot: Array[StringName] = []


func setup(view: BattleViewDef) -> void:
	_view = view
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", view.margin)
	box.custom_minimum_size.x = view.menu_width
	add_child(box)
	_title = BattleStyle.label("", &"BannerLabel")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	box.add_child(Ui.divider())
	_loot_box = VBoxContainer.new()
	box.add_child(_loot_box)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", view.margin)
	box.add_child(_row)
	visible = false


## The guaranteed loot of this fight (item ids); on a victory the ones not owned yet are listed.
func set_loot(item_ids: Array[StringName]) -> void:
	_loot = item_ids


## The item ids the panel lists right now (victory only).
func shown_loot() -> Array[StringName]:
	return _shown_loot


func show_result(result: StringName) -> void:
	visible = true
	AudioDirector.play_sfx(result)
	_title.text = BattleStyle.text("UI_VICTORY" if result == &"victory" else "UI_DEFEAT")
	for button: Button in _buttons:
		_row.remove_child(button)
		button.queue_free()
	_buttons.clear()
	_fill_loot(result == &"victory")
	if result == &"victory":
		_add("UI_CONTINUE", &"victory")
	else:
		_add("UI_RETRY", &"retry")
		_add("UI_BACK_TO_ROOFTOP", &"defeat")
	_buttons[0].grab_focus()


## The buttons now showing, in order.
func buttons() -> Array[Button]:
	return _buttons


func _fill_loot(won: bool) -> void:
	for child: Node in _loot_box.get_children():
		_loot_box.remove_child(child)
		child.queue_free()
	_shown_loot = []
	if won:
		for item_id: StringName in _loot:
			if not GameState.inventory.has(item_id):
				_shown_loot.append(item_id)
	_loot_box.visible = not _shown_loot.is_empty()
	if _shown_loot.is_empty():
		return
	_loot_box.add_child(BattleStyle.label(BattleStyle.text("UI_SPOILS"), &"CaptionLabel"))
	for item_id: StringName in _shown_loot:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", _view.margin)
		line.add_child(UiRarity.item_label(item_id))
		line.add_child(UiRarity.tag(UiRarity.of_item(item_id)))
		_loot_box.add_child(line)


func _add(key: String, result: StringName) -> void:
	var button := Button.new()
	button.text = BattleStyle.text(key)
	button.custom_minimum_size = Vector2(_view.menu_width / 3.0, Ui.style().size(&"s_button_h") * 1.2)
	button.pressed.connect(_pick.bind(result))
	_row.add_child(button)
	_buttons.append(button)


func _pick(result: StringName) -> void:
	picked.emit(result)
