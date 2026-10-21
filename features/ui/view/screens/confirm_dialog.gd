class_name ConfirmDialog
extends UiScreen
## A centred Yes/No question over the scrim. The safe button has focus (default_yes false = "No"); back means No.
## Use: var d := ConfirmDialog.new(); d.setup(title_key, body_key, false); Screens.push(d); await d.answered
## (Ui.confirm does exactly that).

## Emitted once with the answer, just before the dialog closes.
signal answered(yes: bool)

var _title_key: String = ""
var _body_key: String = ""
var _default_yes: bool = false
var _yes: Button
var _no: Button


func setup(title_key: String, body_key: String, default_yes: bool = false) -> void:
	_title_key = title_key
	_body_key = body_key
	_default_yes = default_yes
	layer_id = UiLayers.CONFIRM


func build(_args: Dictionary) -> void:
	var style: UiStyleDef = Ui.style()
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var panel: UiPanel = Ui.panel(Ui.text(_title_key))
	panel.custom_minimum_size.x = style.size(&"s_confirm_w")
	centre.add_child(panel)
	var body_label: Label = Ui.label(Ui.text(_body_key))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.body.add_child(body_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", style.size(&"s_pad"))
	panel.body.add_child(row)
	_yes = _button(row, "PAUSE_YES", true)
	_no = _button(row, "PAUSE_NO", false)


func focus_default() -> void:
	if _yes != null:
		(_yes if _default_yes else _no).grab_focus()


func on_back() -> bool:
	answer(false)
	return true


## Gives the answer and closes (also what the buttons call).
func answer(yes: bool) -> void:
	if is_closing():
		return
	answered.emit(yes)
	close(yes)


func yes_button() -> Button:
	return _yes


func no_button() -> Button:
	return _no


func _button(row: HBoxContainer, key: String, yes: bool) -> Button:
	var button := Button.new()
	button.text = Ui.text(key)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = Ui.style().size(&"s_button_h")
	button.pressed.connect(answer.bind(yes))
	sweep_on_focus(button)
	row.add_child(button)
	return button
