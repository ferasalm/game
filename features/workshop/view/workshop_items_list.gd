class_name WorkshopItemsList
extends PanelContainer
## purpose: Left list panel (460x760 at 80,140) displaying upgradeable gear, gemstones, or craft recipes.

signal item_selected(id_name: StringName)
signal item_activated(id_name: StringName)

var _list_box: VBoxContainer
var _selected_id: StringName = &""


func _init() -> void:
	custom_minimum_size = Vector2(460.0, 760.0)
	size = Vector2(460.0, 760.0)
	position = Vector2(80.0, 140.0)
	theme_type_variation = &"InsetPanel"
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 4)
	scroll.add_child(_list_box)


func populate(tab: int) -> void:
	for child: Node in _list_box.get_children():
		_list_box.remove_child(child)
		child.queue_free()
	match tab:
		0:
			_populate_upgrades()
		1:
			_populate_gemstones()
		2:
			_populate_crafting()
	if _list_box.get_child_count() > 0:
		var first: ListRow = _list_box.get_child(0) as ListRow
		if first != null:
			select_item(first.get_meta(&"id", &""))


func select_item(id_name: StringName) -> void:
	_selected_id = id_name
	item_selected.emit(id_name)


func focus_first() -> void:
	if _list_box.get_child_count() > 0:
		var first: Control = _list_box.get_child(0) as Control
		if first != null:
			first.grab_focus()


func _populate_upgrades() -> void:
	var items: Array[StringName] = []
	for id_name: StringName in GameState.inventory:
		if ContentDB.get_def("blade", id_name) != null or ContentDB.get_def("armor", id_name) != null:
			if not items.has(id_name):
				items.append(id_name)
	for slot_item: StringName in GameState.equipment.values():
		if ContentDB.get_def("blade", slot_item) != null or ContentDB.get_def("armor", slot_item) != null:
			if not items.has(slot_item):
				items.append(slot_item)
	for item_id: StringName in items:
		var item := ContentDB.get_def("item", item_id) as EquipDef
		var lvl: int = int(GameState.upgrades.get(item_id, 0))
		var tag: String = ("MAX" if lvl >= 3 else "+%d" % lvl) if lvl > 0 else ""
		var label: String = Ui.text(item.name_key) if item != null else String(item_id)
		var row: ListRow = Ui.list_row(null, label, -1, UiRarity.item_colour(item_id), tag)
		row.set_meta(&"id", item_id)
		row.focus_entered.connect(select_item.bind(item_id))
		row.pressed.connect(func() -> void: item_activated.emit(item_id))
		_list_box.add_child(row)


func _populate_gemstones() -> void:
	for id_name: StringName in GameState.inventory:
		var st := ContentDB.get_def("stone", id_name) as StoneDef
		if st != null:
			var label: String = Ui.text(st.name_key)
			var row: ListRow = Ui.list_row(null, label, -1, UiRarity.colour(st.rarity), "")
			row.set_meta(&"id", id_name)
			row.focus_entered.connect(select_item.bind(id_name))
			row.pressed.connect(func() -> void: item_activated.emit(id_name))
			_list_box.add_child(row)


func _populate_crafting() -> void:
	for r_id: StringName in ContentDB.ids("recipe"):
		var recipe := ContentDB.get_def("recipe", r_id) as RecipeDef
		var out_str: String = _recipe_name(recipe)
		var row: ListRow = Ui.list_row(null, out_str, recipe.count, Ui.style().colour(&"c_text"), "")
		row.set_meta(&"id", r_id)
		row.focus_entered.connect(select_item.bind(r_id))
		row.pressed.connect(func() -> void: item_activated.emit(r_id))
		_list_box.add_child(row)


static func _recipe_name(recipe: RecipeDef) -> String:
	if recipe == null:
		return ""
	var con: ConsumableDef = ContentDB.get_def("consumable", recipe.output) as ConsumableDef
	if con != null and con.name_key != "":
		return Ui.text(con.name_key)
	var st: StoneDef = ContentDB.get_def("stone", recipe.output) as StoneDef
	if st != null and st.name_key != "":
		return Ui.text(st.name_key)
	return String(recipe.output)
