class_name ShopCell
extends Button
## One cell in the shop item grid: 220x170, icon 96, name, price c_brass, rarity glow, sold out dim.

var item_id: StringName = &""
var _icon_rect: TextureRect
var _name_label: Label
var _price_label: Label
var _tag_label: Label


func setup(def: ConsumableDef, price: int, owned: int, _can_afford: bool, is_sold_out: bool) -> ShopCell:
	item_id = def.id if def != null else &""
	var style: UiStyleDef = Ui.style()
	custom_minimum_size = Vector2(220, 170)
	size = Vector2(220, 170)

	var rarity_col: Color = UiRarity.colour(def.rarity if def != null and "rarity" in def else &"")
	if def != null:
		add_theme_stylebox_override("normal", UiBoxes.panel(style, &"inset"))
		add_theme_stylebox_override("hover", UiBoxes.panel(style, &"plate", rarity_col))
		add_theme_stylebox_override("focus", UiBoxes.panel(style, &"plate", rarity_col))

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	add_child(col)

	_icon_rect = TextureRect.new()
	_icon_rect.custom_minimum_size = Vector2(96, 96)
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_icon_rect)

	var name_text: String = Ui.text(def.name_key) if def != null else ""
	_name_label = Ui.label(name_text, &"NameLabel", rarity_col)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_name_label)

	var price_row := HBoxContainer.new()
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_row.add_child(Ui.label(Ui.text("MONEY_GLYPH"), &"CaptionLabel", style.colour(&"c_brass")))
	_price_label = Ui.label(str(price), &"NumberLabel", style.colour(&"c_brass"))
	price_row.add_child(_price_label)
	col.add_child(price_row)

	if is_sold_out:
		modulate = Color(1.0, 1.0, 1.0, 0.45)
		_tag_label = Ui.label(Ui.text("SHOP_SOLD_OUT_TAG"), &"SmallLabel", style.colour(&"c_bad"))
		_tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(_tag_label)

	focus_entered.connect(UiSweep.start.bind(self))
	focus_exited.connect(UiSweep.clear.bind(self))
	mouse_entered.connect(grab_focus)
	return self


func icon_rect() -> TextureRect:
	return _icon_rect
