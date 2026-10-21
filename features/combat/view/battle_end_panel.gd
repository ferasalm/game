class_name BattleEndPanel
extends PanelContainer
## The end-of-battle panel in the middle of the screen. Victory: Continue. Defeat: Retry or Back to the rooftop.

## The player's pick: &"victory" (continue), &"retry" or &"defeat" (back to the rooftop).
signal picked(result: StringName)

var _view: BattleViewDef
var _title: Label
var _row: HBoxContainer
var _buttons: Array[Button] = []


func setup(view: BattleViewDef) -> void:
	_view = view
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	add_theme_stylebox_override("panel", BattleStyle.panel(view, view.highlight_color))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", view.margin)
	box.custom_minimum_size.x = view.menu_width
	add_child(box)
	_title = BattleStyle.label("", view.highlight_color)
	_title.add_theme_font_size_override("font_size", roundi(view.banner_font_size / 2.0))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", view.margin)
	box.add_child(_row)
	visible = false


func show_result(result: StringName) -> void:
	visible = true
	AudioDirector.play_sfx(result)
	_title.text = BattleStyle.text("UI_VICTORY" if result == &"victory" else "UI_DEFEAT")
	for button: Button in _buttons:
		_row.remove_child(button)
		button.queue_free()
	_buttons.clear()
	if result == &"victory":
		_add("UI_CONTINUE", &"victory")
	else:
		_add("UI_RETRY", &"retry")
		_add("UI_BACK_TO_ROOFTOP", &"defeat")
	_buttons[0].grab_focus()


## The buttons now showing, in order.
func buttons() -> Array[Button]:
	return _buttons


func _add(key: String, result: StringName) -> void:
	var button := Button.new()
	button.text = BattleStyle.text(key)
	button.custom_minimum_size = Vector2(_view.menu_width / 3.0, _view.margin * 2.5)
	button.pressed.connect(_pick.bind(result))
	_row.add_child(button)
	_buttons.append(button)


func _pick(result: StringName) -> void:
	picked.emit(result)
