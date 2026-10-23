class_name ShopKeeperBox
extends PanelContainer
## Keeper box: portrait 220x260 and typed greeting in a glass box at (80,720) 620x260.

var _portrait: TextureRect
var _dialogue_label: Label


func _init() -> void:
	var style: UiStyleDef = Ui.style()
	custom_minimum_size = Vector2(620, 260)
	size = Vector2(620, 260)
	add_theme_stylebox_override("panel", UiBoxes.panel(style, &"glass"))

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", style.size(&"s_pad"))
	add_child(line)

	var port_box := PanelContainer.new()
	port_box.custom_minimum_size = Vector2(220, 260)
	port_box.size = Vector2(220, 260)
	port_box.add_theme_stylebox_override("panel", UiBoxes.panel(style, &"inset"))
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(220, 260)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	port_box.add_child(_portrait)
	line.add_child(port_box)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_child(text_box)

	_dialogue_label = Ui.label("", &"")
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(_dialogue_label)


func setup_portrait(speaker: StringName) -> void:
	_portrait.texture = Portraits.texture(speaker, &"neutral")


func set_text(content: String) -> void:
	_dialogue_label.text = content


func get_text() -> String:
	return _dialogue_label.text


func portrait_rect() -> TextureRect:
	return _portrait
