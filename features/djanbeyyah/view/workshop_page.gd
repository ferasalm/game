class_name WorkshopPage
extends MarginContainer
## The workshop layout: title, a hilt column, a blade column, the stats panel, and the Confirm button with the
## back hint. Only builds; WorkshopMenu connects the buttons and owns the choices.

var choices: Dictionary[StringName, WorkshopChoice] = {}
var panel: WorkshopStatsPanel
var confirm_button: Button
var _style: WorkshopStyleDef


func build(style: WorkshopStyleDef, hilts: Dictionary[StringName, HiltDef], blades: Dictionary[StringName, BladeDef]) -> void:
	_style = style
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		add_theme_constant_override("margin_" + side, style.margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", style.gap)
	add_child(page)
	page.add_child(_label(tr("WORKSHOP_TITLE"), style.title_size, style.current))
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", style.gap)
	page.add_child(body)
	var hilt_column: VBoxContainer = _column("WORKSHOP_HILTS", body)
	for hilt: HiltDef in hilts.values():
		_add_choice(hilt_column, hilt.id, hilt.name_key, hilt.desc_key)
	var blade_column: VBoxContainer = _column("WORKSHOP_BLADES", body)
	for blade: BladeDef in blades.values():
		_add_choice(blade_column, blade.id, blade.name_key, blade.desc_key)
	panel = WorkshopStatsPanel.new()
	panel.build(style)
	body.add_child(panel)
	page.add_child(_footer())


func _column(heading_key: String, body: HBoxContainer) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", _style.gap)
	column.add_child(_label(tr(heading_key), _style.heading_size, _style.muted))
	body.add_child(column)
	return column


func _add_choice(column: VBoxContainer, item_id: StringName, name_key: String, desc_key: String) -> void:
	var choice := WorkshopChoice.new()
	choice.setup(_style, item_id, tr(name_key), tr(desc_key))
	column.add_child(choice)
	choices[item_id] = choice


func _footer() -> HBoxContainer:
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", _style.gap)
	confirm_button = Button.new()
	confirm_button.text = tr("WORKSHOP_CONFIRM")
	confirm_button.custom_minimum_size = Vector2(_style.confirm_width, _style.confirm_height)
	confirm_button.add_theme_font_size_override("font_size", _style.button_size)
	footer.add_child(confirm_button)
	var hint := _label(tr("WORKSHOP_BACK_HINT"), _style.desc_size, _style.muted)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(hint)
	return footer


func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
