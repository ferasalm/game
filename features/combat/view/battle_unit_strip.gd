class_name BattleUnitStrip
extends Control
## One slim vitals strip under a fighter's feet: a name initial (the letter for same-kind foes) and a thin HP bar,
## for a hero also a thinner SP bar. It pulses and grows for a moment when told to (a hero just got hit).

var unit_id: StringName = &""
var _view: BattleViewDef
var _hp: ProgressBar
var _sp: ProgressBar = null
var _tween: Tween = null
var _initial: String = ""
var _colour: Color = Color.WHITE


## `initial` is the text at the left ("Z", or a foe's letter / ""), `hp_max` and `sp_max` size the bars (sp_max 0: no SP bar).
func setup(id: StringName, view: BattleViewDef, initial: String, hp_max: int, sp_max: int, colour: Color) -> void:
	unit_id = id
	_view = view
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hero: bool = sp_max > 0
	var width: float = view.strip_w if hero else view.foe_strip_w
	var height: float = view.strip_h if hero else view.foe_strip_h
	custom_minimum_size = Vector2(width, height)
	size = custom_minimum_size
	pivot_offset = size / 2.0
	var left: float = float(view.strip_initial) if not initial.is_empty() else 0.0
	_initial = initial
	_colour = colour
	var bars_h: float = view.hp_h + (view.sp_h + 2.0 if hero else 0.0)
	var top: float = (height - bars_h) / 2.0
	_hp = _add_bar(&"HpBar", Rect2(left, top, width - left, view.hp_h), hp_max)
	if hero:
		_sp = _add_bar(&"SpBar", Rect2(left, top + view.hp_h + 2.0, width - left, view.sp_h), sp_max)


## The initial is drawn here, not in a Label: a Label is never shorter than its font's line and would hang below the strip.
func _draw() -> void:
	if _initial.is_empty():
		return
	var font: Font = Ui.theme().get_font(&"font", &"CaptionLabel")
	var px: int = _view.letter_font + 4
	var baseline: float = (size.y + font.get_ascent(px) - font.get_descent(px)) / 2.0
	draw_string(font, Vector2(0.0, baseline), _initial, HORIZONTAL_ALIGNMENT_CENTER, _view.strip_initial, px, _colour)


func set_values(hp: int, sp: int) -> void:
	_hp.value = hp
	if _sp != null:
		_sp.value = sp


func hp_value() -> float:
	return _hp.value


func has_sp_bar() -> bool:
	return _sp != null


## The strip swells and settles again over pulse_seconds.
func pulse() -> void:
	if _tween != null:
		_tween.kill()
	if not is_inside_tree():
		return
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * _view.pulse_scale, _view.pulse_seconds * 0.3)
	_tween.tween_property(self, "scale", Vector2.ONE, _view.pulse_seconds * 0.7)


func pulsing() -> bool:
	return _tween != null and _tween.is_valid()


func _add_bar(kind: StringName, area: Rect2, maximum: int) -> ProgressBar:
	var bar: ProgressBar = BattleStyle.thin_bar(kind, int(area.size.y))
	bar.max_value = maximum
	bar.position = area.position
	bar.size = area.size
	add_child(bar)
	return bar
