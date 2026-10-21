extends TestCase
## The equipment screen: the pure options rules (owned items only, rarer first, per hero and slot), the screen
## listing only owned items in rarity colours, staging, Confirm writing every slot through Inventory.equip, back
## changing nothing, and the stat comparison.

const OWNED: Array[StringName] = [
	&"grandfather_hilt", &"swift_hilt", &"rustwire_blade", &"keen_blade", &"salvage_arm", &"arc_arm",
	&"wrist_rig", &"lens_array"]


func _screen() -> EquipmentScreen:
	GameState.reset()
	Inventory.add_all(GameState.inventory, OWNED)
	var screen := EquipmentScreen.new()
	tree.root.add_child(screen)
	return screen


func _ids(screen: EquipmentScreen) -> Array[StringName]:
	var out: Array[StringName] = []
	for button: Button in screen.item_buttons():
		out.append(button.get_meta("item_id") as StringName)
	return out


func _press(screen: EquipmentScreen, item_id: StringName) -> void:
	screen._opened_frame = -1  # a press in the frame the screen opened is ignored on purpose
	for button: Button in screen.item_buttons():
		if button.get_meta("item_id") == item_id:
			button.pressed.emit()


func _closes(screen: EquipmentScreen) -> Array[int]:
	var count: Array[int] = [0]
	screen.closed.connect(func() -> void: count[0] += 1)
	return count


func test_options_are_owned_fitting_and_rarer_first() -> void:
	var items: Array[EquipDef] = []
	for kind: String in ContentDB.ITEM_KINDS:
		for item_id: StringName in ContentDB.ids(kind):
			items.append(ContentDB.get_def(kind, item_id) as EquipDef)
	var order: Dictionary[StringName, int] = {}
	for rarity_id: StringName in ContentDB.ids("rarity"):
		order[rarity_id] = UiRarity.order(rarity_id)
	var owned: Array[StringName] = OWNED.duplicate()
	var hilts: Array[EquipDef] = EquipmentOptions.options(owned, items, &"zayd", &"hilt", order)
	check_eq(hilts.map(func(item: EquipDef) -> StringName: return item.id), [&"grandfather_hilt", &"swift_hilt"], "owned hilts, heirloom first")
	var arms: Array[EquipDef] = EquipmentOptions.options(owned, items, &"zayd", &"prosthetic", order)
	check_eq(arms.map(func(item: EquipDef) -> StringName: return item.id), [&"arc_arm", &"salvage_arm"], "Zayd's prosthetics only, epic first")
	var hers: Array[EquipDef] = EquipmentOptions.options(owned, items, &"bilqis", &"prosthetic", order)
	check_eq(hers.map(func(item: EquipDef) -> StringName: return item.id), [&"lens_array", &"wrist_rig"], "Bilqis's own prosthetics")
	check_eq(EquipmentOptions.options(owned, items, &"bilqis", &"hilt", order).size(), 0, "Bilqis has no hilt slot items")
	check_eq(EquipmentOptions.parts_for(&"bilqis"), [&"prosthetic"] as Array[StringName], "one slot for Bilqis")
	check_eq(EquipmentOptions.parts_for(&"zayd").size(), 3, "three slots for Zayd")


func test_screen_lists_only_owned_items_per_hero() -> void:
	var screen: EquipmentScreen = _screen()
	check(not screen.is_open(), "closed until open()")
	screen.open()
	check_eq(_ids(screen), [&"grandfather_hilt", &"swift_hilt", &"keen_blade", &"rustwire_blade", &"arc_arm", &"salvage_arm"],
		"Zayd: owned hilts, blades, prosthetics; never anvil_hilt")
	screen.show_hero(&"bilqis")
	check_eq(_ids(screen), [&"lens_array", &"wrist_rig"], "Bilqis: only her prosthetics")
	screen.free()
	GameState.reset()


func test_names_use_the_rarity_colour_and_a_tag() -> void:
	var screen: EquipmentScreen = _screen()
	screen.open()
	for button: Button in screen.item_buttons():
		var item := ContentDB.get_def("item", button.get_meta("item_id")) as EquipDef
		check_eq(button.get_theme_color("font_color"), UiRarity.colour(item.rarity), "name colour of " + item.id)
	check(UiRarity.colour(&"epic") != UiRarity.colour(&"common"), "tiers differ")
	screen.free()
	GameState.reset()


