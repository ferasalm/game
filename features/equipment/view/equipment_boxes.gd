class_name EquipmentBoxes
extends RefCounted
## purpose: Manages the 5 equipment slot boxes, their positions, visibility per hero and focus navigation.

const SLOTS: Array[StringName] = [&"blade", &"hilt", &"gemstones", &"armor", &"prosthetic"]
const POS: Dictionary[StringName, Vector2] = {
	&"blade": Vector2(600.0, 180.0),
	&"hilt": Vector2(600.0, 420.0),
	&"gemstones": Vector2(600.0, 660.0),
	&"armor": Vector2(1210.0, 180.0),
	&"prosthetic": Vector2(1210.0, 420.0),
}
const ANCHORS: Dictionary[StringName, StringName] = {
	&"blade": &"chest", &"hilt": &"hand", &"gemstones": &"hip", &"armor": &"chest", &"prosthetic": &"hand",
}

var boxes: Dictionary[StringName, SlotBox] = {}


func build(root: Control, stage: HologramStage, on_activated: Callable, on_focused: Callable = Callable()) -> void:
	for slot_name: StringName in SLOTS:
		var box := SlotBox.new()
		box.position = POS[slot_name]
		box.setup(slot_name, Ui.text("EQUIP_SLOT_" + slot_name.to_upper()), slot_name == &"gemstones")
		box.slot_activated.connect(on_activated)
		if on_focused.is_valid():
			box.slot_focused.connect(on_focused)
		root.add_child(box)
		boxes[slot_name] = box
		stage.register_box(slot_name, box, ANCHORS[slot_name])
	_wire_focus()


func set_active_slot(active_name: StringName) -> void:
	for slot_name: StringName in boxes:
		var box: SlotBox = boxes[slot_name]
		box.is_selected = (slot_name == active_name)
		box.queue_redraw()


func refresh(hero: StringName) -> void:
	var allowed: Array[StringName] = EquipmentOptions.parts_for(hero)
	var loadout: LoadoutDef = null
	for l_id: StringName in ContentDB.ids("loadout"):
		var l := ContentDB.get_def("loadout", l_id) as LoadoutDef
		if l != null and l.hero == hero:
			loadout = l
			break
	for slot_name: StringName in SLOTS:
		var box: SlotBox = boxes[slot_name]
		var fits: bool = allowed.has(slot_name)
		if slot_name == &"gemstones":
			fits = allowed.has(&"hilt")
		box.visible = fits
		if fits:
			if slot_name == &"gemstones":
				var hilt_id: StringName = GameState.equipment.get(Inventory.slot_key(hero, &"hilt"), &"")
				if hilt_id == &"" and loadout != null:
					hilt_id = Loadout.worn(GameState.equipment, loadout, &"hilt")
				var sock_list: Array = GameState.sockets.get(hilt_id, [])
				var hilt_def := ContentDB.get_def("hilt", hilt_id) as HiltDef
				box.set_sockets(sock_list, Stones.open_slots(hilt_def, GameState.flags))
			else:
				var slot_key: StringName = Inventory.slot_key(hero, slot_name)
				var worn_id: StringName = GameState.equipment.get(slot_key, &"")
				if worn_id == &"" and not GameState.equipment.has(slot_key) and loadout != null:
					if slot_name == &"hilt":
						worn_id = loadout.hilt
					elif slot_name == &"blade":
						worn_id = loadout.blade
					elif slot_name == &"prosthetic":
						worn_id = loadout.prosthetic
				var item: EquipDef = ContentDB.get_def("item", worn_id) as EquipDef
				box.set_item(item)


func visible_boxes() -> Array[SlotBox]:
	var out: Array[SlotBox] = []
	for b: SlotBox in boxes.values():
		if b.visible:
			out.append(b)
	return out


func focus_first() -> void:
	for b: SlotBox in visible_boxes():
		b.grab_focus()
		break


func focus_slot(slot_name: StringName) -> void:
	if boxes.has(slot_name) and boxes[slot_name].visible:
		boxes[slot_name].grab_focus()
	else:
		focus_first()


func _wire_focus() -> void:
	boxes[&"blade"].focus_neighbor_bottom = boxes[&"hilt"].get_path()
	boxes[&"blade"].focus_neighbor_right = boxes[&"armor"].get_path()
	boxes[&"hilt"].focus_neighbor_top = boxes[&"blade"].get_path()
	boxes[&"hilt"].focus_neighbor_bottom = boxes[&"gemstones"].get_path()
	boxes[&"hilt"].focus_neighbor_right = boxes[&"prosthetic"].get_path()
	boxes[&"gemstones"].focus_neighbor_top = boxes[&"hilt"].get_path()
	boxes[&"gemstones"].focus_neighbor_right = boxes[&"prosthetic"].get_path()
	boxes[&"armor"].focus_neighbor_bottom = boxes[&"prosthetic"].get_path()
	boxes[&"armor"].focus_neighbor_left = boxes[&"blade"].get_path()
	boxes[&"prosthetic"].focus_neighbor_top = boxes[&"armor"].get_path()
	boxes[&"prosthetic"].focus_neighbor_left = boxes[&"hilt"].get_path()
