class_name ChoiceScreen
extends UiScreen
## Base of the small centred "pick one" screens (Sabil, Defeat): a framed panel with the Arabic + English title pair
## and a column of buttons in focus order. Each button closes the screen with its result (pressing = choose).

var _choices: Array[Button] = []
var _results: Array[StringName] = []
var _default_index: int = 0


## A centred framed panel of the given width (and height when above zero); content goes into its body.
func centred_panel(title_en: String, title_ar: String, width: int, height: int = 0) -> UiPanel:
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var panel: UiPanel = Ui.panel(title_en, title_ar)
	panel.custom_minimum_size = Vector2(width, height)
	centre.add_child(panel)
	return panel


## Adds a button that closes the screen with `result`; enabled false greys it and skips it in focus order.
func add_choice(parent: Control, label_key: String, result: StringName, enabled: bool = true) -> Button:
	var button := Button.new()
	button.text = Ui.text(label_key)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = Ui.style().size(&"s_list_row_h")
	button.disabled = not enabled
	button.pressed.connect(choose.bind(result))
	button.mouse_entered.connect(_hover.bind(button))
	sweep_on_focus(button)
	parent.add_child(button)
	_choices.append(button)
	_results.append(result)
	return button


## Closes with a result (what pressing its button does).
func choose(result: StringName) -> void:
	AudioDirector.play_ui(&"ui_confirm")
	close(result)


## The buttons in focus order and the result each one gives.
func choices() -> Array[Button]:
	return _choices


func results() -> Array[StringName]:
	return _results


func set_default(index: int) -> void:
	_default_index = index


func focus_default() -> void:
	if _default_index < _choices.size() and not _choices[_default_index].disabled:
		_choices[_default_index].grab_focus()


func _hover(button: Button) -> void:
	if not button.disabled:
		button.grab_focus()
