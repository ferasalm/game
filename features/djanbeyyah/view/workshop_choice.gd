class_name WorkshopChoice
extends Button
## One hilt or blade on the bench: its name and a short description on a panel. A gold frame marks the staged
## choice and an "Equipped" tag marks the part Zayd wears now. Focus shows a light frame.

var item_id: StringName = &""
var _style: WorkshopStyleDef
var _tag: Label


func setup(style: WorkshopStyleDef, def_id: StringName, name_text: String, desc_text: String) -> void:
	_style = style
	item_id = def_id
	custom_minimum_size = Vector2(style.column_width, style.button_height)
	focus_mode = Control.FOCUS_ALL
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = style.gap
	box.offset_right = -style.gap
	box.offset_top = style.gap / 2.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	var title := _label(name_text, style.button_size, style.text)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_tag = _label(tr("WORKSHOP_EQUIPPED"), style.desc_size, style.current)
	_tag.visible = false
	head.add_child(_tag)
	var desc := _label(desc_text, style.desc_size, style.muted)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc)
	mark_staged(false)


## Shows or hides the "Equipped" tag (this is the part Zayd wears now).
func mark_current(on: bool) -> void:
	_tag.visible = on


## Gold frame on (this is the choice that Confirm will save) or off.
func mark_staged(on: bool) -> void:
	var frame: Color = _style.current if on else Color(0, 0, 0, 0)
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		add_theme_stylebox_override(state, _box(frame))
	add_theme_stylebox_override("focus", _box(_style.text))


func _box(frame: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = _style.panel
	box.set_border_width_all(_style.border)
	box.border_color = frame
	box.set_corner_radius_all(_style.gap / 2)
	return box


func _label(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
