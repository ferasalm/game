class_name EquipmentBoxes
extends RefCounted
## purpose: Manages the 8 equipment slot boxes, their positions, visibility per hero and focus navigation.

const SLOTS: Array[StringName] = [&"blade", &"hilt", &"gemstones", &"frame", &"barrel", &"armor", &"prosthetic", &"accessory"]
const POS: Dictionary[StringName, Vector2] = {
	&"blade": Vector2(600.0, 180.0),
	&"hilt": Vector2(600.0, 420.0),
	&"gemstones": Vector2(600.0, 660.0),
	&"frame": Vector2(600.0, 180.0),
	&"barrel": Vector2(600.0, 420.0),
	&"armor": Vector2(1210.0, 180.0),
	&"prosthetic": Vector2(1210.0, 420.0),
	&"accessory": Vector2(1210.0, 660.0),
}
const ANCHORS: Dictionary[StringName, StringName] = {
	&"blade": &"hand_left", &"hilt": &"belt", &"gemstones": &"hip", &"frame": &"belt", &"barrel": &"hand",
	&"armor": &"chest", &"prosthetic": &"arm_left", &"accessory": &"feet",
}

var boxes: Dictionary[StringName, SlotBox] = {}


func build(root: Control, stage: HologramStage, on_activated: Callable, on_focused: Callable = Callable()) -> void:
	for slot_name: StringName in SLOTS:
		var box := SlotBox.new()
		box.position = POS[slot_name]
		box.setup(
			slot_name, Ui.text("EQUIP_SLOT_" + slot_name.to_upper()),
			slot_name == &"gemstones", slot_name == &"accessory")
		box.slot_activated.connect(on_activated)
		if on_focused.is_valid():
			box.slot_focused.connect(on_focused)
		root.add_child(box)
		boxes[slot_name] = box
		stage.register_box(slot_name, box, ANCHORS[slot_name])


func set_active_slot(active_name: StringName) -> void:
	for slot_name: StringName in boxes:
		var box: SlotBox = boxes[slot_name]
		box.is_selected = (slot_name == active_name)
		box.queue_redraw()


func set_allow_hover_focus(allowed: bool) -> void:
	for box: SlotBox in boxes.values():
		box.allow_hover_focus = allowed


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
		if not fits:
			continue
		if slot_name == &"gemstones":
			var hilt_id: StringName = GameState.equipment.get(Inventory.slot_key(hero, &"hilt"), &"")
			if hilt_id == &"" and loadout != null:
				hilt_id = Loadout.worn(GameState.equipment, loadout, &"hilt")
			var sock_list: Array = GameState.sockets.get(hilt_id, [])
			var hilt_def := ContentDB.get_def("hilt", hilt_id) as HiltDef
			box.set_sockets(sock_list, Stones.open_slots(hilt_def, GameState.flags))
		elif slot_name == &"accessory":
			_refresh_accessory(box, hero, loadout)
		else:
			var slot_key: StringName = Inventory.slot_key(hero, slot_name)
			var worn_id: StringName = GameState.equipment.get(slot_key, &"")
			if worn_id == &"" and not GameState.equipment.has(slot_key) and loadout != null:
				worn_id = Loadout.worn(GameState.equipment, loadout, slot_name)
			var item: EquipDef = ContentDB.get_def("item", worn_id) as EquipDef
			box.set_item(item)
	_rewire_focus()


## The ring worn in the accessory slot with its gem sockets (read only, like the hilt's gemstones).
func _refresh_accessory(box: SlotBox, hero: StringName, loadout: LoadoutDef) -> void:
	var slot_key: StringName = Inventory.slot_key(hero, &"accessory")
	var ring_id: StringName = GameState.equipment.get(slot_key, &"")
	if ring_id == &"" and not GameState.equipment.has(slot_key) and loadout != null:
		ring_id = loadout.accessory
	var ring := ContentDB.get_def("accessory", ring_id) as AccessoryDef
	box.set_item(ring)
	box.set_sockets(GameState.sockets.get(ring_id, []), ring.sockets if ring != null else 0)


func visible_boxes() -> Array[SlotBox]:
	var out: Array[SlotBox] = []
	for slot_name: StringName in SLOTS:
		var box: SlotBox = boxes.get(slot_name)
		if box != null and box.visible:
			out.append(box)
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


## Rewires d-pad focus between the visible boxes: the nearest box in each direction wins (side distance
## outweighs along distance, so up/down stay in a column and left/right cross at the same height).
func _rewire_focus() -> void:
	var vis: Array[SlotBox] = visible_boxes()
	for box: SlotBox in vis:
		box.focus_neighbor_top = _nearest(box, vis, Vector2(0.0, -1.0))
		box.focus_neighbor_bottom = _nearest(box, vis, Vector2(0.0, 1.0))
		box.focus_neighbor_left = _nearest(box, vis, Vector2(-1.0, 0.0))
		box.focus_neighbor_right = _nearest(box, vis, Vector2(1.0, 0.0))


func _nearest(from: SlotBox, pool: Array[SlotBox], dir: Vector2) -> NodePath:
	var best: SlotBox = null
	var best_rank: float = INF
	for other: SlotBox in pool:
		if other == from:
			continue
		var delta: Vector2 = other.position - from.position
		var along: float = delta.dot(dir)
		if along <= 0.0:
			continue
		var rank: float = absf(delta.x * dir.y - delta.y * dir.x) * 10.0 + along
		if rank < best_rank:
			best_rank = rank
			best = other
	return best.get_path() if best != null else NodePath()
