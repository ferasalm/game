class_name ShopDetail
extends VBoxContainer
## The right half of the shop: the riyal counter, the focused item's name, description and effect, then price,
## owned count, "money after" (red when the trade is not affordable) and the quantity. Labels only; no rules.

var _money: Label
var _name: Label
var _desc: Label
var _effect: Label
var _price: Label
var _owned: Label
var _after: Label
var _qty: Label


func _init() -> void:
	var style: UiStyleDef = Ui.style()
	_money = Ui.label("", &"NumberLabel", style.colour(&"c_brass"))
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_name = Ui.label("", &"NameLabel")
	_desc = Ui.label("", &"MutedLabel")
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_effect = Ui.label("", &"SmallLabel", style.colour(&"c_good"))
	_price = Ui.label("", &"NumberLabel")
	_owned = Ui.label("", &"SmallLabel")
	_after = Ui.label("", &"SmallLabel")
	_qty = Ui.label("", &"NumberLabel")
	add_theme_constant_override("separation", style.size(&"s_gap"))
	for node: Control in [_money, _name, _desc, _effect, Ui.divider(), _price, _owned, _after, _qty]:
		add_child(node)


func show_money(amount: int) -> void:
	_money.text = "%s %s" % [str(amount), Ui.text("UI_RIYAL")]


## def == null clears the item part. `price` is the per-unit riyal (buy price or sell value).
func show_item(def: ConsumableDef, price: int, qty: int, money: int, owned: int, selling: bool) -> void:
	if def == null:
		for label: Label in [_name, _desc, _effect, _price, _owned, _after, _qty]:
			label.text = ""
		return
	var after: int = money + (price * qty if selling else -price * qty)
	_name.text = Ui.text(def.name_key)
	_desc.text = Ui.text(def.desc_key)
	_effect.text = ItemsText.effect(def)
	_price.text = "%s  %s %s" % [Ui.text("SHOP_PRICE"), str(price), Ui.text("UI_RIYAL")]
	_owned.text = "%s  %d / %d" % [Ui.text("SHOP_OWNED"), owned, def.max_stack]
	_after.text = "%s  %s" % [Ui.text("SHOP_MONEY_AFTER"), Ui.text("ITEMS_PREVIEW") % [money, after]]
	var style: UiStyleDef = Ui.style()
	_after.add_theme_color_override("font_color", style.colour(&"c_bad" if after < 0 else &"c_muted"))
	_qty.text = "%s  < %d >" % [Ui.text("SHOP_QTY"), qty]
