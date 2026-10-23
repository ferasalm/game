class_name ShopSummary
extends PanelContainer
## Shop summary panel at (1440,140) 400x420: quantity, owned, price, money after (c_bad when < 0).

var _qty: Label
var _owned: Label
var _price: Label
var _after: Label


func _init() -> void:
	var style: UiStyleDef = Ui.style()
	custom_minimum_size = Vector2(400, 420)
	size = Vector2(400, 420)
	add_theme_stylebox_override("panel", UiBoxes.panel(style, &"glass"))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", style.size(&"s_pad"))
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)

	box.add_child(Ui.label(Ui.text("SHOP_QTY"), &"TitleLabel", style.colour(&"c_brass")))

	var qty_row := HBoxContainer.new()
	qty_row.alignment = BoxContainer.ALIGNMENT_CENTER
	qty_row.add_theme_constant_override("separation", style.size(&"s_pad"))

	var left_pill := PanelContainer.new()
	left_pill.add_theme_stylebox_override("panel", UiBoxes.pill_button(style, &"normal"))
	left_pill.add_child(Ui.label("<", &"TitleLabel", style.colour(&"c_brass")))
	qty_row.add_child(left_pill)

	_qty = Ui.label("01", &"TitleLabel")
	_qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty_row.add_child(_qty)

	var right_pill := PanelContainer.new()
	right_pill.add_theme_stylebox_override("panel", UiBoxes.pill_button(style, &"normal"))
	right_pill.add_child(Ui.label(">", &"TitleLabel", style.colour(&"c_brass")))
	qty_row.add_child(right_pill)

	box.add_child(qty_row)
	box.add_child(Ui.divider())

	_owned = Ui.label("", &"NameLabel")
	box.add_child(_owned)

	_price = Ui.label("", &"NameLabel")
	box.add_child(_price)

	_after = Ui.label("", &"NameLabel")
	box.add_child(_after)


func show_summary(def: ConsumableDef, price: int, qty: int, money: int, owned: int, selling: bool) -> void:
	if def == null:
		_qty.text = "00"
		_owned.text = ""
		_price.text = ""
		_after.text = ""
		return

	var after: int = money + (price * qty if selling else -price * qty)
	var style: UiStyleDef = Ui.style()
	_qty.text = "%02d" % qty
	_owned.text = "%s: %d / %d" % [Ui.text("SHOP_OWNED"), owned, def.max_stack]
	_price.text = "%s: %d %s" % [Ui.text("SHOP_PRICE"), price * qty, Ui.text("UI_RIYAL")]
	_after.text = "%s: %d -> %d" % [Ui.text("SHOP_MONEY_AFTER"), money, after]

	var col: Color = style.colour(&"c_bad" if after < 0 else &"c_muted")
	_after.add_theme_color_override("font_color", col)


func after_label() -> Label:
	return _after


func qty_label() -> Label:
	return _qty
