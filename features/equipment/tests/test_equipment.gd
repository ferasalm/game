extends TestCase
## purpose: Tests the pure EquipmentOptions rules (owned items only, rarer first, per hero and slot).

const OWNED: Array[StringName] = [
	&"grandfather_hilt", &"swift_hilt", &"rustwire_blade", &"keen_blade", &"salvage_arm", &"arc_arm",
	&"wrist_rig", &"lens_array", &"courier_jacket", &"rig_shawl",
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
	var hilts: Array[EquipDef] = EquipmentOptions.options(owned, items, &"zayd", &"hilt", order)
	check_eq(hilts.map(func(item: EquipDef) -> StringName: return item.id), [&"grandfather_hilt", &"swift_hilt"], "owned hilts, heirloom first")
	var arms: Array[EquipDef] = EquipmentOptions.options(owned, items, &"zayd", &"prosthetic", order)
	check_eq(arms.map(func(item: EquipDef) -> StringName: return item.id), [&"arc_arm", &"salvage_arm"], "Zayd's prosthetics only, epic first")
	var hers: Array[EquipDef] = EquipmentOptions.options(owned, items, &"bilqis", &"prosthetic", order)
	check_eq(hers.map(func(item: EquipDef) -> StringName: return item.id), [&"lens_array", &"wrist_rig"], "Bilqis's own prosthetics")
	check_eq(EquipmentOptions.options(owned, items, &"bilqis", &"hilt", order).size(), 0, "Bilqis has no hilt slot items")
	check_eq(EquipmentOptions.parts_for(&"bilqis"), [&"armor", &"prosthetic"] as Array[StringName], "two slots for Bilqis")
	check_eq(EquipmentOptions.parts_for(&"zayd").size(), 4, "four slots for Zayd")


func test_options_sort_by_string_not_stringname_address() -> void:
	var suffix: String = str(Time.get_ticks_usec())
	var first: Array[String] = _sorted_ids("a_" + suffix, ["zebra", "apple", "mango"])
	var second: Array[String] = _sorted_ids("b_" + suffix, ["mango", "zebra", "apple"])
	check_eq(first, ["apple", "mango", "zebra"], "one creation order sorts by String id")
	check_eq(second, ["apple", "mango", "zebra"], "and another creation order gives the same rows")


func _sorted_ids(prefix: String, words: Array[String]) -> Array[String]:
	var items: Array[EquipDef] = []
	var owned: Array[StringName] = []
	for word: String in words:
		var armor := ArmorDef.new()
		armor.id = StringName("zz_%s_%s" % [prefix, word])
		armor.rarity = &"common"
		armor.heroes = [&"zayd"]
		items.append(armor)
		owned.append(armor.id)
	var order: Dictionary[StringName, int] = {&"common": 0}
	var sorted: Array[EquipDef] = EquipmentOptions.options(owned, items, &"zayd", &"armor", order)
	var out: Array[String] = []
	out.assign(sorted.map(func(item: EquipDef) -> String: return String(item.id).trim_prefix("zz_%s_" % prefix)))
	return out