func test_start_gear_is_staged_and_marked() -> void:
	var screen: EquipmentScreen = _screen()
	screen.open()
	check_eq(screen.staged()[&"zayd.hilt"], &"grandfather_hilt", "the worn hilt is staged")
	check_eq(screen.staged()[&"bilqis.prosthetic"], &"wrist_rig", "Bilqis's worn prosthetic is staged")
	var pressed: Array[StringName] = []
	for button: Button in screen.item_buttons():
		if button.button_pressed:
			pressed.append(button.get_meta("item_id") as StringName)
	check_eq(pressed, [&"grandfather_hilt", &"rustwire_blade", &"salvage_arm"], "the staged items are pressed")
	screen.free()
	GameState.reset()


func test_confirm_writes_every_slot_and_closes_once() -> void:
	var screen: EquipmentScreen = _screen()
	var count: Array[int] = _closes(screen)
	screen.open()
	_press(screen, &"swift_hilt")
	_press(screen, &"arc_arm")
	screen.show_hero(&"bilqis")
	_press(screen, &"lens_array")
	check(GameState.equipment.is_empty(), "nothing saved before Confirm")
	screen.confirm()
	screen.confirm()
	check_eq(GameState.equipment[&"zayd.hilt"], &"swift_hilt", "hilt saved")
	check_eq(GameState.equipment[&"zayd.blade"], &"rustwire_blade", "blade kept")
	check_eq(GameState.equipment[&"zayd.prosthetic"], &"arc_arm", "Zayd's prosthetic saved")
	check_eq(GameState.equipment[&"bilqis.prosthetic"], &"lens_array", "Bilqis's prosthetic saved")
	check_eq(count[0], 1, "closed emitted once")
	check(not screen.is_open(), "closed")
	screen.free()
	GameState.reset()


func test_unowned_items_are_refused_and_back_changes_nothing() -> void:
	var screen: EquipmentScreen = _screen()
	var count: Array[int] = _closes(screen)
	screen.open()
	screen.select(&"zayd.hilt", &"anvil_hilt")
	check_eq(screen.staged()[&"zayd.hilt"], &"grandfather_hilt", "an unowned hilt is not staged")
	screen.select(&"zayd.hilt", &"arc_arm")
	check_eq(screen.staged()[&"zayd.hilt"], &"grandfather_hilt", "a prosthetic does not fit the hilt slot")
	_press(screen, &"swift_hilt")
	var back := InputEventAction.new()
	back.action = &"back"
	back.pressed = true
	screen._unhandled_input(back)
	check(GameState.equipment.is_empty(), "equipment unchanged")
	check_eq(count[0], 1, "closed emitted")
	screen.free()
	GameState.reset()


func test_reopening_shows_the_saved_kit() -> void:
	var screen: EquipmentScreen = _screen()
	GameState.equipment[&"zayd.hilt"] = &"swift_hilt"
	screen.open()
	check_eq(screen.staged()[&"zayd.hilt"], &"swift_hilt", "saved hilt")
	check_eq(screen.staged()[&"zayd.blade"], &"rustwire_blade", "start blade")
	screen.free()
	GameState.reset()


func test_comparison_shows_base_against_the_staged_kit() -> void:
	var screen: EquipmentScreen = _screen()
	screen.open()
	_press(screen, &"keen_blade")
	_press(screen, &"arc_arm")
	var base := ContentDB.get_def("combatant", &"zayd") as CombatantDef
	var staged := screen.staged()
	var items: Dictionary[StringName, EquipDef] = {}
	for item_id: StringName in staged.values():
		items[item_id] = ContentDB.get_def("item", item_id) as EquipDef
	var perks: Dictionary[StringName, PerkDef] = {}
	for perk_id: StringName in ContentDB.ids("perk"):
		perks[perk_id] = ContentDB.get_def("perk", perk_id) as PerkDef
	var kit: CombatantDef = EquipmentOptions.fighter(base, &"zayd", staged, items, perks)
	var rows: PackedStringArray = screen.detail().texts()
	check_eq(rows.size(), 8, "eight stat rows")
	check(rows[0].contains("%d | %d" % [base.max_hp, kit.max_hp]), "health: " + rows[0])
	check(rows[1].contains("%d | %d" % [base.max_sp, kit.max_sp]) and rows[1].ends_with("▲"), "arc_arm adds SP: " + rows[1])
	check(rows[2].contains("%d | %d" % [base.attack, kit.attack]), "damage: " + rows[2])
	check(kit.attack > base.attack, "the keen blade and arc arm raise the damage")
	check_eq(screen.detail().item_name(), Ui.text("PROSTHETIC_ARC_ARM"), "the detail describes the last pressed item")
	screen.free()
	GameState.reset()
