extends TestCase
## purpose: The gear-slots menu tests: Bilqis's frame and barrel boxes, the accessory box and its sockets,
## and equipping through the new slots.

const OWNED: Array[StringName] = [
	&"grandfather_hilt", &"swift_hilt", &"rustwire_blade", &"keen_blade", &"salvage_arm", &"arc_arm",
	&"wrist_rig", &"lens_array", &"courier_jacket", &"rig_shawl", &"aqiq_red",
	&"machined_frame", &"choke_barrel", &"lattice_ring", &"qamariya_ring",
]


func _open_menu() -> EquipmentMenu:
	GameState.start_new()
	Inventory.add_all(GameState.inventory, OWNED)
	var menu: EquipmentMenu = Screens.open(&"equipment") as EquipmentMenu
	return menu


func test_bilqis_shows_five_boxes_zayd_six() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"zayd")
	check_eq(menu.boxes_manager.visible_boxes().size(), 6, "Zayd shows 6 boxes")
	menu.show_hero(&"bilqis")
	var bilqis_slots: Array[StringName] = []
	for b: SlotBox in menu.boxes_manager.visible_boxes():
		bilqis_slots.append(b.part)
	check_eq(bilqis_slots, [&"frame", &"barrel", &"armor", &"prosthetic", &"accessory"] as Array[StringName],
		"Bilqis's boxes: frame, barrel, armor, prosthetic, accessory")
	check_eq(menu.boxes_manager.boxes[&"frame"].item_name(), Ui.text("PISTOL_RIVET_FRAME"),
		"frame box shows the start frame")
	check_eq(menu.boxes_manager.boxes[&"accessory"].item_name(), Ui.text("ACCESSORY_SILVER_BAND"),
		"accessory box shows the start ring")
	Screens.clear()
	GameState.reset()


func test_accessory_box_shows_the_ring_sockets() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"zayd")
	var ring_box: SlotBox = menu.boxes_manager.boxes[&"accessory"]
	check(ring_box._socket_panels[0].visible, "socket 0 visible for the Common ring")
	check(not ring_box._socket_panels[1].visible, "socket 1 hidden (one socket)")
	Inventory.add(GameState.inventory, &"qamariya_ring")
	GameState.equipment[&"zayd.accessory"] = &"qamariya_ring"
	menu.boxes_manager.refresh(&"zayd")
	check(ring_box._socket_panels[0].visible and ring_box._socket_panels[1].visible,
		"the Rare ring opens both sockets")
	Screens.clear()
	GameState.reset()


func test_equipping_through_the_new_slots_writes_game_state() -> void:
	var menu: EquipmentMenu = _open_menu()
	menu.show_hero(&"bilqis")
	menu._on_slot_activated(&"frame")
	var machined: EquipDef = ContentDB.get_def("pistol", &"machined_frame") as EquipDef
	menu._on_item_pressed(machined)
	check_eq(GameState.equipment[&"bilqis.frame"], &"machined_frame", "A on a frame writes bilqis.frame")
	menu._on_slot_activated(&"accessory")
	var ring: EquipDef = ContentDB.get_def("accessory", &"lattice_ring") as EquipDef
	menu._on_item_pressed(ring)
	check_eq(GameState.equipment[&"bilqis.accessory"], &"lattice_ring", "A on a ring writes bilqis.accessory")
	check(not GameState.equipment.has(&"zayd.accessory"), "the swap never touches the other hero")
	var loader := BattleLoader.from_db(ContentDB)
	var after: CombatantDef = loader.hero_from_state(&"bilqis", GameState)
	var bare: CombatantDef = ContentDB.get_def("combatant", &"bilqis") as CombatantDef
	var barrel: PistolDef = ContentDB.get_def("pistol", &"rivet_barrel") as PistolDef
	check_eq(after.attack, bare.attack + barrel.attack,
		"the worn machined frame and the start barrel count in her fighter")
	check_eq(after.agility, bare.agility + 1, "the machined frame's agility is on")
	Screens.clear()
	GameState.reset()
