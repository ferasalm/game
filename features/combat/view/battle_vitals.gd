class_name BattleVitals
extends VBoxContainer
## A name line over a thin HP bar and an optional thin SP bar, with the numbers beside them when wanted. The body of
## the acting hero's card and of the info card: show_unit() sets who it is about, update() the shown values.

var _view: BattleViewDef
var _name: Label
var _rows: BoxContainer
var _hp_row: HBoxContainer
var _sp_row: HBoxContainer
var _hp: ProgressBar
var _sp: ProgressBar
var _hp_text: Label
var _sp_text: Label


## stacked: HP over SP; otherwise the two side by side (the hero's turn card, which has little height to spare).
func setup(view: BattleViewDef, stacked: bool = true) -> void:
	_view = view
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name = BattleStyle.label("", &"NameLabel")
	_name.add_theme_font_size_override("font_size", view.card_name_font)
	add_child(_name)
	_rows = BoxContainer.new()
	_rows.vertical = stacked
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows.add_theme_constant_override("separation", view.card_bar_h)
	add_child(_rows)
	_hp_row = _row("UI_HP", &"HpBar")
	_hp = _hp_row.get_meta("bar")
	_hp_text = _hp_row.get_meta("numbers")
	_sp_row = _row("UI_SP", &"SpBar")
	_sp = _sp_row.get_meta("bar")
	_sp_text = _sp_row.get_meta("numbers")


## numbers: show "hp/max" beside the bars; max_sp 0 hides the SP row (a foe has none).
func show_unit(unit_name: String, max_hp: int, max_sp: int, numbers: bool) -> void:
	_name.text = unit_name
	_hp.max_value = max_hp
	_sp.max_value = maxi(max_sp, 1)
	_sp_row.visible = max_sp > 0
	_hp_text.visible = numbers
	_sp_text.visible = numbers


func update(hp: int, sp: int) -> void:
	_hp.value = hp
	_sp.value = sp
	_hp_text.text = "%d/%d" % [hp, int(_hp.max_value)]
	_sp_text.text = "%d/%d" % [sp, int(_sp.max_value)]


func name_text() -> String:
	return _name.text


func hp_text() -> String:
	return _hp_text.text


func sp_text() -> String:
	return _sp_text.text


func has_sp_row() -> bool:
	return _sp_row.visible


func _row(tag_key: String, kind: StringName) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag: Label = BattleStyle.label(BattleStyle.text(tag_key), &"CaptionLabel")
	tag.add_theme_font_size_override("font_size", _view.card_font - 2)
	tag.custom_minimum_size.x = _view.card_bar_h * 2.2
	line.add_child(tag)
	var bar: ProgressBar = BattleStyle.thin_bar(kind, _view.card_bar_h)
	line.add_child(bar)
	var numbers: Label = BattleStyle.label("", &"NumberLabel")
	numbers.add_theme_font_size_override("font_size", _view.card_font)
	numbers.custom_minimum_size.x = _view.card_font * 3.6
	numbers.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(numbers)
	line.set_meta("bar", bar)
	line.set_meta("numbers", numbers)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_child(line)
	return line
