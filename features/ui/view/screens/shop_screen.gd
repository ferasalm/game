class_name ShopScreen
extends UiScreen
## Shop screen: title (80,40), grid (80,140), keeper (80,720), detail (840,140), summary (1440,140), party (1440,600).

const ID: StringName = &"shop"
const BUY: StringName = &"buy"
const SELL: StringName = &"sell"

var _shop: ShopDef
var _tab: StringName = BUY
var _item: StringName = &""
var _qty: int = 1

var _title_bar: UiPanel
var _money_counter: MoneyCounter
var _grid_panel: ShopGrid
var _keeper_box: ShopKeeperBox
var _detail: ShopDetail
var _summary: ShopSummary
var _party_mini: ShopPartyMini


func _init() -> void:
	super()
	backdrop_id = &"shop"
	prompts = [{"key": "accept", "text": "SHOP_PROMPT_BUY"}, {"key": "back", "text": "SHOP_PROMPT_LEAVE"}]


func build(args: Dictionary) -> void:
	_shop = ShopService.shop(args.get("shop", &"herb_stall"))
	if _shop == null:
		push_warning("ShopScreen: unknown shop %s" % args.get("shop"))
		close()
		return
	_build_title_bar()
	_build_panels()
	_keeper_box.setup_portrait(&"abu_nabil")
	_keeper_box.set_text(Ui.text(ShopService.greeting(_shop, args.get("after_battle", false))))
	_open_tab(BUY)


func focus_default() -> void:
	if not is_inside_tree():
		return
	if _grid_panel.row_of(_item) != null:
		_grid_panel.row_of(_item).grab_focus()
	elif not _grid_panel.order().is_empty():
		_grid_panel.row_of(_grid_panel.order()[0]).grab_focus()


func on_back() -> bool:
	close()
	return true


func switch_tab(tab_id: StringName) -> void:
	_open_tab(tab_id)
	_keeper_box.set_text(Ui.text("SHOP_LINE_BUY" if tab_id == BUY else "SHOP_LINE_SELL"))


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
	return _grid_panel.row_of(item_id)


func tab_button(tab_id: StringName) -> Button:
	return _grid_panel.tab_button(tab_id)


func keeper_text() -> String:
	return _keeper_box.get_text()


func title_bar() -> Control:
	return _title_bar


func grid_panel() -> Control:
	return _grid_panel


func keeper_box() -> ShopKeeperBox:
	return _keeper_box


func detail_panel() -> ShopDetail:
	return _detail


func summary_panel() -> ShopSummary:
	return _summary


func party_mini() -> ShopPartyMini:
	return _party_mini


func trade() -> ShopResult:
	if _item == &"":
		return ShopResult.fail(Shop.NOTHING_TO_SELL, &"")
	var result: ShopResult = ShopService.buy(_shop.id, _item, _qty) if _tab == BUY else ShopService.sell(_item, _qty)
	if result.ok:
		_keeper_box.set_text(Ui.text("SHOP_BUY_DONE" if _tab == BUY else "SHOP_SELL_DONE"))
	else:
		_keeper_box.set_text(Ui.text(Shop.REASON_KEYS.get(result.reason, "SHOP_NOT_ENOUGH")))
	var keep: StringName = _item
	_open_tab(_tab)
	if _grid_panel.row_of(keep) != null:
		select(keep)
	focus_default()
	return result


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _closing or process_mode == Node.PROCESS_MODE_DISABLED:
		return
	var step: int = 1 if event.is_action_pressed(&"ui_right") else -1 if event.is_action_pressed(&"ui_left") else 0
	var cell: Button = _grid_panel.row_of(_item)
	if step != 0 and cell != null and cell.has_focus():
		set_quantity(_qty + step)
		get_viewport().set_input_as_handled()


func _build_title_bar() -> void:
	var title_text: String = Ui.text("SHOP_TITLE_HERB_STALL")
	_title_bar = Ui.panel(title_text, Ui.text("SHOP_HERB_STALL_MUSNAD"))
	_title_bar.position = Vector2(80, 40)
	_title_bar.size = Vector2(1760, 80)
	_title_bar.custom_minimum_size = Vector2(1760, 80)
	add_child(_title_bar)

	_money_counter = Ui.money_counter()
	_money_counter.position = Vector2(1600, 56)
	_money_counter.set_amount(GameState.money, false)
	add_child(_money_counter)


func _build_panels() -> void:
	_grid_panel = ShopGrid.new().setup_grid()
	_grid_panel.tab_switched.connect(switch_tab)
	_grid_panel.item_selected.connect(select)
	_grid_panel.item_traded.connect(func() -> void: trade())
	add_child(_grid_panel)

	_keeper_box = ShopKeeperBox.new()
	_keeper_box.position = Vector2(80, 720)
	add_child(_keeper_box)

	_detail = ShopDetail.new()
	_detail.position = Vector2(840, 140)
	add_child(_detail)

	_summary = ShopSummary.new()
	_summary.position = Vector2(1440, 140)
	add_child(_summary)

	_party_mini = ShopPartyMini.new()
	_party_mini.position = Vector2(1440, 600)
	add_child(_party_mini)


func _open_tab(tab: StringName) -> void:
	_tab = tab
	_item = &""
	_grid_panel.open_tab(tab, _shop)
	if not _grid_panel.order().is_empty():
		select(_grid_panel.order()[0])
	else:
		_refresh()


func _refresh() -> void:
	_money_counter.set_amount(GameState.money, false)
	_party_mini.refresh()
	var def := ContentDB.get_def("consumable", _item) as ConsumableDef
	var selling: bool = _tab == SELL
	_qty = clampi(_qty, 1, maxi(1, ShopService.limit(_item, selling, _shop.id)))
	var price: int = 0
	if def != null:
		price = def.sell if selling else Shop.unit_buy_price(_shop, def, GameState.flags)
	_detail.show_item(def, price, _qty, GameState.money, GameState.bag.get(_item, 0), selling)
	_summary.show_summary(def, price, _qty, GameState.money, GameState.bag.get(_item, 0), selling)
