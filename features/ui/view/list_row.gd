class_name ListRow
extends Button
## One row of a menu list: icon | name (rarity colour) | "x3" count | tag chip on the right. Focus shows the brass
## bar from the theme and the qamariya sweep; a disabled row greys its name. Use: Ui.list_row(icon, name, 3, colour, "HP+60").

var _name: Label
var _count: Label


## icon may be null; count below zero hides the count; tag empty = no chip.
func setup(icon: Texture2D, label: String, count: int, colour: Color, tag: String) -> ListRow:
	var style: UiStyleDef = Ui.style()
	custom_minimum_size.y = style.size(&"s_list_row_h")
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	var line := HBoxContainer.new()
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", style.size(&"s_pad"))
	line.offset_left = style.size(&"s_pad")
	add_child(line)
	var picture := TextureRect.new()
	picture.texture = icon
	picture.custom_minimum_size = Vector2.ONE * (style.size(&"s_icon") - style.size(&"s_pad"))
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.visible = icon != null
	line.add_child(picture)
	_name = Ui.label(label, &"NameLabel", colour)
	_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(_name)
	_count = Ui.label("x%d" % count, &"NumberLabel", style.colour(&"c_muted"))
	_count.visible = count >= 0
	line.add_child(_count)
	if not tag.is_empty():
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", UiBoxes.pill(style, style.colour(&"c_cyan")))
		chip.add_child(Ui.label(tag, &"SmallLabel"))
		line.add_child(Ui.chip_row([chip] as Array[Control]))
	focus_entered.connect(UiSweep.start.bind(self))
	focus_exited.connect(UiSweep.clear.bind(self))
	mouse_entered.connect(grab_focus)
	return self


## Enables or disables the row; a disabled row greys its name and count.
func set_enabled(on: bool) -> void:
	disabled = not on
	if not on:
		var grey: Color = Ui.style().colour(&"c_disabled")
		_name.add_theme_color_override("font_color", grey)
		_count.add_theme_color_override("font_color", grey)


func name_text() -> String:
	return _name.text


func count_text() -> String:
	return _count.text if _count.visible else ""
