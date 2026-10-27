extends TestCase
## purpose: Tests the pure EquipmentOptions rules (owned items only, rarer first, per hero and slot).

const OWNED: Array[StringName] = [
	&"grandfather_hilt", &"swift_hilt", &"rustwire_blade", &"keen_blade", &"salvage_arm", &"arc_arm",
	&"wrist_rig", &"lens_array", &"courier_jacket", &"rig_shawl",
	&"rivet_frame", &"machined_frame", &"rivet_barrel", &"choke_barrel", &"silver_band", &"lattice_ring",
]


func test_options_are_owned_fitting_and_rarer_first() -> void:
	var items: Array[EquipDef] = []
	for kind: String in ContentDB.ITEM_KINDS:
		for item_id: StringName in ContentDB.ids(kind):
			items.append(ContentDB.get_def(kind, item_id) as EquipDef)
	var order: Dictionary[StringName, int] = {}
	for rarity_id: StringName in ContentDB.ids("rarity"):
		order[rarity_id] = UiRarity.order(rarity_id)
	var owned: Array[StringName] = OWNED.duplicate()
	var hilts: Array[EquipDef] = EquipmentOptions.options(owned, items, &"rydan", &"hilt", order)
	check_eq(hilts.map(func(item: EquipDef) -> StringName: return item.id), [&"grandfather_hilt", &"swift_hilt"], "owned hilts, heirloom first")
	var arms: Array[EquipDef] = EquipmentOptions.options(owned, items, &"rydan", &"prosthetic", order)
	check_eq(arms.map(func(item: EquipDef) -> StringName: return item.id), [&"arc_arm", &"salvage_arm"], "Rydan's prosthetics only, epic first")
	var hers: Array[EquipDef] = EquipmentOptions.options(owned, items, &"bilqis", &"prosthetic", order)
	check_eq(hers.map(func(item: EquipDef) -> StringName: return item.id), [&"lens_array", &"wrist_rig"], "Bilqis's own prosthetics")
	check_eq(EquipmentOptions.options(owned, items, &"bilqis", &"hilt", order).size(), 0, "Bilqis has no hilt slot items")
	var frames: Array[EquipDef] = EquipmentOptions.options(owned, items, &"bilqis", &"frame", order)
	check_eq(frames.map(func(item: EquipDef) -> StringName: return item.id), [&"machined_frame", &"rivet_frame"], "Bilqis's pistol frames, rarer first")
	check_eq(EquipmentOptions.options(owned, items, &"rydan", &"frame", order).size(), 0, "Rydan has no frame slot")
	var rings: Array[EquipDef] = EquipmentOptions.options(owned, items, &"rydan", &"accessory", order)
	check_eq(rings.map(func(item: EquipDef) -> StringName: return item.id), [&"lattice_ring", &"silver_band"], "Rydan's rings, rarer first")
	check_eq(EquipmentOptions.options(owned, items, &"bilqis", &"accessory", order).size(), 2, "Bilqis may wear the same rings")
	check_eq(EquipmentOptions.parts_for(&"bilqis"),
		[&"frame", &"barrel", &"armor", &"prosthetic", &"accessory"] as Array[StringName],
		"Bilqis's slots: frame, barrel, armor, prosthetic, accessory")
	check_eq(EquipmentOptions.parts_for(&"rydan"),
		[&"blade", &"hilt", &"armor", &"prosthetic", &"accessory"] as Array[StringName],
		"Rydan's slots: blade, hilt, armor, prosthetic, accessory")


func test_options_sort_by_string_not_stringname_address() -> void:
	var suffix: String = str(Time.get_ticks_usec())
	var first_words: Array[String] = ["zebra", "apple", "mango"]
	var second_words: Array[String] = ["mango", "zebra", "apple"]
	var first: Array[String] = _sorted_ids("a_" + suffix, first_words)
	var second: Array[String] = _sorted_ids("b_" + suffix, second_words)
	check_eq(first, ["apple", "mango", "zebra"], "one creation order sorts by String id")
	check_eq(second, ["apple", "mango", "zebra"], "and another creation order gives the same rows")


func _sorted_ids(prefix: String, words: Array[String]) -> Array[String]:
	var items: Array[EquipDef] = []
	var owned: Array[StringName] = []
	for word: String in words:
		var armor := ArmorDef.new()
		armor.id = StringName("zz_%s_%s" % [prefix, word])
		armor.rarity = &"common"
		armor.heroes = [&"rydan"]
		items.append(armor)
		owned.append(armor.id)
	var order: Dictionary[StringName, int] = {&"common": 0}
	var sorted: Array[EquipDef] = EquipmentOptions.options(owned, items, &"rydan", &"armor", order)
	var out: Array[String] = []
	for item: EquipDef in sorted:
		out.append(String(item.id).trim_prefix("zz_%s_" % prefix))
	return out
