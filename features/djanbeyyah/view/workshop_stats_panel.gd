class_name WorkshopStatsPanel
extends PanelContainer
## The right-hand panel of the workshop: one line per stat (name, base value, value with the chosen pair, an
## up/down arrow in green or red) and below them the hilt's move with its description.

var _style: WorkshopStyleDef
var _grid: GridContainer
var _name_label: Label
var _desc_label: Label
var _cells: Array[Array] = []


func build(style: WorkshopStyleDef) -> void:
	_style = style
	custom_minimum_size.x = style.stats_width
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", style.gap)
	add_child(box)
	var panel := StyleBoxFlat.new()
	panel.bg_color = style.panel
	panel.set_content_margin_all(style.gap)
	panel.set_corner_radius_all(style.gap / 2)
	add_theme_stylebox_override("panel", panel)
	box.add_child(_text(tr("WORKSHOP_STATS"), style.heading_size, style.current))
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", style.gap)
	box.add_child(_grid)
	box.add_child(_text(tr("WORKSHOP_ABILITY"), style.heading_size, style.current))
	_name_label = _text("", style.ability_size + 4, style.text)
	box.add_child(_name_label)
	_desc_label = _text("", style.ability_size, style.muted)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_desc_label)


func show_pair(rows: Array[StatRow], move_name: String, move_desc: String) -> void:
	while _cells.size() < rows.size():
		_add_row()
	for i: int in rows.size():
		_fill(_cells[i], rows[i])
	_name_label.text = move_name
	_desc_label.text = move_desc


## One string per row, as shown: "label | base | value | arrow".
func texts() -> PackedStringArray:
	var out := PackedStringArray()
	for cell: Array in _cells:
		var parts := PackedStringArray()
		for label: Label in cell:
			parts.append(label.text)
		out.append(" | ".join(parts))
	return out


func move_name() -> String:
	return _name_label.text


func _add_row() -> void:
	var cell: Array = []
	for column: int in 4:
		var label := _text("", _style.stat_size, _style.text)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL if column == 0 else Control.SIZE_SHRINK_END
		_grid.add_child(label)
		cell.append(label)
	_cells.append(cell)


func _fill(cell: Array, row: StatRow) -> void:
	var direction: int = row.direction()
	var color: Color = _style.neutral if row.neutral else (_style.up if direction > 0 else _style.down)
	(cell[0] as Label).text = tr(row.label_key)
	(cell[1] as Label).text = row.format(row.before)
	(cell[1] as Label).add_theme_color_override("font_color", _style.muted)
	(cell[2] as Label).text = row.format(row.after)
	(cell[2] as Label).add_theme_color_override("font_color", _style.text if direction == 0 else color)
	(cell[3] as Label).text = "" if direction == 0 else tr("WORKSHOP_UP" if direction > 0 else "WORKSHOP_DOWN")
	(cell[3] as Label).add_theme_color_override("font_color", color)


func _text(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
