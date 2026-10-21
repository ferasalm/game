class_name EquipmentDetail
extends VBoxContainer
## The right-hand side of the equipment screen: the focused item (name in its rarity colour, tag, text, perk and the
## tech moves it teaches) above the stat comparison (base, with the staged kit, an up / down arrow).

const COLUMNS: int = 4

var _item_name: Label
var _tag_slot: HBoxContainer
var _desc: Label
var _perk_box: VBoxContainer
var _grants_box: VBoxContainer
var _stats_title: Label
var _grid: GridContainer
var _cells: Array[Array] = []


func build() -> void:
	var style: UiStyleDef = Ui.style()
	add_theme_constant_override("separation", style.size(&"s_gap"))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", style.size(&"s_pad"))
	add_child(head)
	_item_name = Ui.label("", &"TitleLabel")
	head.add_child(_item_name)
	_tag_slot = HBoxContainer.new()
	_tag_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_tag_slot)
	_desc = Ui.label("")
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_desc)
	_perk_box = VBoxContainer.new()
	add_child(_perk_box)
	_grants_box = VBoxContainer.new()
	add_child(_grants_box)
	add_child(Ui.divider())
	_stats_title = Ui.label("", &"CaptionLabel")
	add_child(_stats_title)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", style.size(&"s_margin"))
	add_child(_grid)


## Shows one item; item_id &"" clears it.
func show_item(item_id: StringName) -> void:
	var item := ContentDB.get_def("item", item_id) as EquipDef
	for tag: Node in _tag_slot.get_children():
		_tag_slot.remove_child(tag)
		tag.queue_free()
	_clear(_perk_box)
	_clear(_grants_box)
	if item == null:
		_item_name.text = ""
		_desc.text = ""
		return
	_item_name.text = Ui.text(item.name_key)
	_item_name.add_theme_color_override("font_color", UiRarity.colour(item.rarity))
	_tag_slot.add_child(UiRarity.tag(item.rarity))
	_desc.text = Ui.text(item.desc_key)
	_show_perk(item)
	_show_grants(item)


func item_name() -> String:
	return _item_name.text


## Fills the comparison for a hero ("Zayd with this kit").
func show_rows(hero_name: String, rows: Array[StatRow]) -> void:
	_stats_title.text = Ui.text("WORKSHOP_STATS_FOR") % hero_name
	while _cells.size() < rows.size():
		_add_row()
	for i: int in rows.size():
		_fill(_cells[i], rows[i])


## One string per row, as shown: "label | base | value | arrow".
func texts() -> PackedStringArray:
	var out := PackedStringArray()
	for cell: Array in _cells:
		var parts := PackedStringArray()
		for label: Label in cell:
			parts.append(label.text)
		out.append(" | ".join(parts))
	return out


func _show_perk(item: EquipDef) -> void:
	var perk := ContentDB.get_def("perk", item.perk) as PerkDef
	if perk == null:
		return
	_perk_box.add_child(Ui.label(Ui.text("WORKSHOP_PERK"), &"CaptionLabel"))
	_perk_box.add_child(Ui.label(Ui.text(perk.name_key), &"NameLabel", Ui.style().colour(&"c_brass")))
	_perk_box.add_child(_wrapped(Ui.text(perk.desc_key), &"MutedLabel"))


func _show_grants(item: EquipDef) -> void:
	var moves: Array[StringName] = []
	if item is HiltDef:
		moves.append((item as HiltDef).ability)
	elif item is ProstheticDef:
		moves = (item as ProstheticDef).actions
	if moves.is_empty():
		return
	_grants_box.add_child(Ui.label(Ui.text("WORKSHOP_GRANTS"), &"CaptionLabel"))
	for move_id: StringName in moves:
		var action := ContentDB.get_def("action", move_id) as ActionDef
		if action == null:
			continue
		var cost: String = "" if action.sp_cost <= 0 else "   %d %s" % [action.sp_cost, Ui.text("UI_SP")]
		_grants_box.add_child(Ui.label(Ui.text(action.name_key) + cost, &"NameLabel", Ui.style().colour(&"c_cyan")))
		_grants_box.add_child(_wrapped(Ui.text("MOVE_DESC_" + String(move_id).to_upper()), &"MutedLabel"))


func _wrapped(content: String, variant: StringName) -> Label:
	var label: Label = Ui.label(content, variant)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _clear(box: Control) -> void:
	for child: Node in box.get_children():
		box.remove_child(child)
		child.queue_free()


func _add_row() -> void:
	var cell: Array = []
	for column: int in COLUMNS:
		var label: Label = Ui.label("", &"NumberLabel")
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL if column == 0 else Control.SIZE_SHRINK_END
		_grid.add_child(label)
		cell.append(label)
	_cells.append(cell)


func _fill(cell: Array, row: StatRow) -> void:
	var style: UiStyleDef = Ui.style()
	var direction: int = row.direction()
	var tint: Color = style.colour(&"c_muted") if row.neutral else style.colour(&"c_good" if direction > 0 else &"c_bad")
	(cell[0] as Label).text = Ui.text(row.label_key)
	(cell[1] as Label).text = row.format(row.before)
	(cell[1] as Label).add_theme_color_override("font_color", style.colour(&"c_muted"))
	(cell[2] as Label).text = row.format(row.after)
	(cell[2] as Label).add_theme_color_override("font_color", style.colour(&"c_text") if direction == 0 else tint)
	(cell[3] as Label).text = "" if direction == 0 else Ui.text("WORKSHOP_UP" if direction > 0 else "WORKSHOP_DOWN")
	(cell[3] as Label).add_theme_color_override("font_color", tint)
