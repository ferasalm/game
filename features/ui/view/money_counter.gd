class_name MoneyCounter
extends PanelContainer
## A pill with the riyal amount in brass. set_amount counts up or down over t_money_count and flashes green (more)
## or red (less). Use: Ui.money_counter().set_amount(1240, true).

var _label: Label
var _amount: int = 0
var _shown: int = 0
var _tween: Tween = null


func _init() -> void:
	var style: UiStyleDef = Ui.style()
	theme_type_variation = &"PlatePanel"
	custom_minimum_size.y = style.size(&"s_money_h")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", style.size(&"s_gap"))
	add_child(row)
	row.add_child(Ui.label(Ui.text("MONEY_GLYPH"), &"CaptionLabel"))
	_label = Ui.label("0", &"NumberLabel", style.colour(&"c_brass"))
	row.add_child(_label)


## Styles the money counter as a framed pill with rounded corners and brass border.
func set_pill_style() -> void:
	var style: UiStyleDef = Ui.style()
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(style.size(&"s_gap"))
	box.set_border_width_all(style.size(&"s_frame_line"))
	box.border_color = style.colour(&"c_brass")
	box.bg_color = style.colour(&"c_glass_menu")
	box.content_margin_left = style.size(&"s_pad")
	box.content_margin_right = style.size(&"s_pad")
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	add_theme_stylebox_override("panel", box)


## Sets the amount; with animate (and the pill in the tree) the shown number counts there.
func set_amount(amount: int, animate: bool = true) -> void:
	var style: UiStyleDef = Ui.style()
	var before: int = _amount
	_amount = maxi(amount, 0)
	if _tween != null:
		_tween.kill()
	if not animate or not is_inside_tree():
		_show(_amount)
		return
	var flash: Color = style.colour(&"c_good" if _amount >= before else &"c_bad")
	_tween = UiMotion.tween(self).set_parallel(true)
	_tween.tween_method(_show, float(_shown), float(_amount), style.time(&"t_money_count"))
	_label.add_theme_color_override("font_color", flash)
	_tween.tween_method(_tint.bind(flash), 0.0, 1.0, style.time(&"t_money_flash") + style.time(&"t_money_count"))


## The amount it is heading to (the shown number catches up).
func amount() -> int:
	return _amount


func shown_text() -> String:
	return _label.text


func _show(value: float) -> void:
	_shown = roundi(value)
	_label.text = PauseLogic.grouped(_shown)


func _tint(t: float, flash: Color) -> void:
	_label.add_theme_color_override("font_color", flash.lerp(Ui.style().colour(&"c_brass"), t))
