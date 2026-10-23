class_name ShopGrid
extends UiPanel
## Shop grid panel at (80,140) 720x560: tabs [Buy][Sell] and 3-column items grid.

signal tab_switched(tab_id: StringName)
signal item_selected(item_id: StringName)
signal item_traded()

var _tabs: Dictionary[StringName, Button] = {}
var _grid: GridContainer
var _rows: Dictionary[StringName, Button] = {}
var _order: Array[StringName] = []


func setup_grid() -> ShopGrid:
	var _panel := setup("", "")
	var style: UiStyleDef = Ui.style()
	position = Vector2(80, 140)
	size = Vector2(720, 560)
	custom_minimum_size = Vector2(720, 560)

	var tabs_box := HBoxContainer.new()
	for tab_id: StringName in [ShopScreen.BUY, ShopScreen.SELL]:
		var btn := Button.new()
		btn.theme_type_variation = &"TabButton"
		btn.toggle_mode = true
		btn.text = Ui.text("SHOP_TAB_BUY" if tab_id == ShopScreen.BUY else "SHOP_TAB_SELL")
		btn.pressed.connect(_on_tab_pressed.bind(tab_id))
		btn.focus_entered.connect(UiSweep.start.bind(btn))
		btn.focus_exited.connect(UiSweep.clear.bind(btn))
		tabs_box.add_child(btn)
		_tabs[tab_id] = btn
	body.add_child(tabs_box)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", style.size(&"s_gap"))
	_grid.add_theme_constant_override("v_separation", style.size(&"s_gap"))
	body.add_child(_grid)
	return self


func open_tab(tab: StringName, shop: ShopDef) -> void:
	for key: StringName in _tabs:
		_tabs[key].button_pressed = key == tab
	for old: Node in _grid.get_children():
		old.queue_free()
	_rows.clear()
	_order.clear()

	var defs: Array[ConsumableDef] = []
	var ids: Array[StringName] = shop.stock if tab == ShopScreen.BUY else ItemService.owned_ids()
	for item_id: StringName in ids:
		defs.append(ContentDB.get_def("consumable", item_id) as ConsumableDef)

	for def: ConsumableDef in defs:
		var price: int = def.sell if tab == ShopScreen.SELL else Shop.unit_buy_price(shop, def, GameState.flags)
		var owned: int = GameState.bag.get(def.id, 0)
		var can_afford: bool = GameState.money >= price
		var is_sold_out: bool = (tab == ShopScreen.BUY and owned >= def.max_stack)
		var cell := ShopCell.new().setup(def, price, owned, can_afford, is_sold_out)
		cell.focus_entered.connect(_on_cell_focus.bind(def.id))
		cell.pressed.connect(_on_cell_pressed)
		_grid.add_child(cell)
		_rows[def.id] = cell
		_order.append(def.id)


func row_of(item_id: StringName) -> Button:
	return _rows.get(item_id)


func tab_button(tab_id: StringName) -> Button:
	return _tabs.get(tab_id)


func order() -> Array[StringName]:
	return _order


func rows() -> Dictionary[StringName, Button]:
	return _rows


func _on_tab_pressed(tab_id: StringName) -> void:
	tab_switched.emit(tab_id)


func _on_cell_focus(item_id: StringName) -> void:
	item_selected.emit(item_id)


func _on_cell_pressed() -> void:
	item_traded.emit()
