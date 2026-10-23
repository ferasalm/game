class_name EquipmentOwnedList
extends UiPanel
## purpose: Owned items panel (420x620 at 80,240) populated with ListRows and worn "E" chips.

signal item_focused(item: EquipDef)
signal item_activated(item: EquipDef)

var _vbox: VBoxContainer


func _init() -> void:
	setup("", "")
	position = Vector2(80.0, 240.0)
	custom_minimum_size = Vector2(420.0, 620.0)
	size = Vector2(420.0, 620.0)
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
		c.queue_free()
	var all_items: Array[EquipDef] = []
	for k: String in ContentDB.ITEM_KINDS:
		for id: StringName in ContentDB.ids(k):
			all_items.append(ContentDB.get_def(k, id) as EquipDef)
	var order: Dictionary[StringName, int] = {}
	for r_id: StringName in ContentDB.ids("rarity"):
		order[r_id] = UiRarity.order(r_id)
	var options: Array[EquipDef] = EquipmentOptions.options(GameState.inventory, all_items, hero, slot_name, order)
	var slot_key: StringName = Inventory.slot_key(hero, slot_name)
	var worn_id: StringName = GameState.equipment.get(slot_key, &"")
	if worn_id == &"" and not GameState.equipment.has(slot_key):
		for l_id: StringName in ContentDB.ids("loadout"):
			var l := ContentDB.get_def("loadout", l_id) as LoadoutDef
			if l != null and l.hero == hero:
				if slot_name == &"hilt":
					worn_id = l.hilt
				elif slot_name == &"blade":
					worn_id = l.blade
				elif slot_name == &"prosthetic":
					worn_id = l.prosthetic
				break
	for item: EquipDef in options:
		var row := ListRow.new()
		var is_worn: bool = (item.id == worn_id)
		var icon_tex: Texture2D = ItemIcons.texture(item)
		if icon_tex == null:
			icon_tex = ItemIcons.disc(UiRarity.colour(item.rarity).darkened(0.2), 48)
		row.setup(icon_tex, Ui.text(item.name_key), -1, UiRarity.colour(item.rarity), "E" if is_worn else "")
		row.focus_entered.connect(item_focused.emit.bind(item))
		row.pressed.connect(item_activated.emit.bind(item))
		_vbox.add_child(row)


func focus_first() -> void:
	if _vbox != null and _vbox.get_child_count() > 0:
		(_vbox.get_child(0) as Control).grab_focus()


func rows() -> Array[ListRow]:
	var out: Array[ListRow] = []
	if _vbox != null:
		for c: Node in _vbox.get_children():
			if c is ListRow:
				out.append(c as ListRow)
	return out
