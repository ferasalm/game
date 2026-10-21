class_name PromptStrip
extends HBoxContainer
## The Hades-style button hints along the bottom: "[Enter] Select   [Esc] Back". Glyphs follow the last device the
## player used (keyboard or gamepad) and switch at once when it changes.
## Use: Ui.prompt_strip([{"key": "accept", "text": "UI_SELECT"}, ...]).

## True once a gamepad button was the last input; shared by every strip.
static var gamepad: bool = false

var _pairs: Array = []


func setup(pairs: Array) -> PromptStrip:
	_pairs = pairs
	add_theme_constant_override("separation", Ui.style().size(&"s_margin"))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild()
	return self


func _input(event: InputEvent) -> void:
	var pad: bool = event is InputEventJoypadButton or event is InputEventJoypadMotion
	if (pad or event is InputEventKey) and pad != gamepad:
		gamepad = pad
		_rebuild()


## The text of each hint as "glyph text" (for tests).
func hints() -> PackedStringArray:
	var out := PackedStringArray()
	for pair: Variant in _pairs:
		var data: Dictionary = pair
		out.append("%s %s" % [_glyph(StringName(data.get("key", ""))), Ui.text(String(data.get("text", "")))])
	return out


func _rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var style: UiStyleDef = Ui.style()
	for pair: Variant in _pairs:
		var data: Dictionary = pair
		var one := HBoxContainer.new()
		one.add_theme_constant_override("separation", style.size(&"s_gap"))
		var pill := PanelContainer.new()
		pill.add_theme_stylebox_override("panel", UiBoxes.pill(style, style.colour(&"c_brass")))
		pill.custom_minimum_size.y = style.size(&"s_key_icon")
		pill.add_child(Ui.label(_glyph(StringName(data.get("key", ""))), &"CaptionLabel"))
		one.add_child(pill)
		one.add_child(Ui.label(Ui.text(String(data.get("text", ""))), &"MutedLabel"))
		add_child(one)


func _glyph(action: StringName) -> String:
	var key: String = PromptGlyph.key(action, gamepad)
	var shown: String = Ui.text(key)
	return String(action).to_upper() if shown == key else shown
