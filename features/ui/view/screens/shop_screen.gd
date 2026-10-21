class_name ShopScreen
extends UiScreen
## The herb stall (Screens id &"shop"; open with Screens.open(&"shop", {"shop": &"herb_stall"}), optional
## "after_battle": true for the keeper's other greeting). Buy and Sell tabs, a list on the left, the focused item's
## details, price and "money after" on the right, a quantity stepper (left/right) and the keeper's reply line.
## A on a row trades the chosen quantity through ShopService; the rules live in Shop. B leaves.

const ID: StringName = &"shop"
const BUY: StringName = &"buy"
const SELL: StringName = &"sell"

var _shop: ShopDef
var _tab: StringName = BUY
var _item: StringName = &""
var _qty: int = 1
var _rows: Dictionary[StringName, Button] = {}
var _tabs: Dictionary[StringName, Button] = {}
var _list: UiPanel
var _box: VBoxContainer
var _keeper: Label
var _info: ShopDetail
var _order: Array[StringName] = []


func _init() -> void:
	super()
	prompts = [{"key": "accept", "text": "SHOP_PROMPT_BUY"}, {"key": "back", "text": "SHOP_PROMPT_LEAVE"}]


func build(args: Dictionary) -> void:
	_shop = ShopService.shop(args.get("shop", &"herb_stall"))
	if _shop == null:
		push_warning("ShopScreen: unknown shop %s" % args.get("shop"))
		close()
		return
	var style: UiStyleDef = Ui.style()
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", style.size(&"s_margin"))
	centre.add_child(row)
	_list = Ui.panel(Ui.text(_shop.name_key), Ui.text(_shop.name_key + "_AR"))
	_list.custom_minimum_size = Vector2(style.size(&"s_pause_w") + style.size(&"s_margin"), style.size(&"s_pause_h"))
	row.add_child(_list)
	var side: UiPanel = Ui.panel()
	side.custom_minimum_size = Vector2(style.size(&"s_party_w") * 0.5, style.size(&"s_pause_h"))
	row.add_child(side)
	_build_list_side()
	_info = ShopDetail.new()
	side.body.add_child(_info)
	_keeper.text = Ui.text(ShopService.greeting(_shop, args.get("after_battle", false)))
	_open_tab(BUY)


func focus_default() -> void:
	if _rows.has(_item):
		_rows[_item].grab_focus()
	elif not _order.is_empty():
		_rows[_order[0]].grab_focus()


func on_back() -> bool:
	close()
	return true


## Switches between &"buy" and &"sell" (the tab buttons call this); the keeper says the tab's line.
func switch_tab(tab_id: StringName) -> void:
	_open_tab(tab_id)
	_keeper.text = Ui.text("SHOP_LINE_BUY" if tab_id == BUY else "SHOP_LINE_SELL")


func _open_tab(tab: StringName) -> void:
	_tab = tab
	for key: StringName in _tabs:
		_tabs[key].button_pressed = key == tab
	for old: Button in _rows.values():
		old.queue_free()
	_rows.clear()
	_order.clear()
	_item = &""
	for def: ConsumableDef in _entries():
		_add_row(def)
	if not _rows.is_empty():
		select(_order[0])
	else:
		_refresh()


## Focuses an item row's details: its price, "money after" and the quantity reset to 1.
func select(item_id: StringName) -> void:
	if _item != item_id:
		_qty = 1
	_item = item_id
	_refresh()


func set_quantity(amount: int) -> void:
	_qty = amount
	_refresh()


func quantity() -> int:
	return _qty


func row_of(item_id: StringName) -> Button:
	return _rows.get(item_id)


func tab_button(tab_id: StringName) -> Button:
	return _tabs.get(tab_id)


func keeper_text() -> String:
	return _keeper.text


## Trades the chosen quantity of the chosen item; the keeper answers with a line.
func trade() -> ShopResult:
	if _item == &"":
		return ShopResult.fail(Shop.NOTHING_TO_SELL, &"")
	var result: ShopResult = ShopService.buy(_shop.id, _item, _qty) if _tab == BUY else ShopService.sell(_item, _qty)
	if result.ok:
		_keeper.text = Ui.text("SHOP_BUY_DONE" if _tab == BUY else "SHOP_SELL_DONE")
	else:
		_keeper.text = Ui.text(Shop.REASON_KEYS.get(result.reason, "SHOP_NOT_ENOUGH"))
	var keep: StringName = _item
	_open_tab(_tab)
	if _rows.has(keep):
		select(keep)
	focus_default()
	return result


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _closing or process_mode == Node.PROCESS_MODE_DISABLED:
		return
	var step: int = 1 if event.is_action_pressed(&"ui_right") else -1 if event.is_action_pressed(&"ui_left") else 0
	if step != 0 and _rows.has(_item) and _rows[_item].has_focus():
		set_quantity(_qty + step)
		get_viewport().set_input_as_handled()


func _build_list_side() -> void:
	_keeper = Ui.label("", &"MutedLabel")
	_keeper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.body.add_child(Ui.label(Ui.text(_shop.keeper_key), &"NameLabel"))
	_list.body.add_child(_keeper)
	var tabs := HBoxContainer.new()
	for tab_id: StringName in [BUY, SELL]:
		var button := Button.new()
		button.theme_type_variation = &"TabButton"
		button.toggle_mode = true
		button.text = Ui.text("SHOP_TAB_BUY" if tab_id == BUY else "SHOP_TAB_SELL")
		button.pressed.connect(switch_tab.bind(tab_id))
		sweep_on_focus(button)
		tabs.add_child(button)
		_tabs[tab_id] = button
	_list.body.add_child(tabs)
	_box = VBoxContainer.new()
	_list.body.add_child(_box)


## The consumables on this tab: the stock (buy) or what the bag holds (sell).
func _entries() -> Array[ConsumableDef]:
	var out: Array[ConsumableDef] = []
	var ids: Array[StringName] = _shop.stock if _tab == BUY else ItemService.owned_ids()
	for item_id: StringName in ids:
		out.append(ContentDB.get_def("consumable", item_id) as ConsumableDef)
	return out


func _add_row(def: ConsumableDef) -> void:
	var button := Button.new()
	var price: int = def.price if _tab == BUY else def.sell
	button.text = "%s   %d   x%d" % [Ui.text(def.name_key), price, GameState.bag.get(def.id, 0)]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = Ui.style().size(&"s_list_row_h")
	button.focus_entered.connect(select.bind(def.id))
	button.mouse_entered.connect(button.grab_focus)
	button.pressed.connect(trade)
	sweep_on_focus(button)
	_box.add_child(button)
	_rows[def.id] = button
	_order.append(def.id)


func _refresh() -> void:
	_info.show_money(GameState.money)
	var def := ContentDB.get_def("consumable", _item) as ConsumableDef
	var selling: bool = _tab == SELL
	_qty = clampi(_qty, 1, maxi(1, ShopService.limit(_item, selling)))
	if def == null:
		_info.show_item(null, 0, 1, GameState.money, 0, selling)
		return
	_info.show_item(def, def.sell if selling else def.price, _qty, GameState.money, GameState.bag.get(_item, 0), selling)
