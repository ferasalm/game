class_name BattlePartyPanel
extends VBoxContainer
## The party panel (bottom right, compact): per hero an ornate name plate beside an HP bar (red to orange) and an
## SP bar (blue to cyan), each with its numbers in Reem Kufi. The hero waiting for a command gets the brighter
## frame. HP shown follows the played events, not the sim's finished tick.


class Row extends RefCounted:
	var unit: UnitState
	var panel: PanelContainer
	var name_label: Label
	var hp_bar: ProgressBar
	var hp_text: Label
	var sp_bar: ProgressBar
	var sp_text: Label
	var active: bool = false


var _sim: BattleSim
var _view: BattleViewDef
var _shown_hp: Dictionary[StringName, int]
var _rows: Array[Row] = []


func setup(sim: BattleSim, view: BattleViewDef, shown_hp: Dictionary[StringName, int]) -> void:
	_sim = sim
	_view = view
	_shown_hp = shown_hp
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_right = -view.margin
	offset_bottom = -view.margin
	offset_top = -view.margin
	offset_left = -view.margin - view.party_panel_width
	add_theme_constant_override("separation", roundi(view.margin / 2.0))
	for unit: UnitState in sim.timeline.units:
		if unit.side == 0:
			_rows.append(_add_row(unit))


func row_count() -> int:
	return _rows.size()


func active_unit() -> StringName:
	for row: Row in _rows:
		if row.active:
			return row.unit.unit_id
	return &""


func _process(_delta: float) -> void:
	if _sim == null:
		return
	var waiting: UnitState = _sim.waiting_hero()
	for row: Row in _rows:
		var hp: int = _shown_hp.get(row.unit.unit_id, 0)
		row.hp_bar.value = hp
		row.hp_text.text = "%d/%d" % [hp, row.unit.def.max_hp]
		row.sp_bar.value = row.unit.sp
		row.sp_text.text = "%d/%d" % [row.unit.sp, row.unit.def.max_sp]
		var now_active: bool = waiting == row.unit
		if now_active != row.active:
			_set_active(row, now_active)


func _set_active(row: Row, on: bool) -> void:
	row.active = on
	row.panel.add_theme_stylebox_override("panel", UiBoxes.panel(Ui.style(), &"plate" if on else &"panel"))
	var gold: Color = Ui.style().colour(&"c_brass")
	row.name_label.add_theme_color_override("font_color", gold if on else Ui.style().colour(&"c_text"))


func _add_row(unit: UnitState) -> Row:
	var row := Row.new()
	row.unit = unit
	row.panel = PanelContainer.new()
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", _view.margin)
	row.panel.add_child(line)
	row.name_label = BattleStyle.label(BattleStyle.unit_name(_sim, unit), &"NameLabel")
	row.name_label.custom_minimum_size.x = _view.margin * 5.0
	row.name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(row.name_label)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(box)
	row.hp_bar = _stat(box, BattleStyle.text("UI_HP"), &"HpBar", unit.def.max_hp)
	row.hp_text = row.hp_bar.get_meta("text") as Label
	row.sp_bar = _stat(box, BattleStyle.text("UI_SP"), &"SpBar", unit.def.max_sp)
	row.sp_text = row.sp_bar.get_meta("text") as Label
	add_child(row.panel)
	return row


## One line: tag, bar, numbers. The numbers label is stored on the bar as meta "text".
func _stat(parent: Control, tag: String, kind: StringName, max_value: int) -> ProgressBar:
	var line := HBoxContainer.new()
	var tag_label: Label = BattleStyle.label(tag, &"CaptionLabel")
	tag_label.custom_minimum_size.x = _view.margin * 1.6
	line.add_child(tag_label)
	var bar: ProgressBar = BattleStyle.bar(_view, kind)
	bar.max_value = max_value
	line.add_child(bar)
	var numbers: Label = BattleStyle.label("", &"NumberLabel")
	numbers.custom_minimum_size.x = _view.margin * 4.2
	numbers.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(numbers)
	bar.set_meta("text", numbers)
	parent.add_child(line)
	return bar
