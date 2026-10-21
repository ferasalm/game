extends TestCase
## Inventory (unique owned items, equip checks per slot), chests (open once, saved flag) and the item_obtained
## signal on the EventBus.


func _hilt(id: StringName) -> HiltDef:
	return ContentDB.get_def("hilt", id) as HiltDef


func test_add_is_unique_and_ignores_empty_ids() -> void:
	var owned: Array[StringName] = []
	check(Inventory.add(owned, &"keen_blade"), "first add")
	check(not Inventory.add(owned, &"keen_blade"), "a second copy is refused")
	check(not Inventory.add(owned, &""), "an empty id is refused")
	check_eq(owned, [&"keen_blade"] as Array[StringName], "one entry")
	check_eq(Inventory.add_all(owned, [&"keen_blade", &"anvil_hilt"] as Array[StringName]), [&"anvil_hilt"] as Array[StringName],
		"add_all returns only the new ones")
	check(Inventory.has(owned, &"anvil_hilt") and not Inventory.has(owned, &"swift_hilt"), "has")


func test_slot_keys_are_hero_dot_part() -> void:
	check_eq(Inventory.slot_key(&"zayd", &"hilt"), &"zayd.hilt", "zayd.hilt")
	check_eq(Inventory.slot_key(&"bilqis", &"prosthetic"), &"bilqis.prosthetic", "bilqis.prosthetic")


func test_equip_checks_ownership_slot_and_wearer() -> void:
	var owned: Array[StringName] = [&"anvil_hilt", &"keen_blade", &"arc_arm", &"wrist_rig"]
	var worn: Dictionary[StringName, StringName] = {}
	check(Inventory.equip(worn, owned, &"zayd.hilt", _hilt(&"swift_hilt")) != "", "not owned: refused")
	check(worn.is_empty(), "and nothing changed")
	check_eq(Inventory.equip(worn, owned, &"zayd.hilt", _hilt(&"anvil_hilt")), "", "an owned hilt in the hilt slot")
	check_eq(worn[&"zayd.hilt"], &"anvil_hilt", "worn")
	check(Inventory.equip(worn, owned, &"zayd.blade", _hilt(&"anvil_hilt")) != "", "a hilt in the blade slot: refused")
	check(Inventory.equip(worn, owned, &"bilqis.hilt", _hilt(&"anvil_hilt")) != "", "Bilqis has no djanbeyyah slot")
	var arc := ContentDB.get_def("prosthetic", &"arc_arm") as ProstheticDef
	var rig := ContentDB.get_def("prosthetic", &"wrist_rig") as ProstheticDef
	check_eq(Inventory.equip(worn, owned, &"zayd.prosthetic", arc), "", "Zayd's own prosthetic")
	check(Inventory.equip(worn, owned, &"bilqis.prosthetic", arc) != "", "Zayd's arm does not fit Bilqis")
	check(Inventory.equip(worn, owned, &"zayd.prosthetic", rig) != "", "Bilqis's rig does not fit Zayd")
	check_eq(Inventory.equip(worn, owned, &"bilqis.prosthetic", rig), "", "Bilqis's own rig")
	check(Inventory.equip(worn, owned, &"zayd.hat", arc) != "", "an unknown part is refused")
	check(Inventory.equip(worn, owned, &"zayd.hilt", null) != "", "no item is refused")


func test_chest_opens_once_and_the_flag_is_saved() -> void:
	var chest := ContentDB.get_def("chest", &"chest_saila") as ChestDef
	var owned: Array[StringName] = []
	var flags: Dictionary[StringName, bool] = {}
	check(not Chests.is_open(chest, flags), "closed at first")
	check_eq(Chests.open(chest, owned, flags), &"arc_arm", "gives its item")
	check(Chests.is_open(chest, flags) and owned.has(&"arc_arm"), "opened and owned")
	check_eq(Chests.open(chest, owned, flags), &"", "a second opening gives nothing")
	check_eq(owned.size(), 1, "no duplicate")
	var state: Node = load("res://core/game_state.gd").new()
	(state.get("flags") as Dictionary)[Chests.flag(chest.id)] = true
	var loaded: Node = load("res://core/game_state.gd").new()
	loaded.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))
	check((loaded.get("flags") as Dictionary).get(Chests.flag(chest.id), false), "the opened flag survives a save")
	state.free()
	loaded.free()


func test_a_chest_with_an_owned_item_still_counts_as_opened() -> void:
	var chest := ContentDB.get_def("chest", &"chest_mafraj") as ChestDef
	var owned: Array[StringName] = [&"lens_array"]
	var flags: Dictionary[StringName, bool] = {}
	check_eq(Chests.open(chest, owned, flags), &"", "nothing new to give")
	check(Chests.is_open(chest, flags), "but it is opened")


func test_chests_are_found_by_place() -> void:
	var chests: Array[ChestDef] = []
	for chest_id: StringName in ContentDB.ids("chest"):
		chests.append(ContentDB.get_def("chest", chest_id) as ChestDef)
	check_eq(Chests.at_place(chests, &"workshop").size(), 2, "two bench items")
	check_eq(Chests.at_place(chests, &"rooftop").size(), 2, "two map chests")


func test_event_bus_has_item_obtained() -> void:
	check(EventBus.has_signal("item_obtained"), "the signal exists")
	var got: Array[StringName] = []
	var hook := func(item_id: StringName) -> void: got.append(item_id)
	EventBus.item_obtained.connect(hook)
	EventBus.item_obtained.emit(&"keen_blade")
	EventBus.item_obtained.disconnect(hook)
	check_eq(got, [&"keen_blade"] as Array[StringName], "listeners hear it")
