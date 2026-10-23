class_name DialogueChoiceList
extends RefCounted
## Manages the focusable button list for dialogue choices.

var buttons: Array[Button] = []
var container: VBoxContainer


func _init(choice_container: VBoxContainer) -> void:
	container = choice_container


func show_choices(choices: Array[DialogueChoice], on_picked: Callable) -> void:
	clear()
	if container == null:
		return
	container.visible = true
	for i: int in choices.size():
		var choice: DialogueChoice = choices[i]
		var btn := Button.new()
		btn.text = Ui.text(choice.text_key)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(Ui.style().size(&"s_confirm_w"), Ui.style().size(&"s_list_row_h"))
		btn.pressed.connect(on_picked.bind(i))
		btn.mouse_entered.connect(btn.grab_focus)
		container.add_child(btn)
		buttons.append(btn)
	if not buttons.is_empty():
		buttons[0].grab_focus()


func clear() -> void:
	for btn: Button in buttons:
		btn.queue_free()
	buttons.clear()
	if container != null:
		container.visible = false
