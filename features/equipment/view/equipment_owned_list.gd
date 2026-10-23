class_name EquipmentOwnedList
extends UiPanel
## purpose: Owned items panel (420x620 at 80,260) populated with ListRows and worn "E" chips.

signal item_focused(item: EquipDef)
signal item_activated(item: EquipDef)

var _vbox: VBoxContainer


func _init() -> void:
	setup("", "")
	position = Vector2(80.0, 280.0)
	custom_minimum_size = Vector2(420.0, 600.0)
	size = Vector2(420.0, 600.0)
	var title_plate := Ui.title_plate(Ui.text("EQUIP_INVENTORY"), "")
	body.add_child(title_plate)
	body.add_child(Ui.divider())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)

	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(_vbox)


func populate(hero: StringName, slot_name: StringName) -> void:
	if _vbox == null:
		return
	for c: Node in _vbox.get_children():
		_vbox.remove_child(c)
		c.queue_free()
	var order: Dictionary[StringName, int] = {}
	for r_id: StringName in ContentDB.ids("rarity"):
		order[r_id] = UiRarity.order(r_id)
	if slot_name == &"gemstones":
		var stones: Array[EquipDef] = _gemstone_options(order)
		var hilt_id: StringName = GameState.equipment.get(Inventory.slot_key(hero, &"hilt"), &"")
		var sock_list: Array = GameState.sockets.get(hilt_id, [])
		_create_rows(stones, &"", sock_list)
		return
	var all_items: Array[EquipDef] = []
	for k: String in ContentDB.ITEM_KINDS:
		for id: StringName in ContentDB.ids(k):
			all_items.append(ContentDB.get_def(k, id) as EquipDef)
	var options: Array[EquipDef] = EquipmentOptions.options(GameState.inventory, all_items, hero, slot_name, order)
	var slot_key: StringName = Inventory.slot_key(hero, slot_name)
	var worn_id: StringName = GameState.equipment.get(slot_key, &"")
	if worn_id == &"" and not GameState.equipment.has(slot_key):
		worn_id = _fallback_worn(hero, slot_name)
	_create_rows(options, worn_id, [])


func focus_first() -> void:
	if _vbox != null and _vbox.get_child_count() > 0:
		(_vbox.get_child(0) as Control).grab_focus()


func rows() -> Array[ListRow]:
	var out: Array[ListRow] = []
	if _vbox != null:
		for c: Node in _vbox.get_children():
			if c is ListRow and not c.is_queued_for_deletion():
				out.append(c as ListRow)
	return out


func _gemstone_options(order: Dictionary[StringName, int]) -> Array[EquipDef]:
	var out: Array[EquipDef] = []
	for item_id: StringName in GameState.inventory:
		var stone := ContentDB.get_def("stone", item_id) as StoneDef
		if stone != null:
			out.append(stone)
	out.sort_custom(func(a: EquipDef, b: EquipDef) -> bool:
		var by_a: int = order.get(a.rarity, 0)
		var by_b: int = order.get(b.rarity, 0)
		return a.id < b.id if by_a == by_b else by_a > by_b)
	return out


func _create_rows(items: Array[EquipDef], worn_id: StringName, sock_list: Array) -> void:
	for item: EquipDef in items:
		var row := ListRow.new()
		var is_worn: bool = (item.id == worn_id) or sock_list.has(item.id) or sock_list.has(String(item.id))
		var icon_tex: Texture2D = ItemIcons.texture(item)
		if icon_tex == null:
			icon_tex = ItemIcons.disc(UiRarity.colour(item.rarity).darkened(0.2), 48)
		row.setup(icon_tex, Ui.text(item.name_key), -1, UiRarity.colour(item.rarity), "E" if is_worn else "")
		row.focus_entered.connect(item_focused.emit.bind(item))
		row.pressed.connect(item_activated.emit.bind(item))
		_vbox.add_child(row)


func _fallback_worn(hero: StringName, slot_name: StringName) -> StringName:
	for l_id: StringName in ContentDB.ids("loadout"):
		var l := ContentDB.get_def("loadout", l_id) as LoadoutDef
		if l != null and l.hero == hero:
			if slot_name == &"hilt":
				return l.hilt
			elif slot_name == &"blade":
				return l.blade
			elif slot_name == &"prosthetic":
				return l.prosthetic
			break
	return &""
