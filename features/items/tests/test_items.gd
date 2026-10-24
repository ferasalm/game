extends TestCase
## Rarity tiers and the shipped items: six tiers with the owner's colours, every equippable has a real rarity,
## ids are unique across hilts / blades / prosthetics, the Heirloom is story-only and never loot, and bad
## content (an unknown rarity, a bad colour) is reported.


func _items() -> Array[EquipDef]:
	var out: Array[EquipDef] = []
	for kind: String in ContentDB.ITEM_KINDS:
		for item_id: StringName in ContentDB.ids(kind):
			out.append(ContentDB.get_def(kind, item_id) as EquipDef)
	return out


func test_six_tiers_in_order_with_the_agreed_colours() -> void:
	var expected: Array[String] = ["common", "uncommon", "rare", "epic", "legendary", "heirloom"]
	var orders: Array[int] = []
	for i: int in expected.size():
		var tier := ContentDB.get_def("rarity", StringName(expected[i])) as RarityDef
		check(tier != null, "tier %s exists" % expected[i])
		check_eq(tier.order, i, "%s sorts at %d" % [expected[i], i])
		orders.append(tier.order)
	check_eq(ContentDB.ids("rarity").size(), 6, "exactly six tiers")
	check_eq((ContentDB.get_def("rarity", &"uncommon") as RarityDef).colour, Color.html("#4fc46a"), "green")
	check_eq((ContentDB.get_def("rarity", &"rare") as RarityDef).colour, Color.html("#4a8cf0"), "blue")
	check_eq((ContentDB.get_def("rarity", &"legendary") as RarityDef).colour, Color.html("#f0b83a"), "gold")
	var heirloom := ContentDB.get_def("rarity", &"heirloom") as RarityDef
	check_eq(heirloom.colour, Color.html("#d9503f"), "Yemeni carnelian red")
	check(heirloom.story_only, "the Heirloom is story-only")
	for tier_id: StringName in ContentDB.ids("rarity"):
		var tier := ContentDB.get_def("rarity", tier_id) as RarityDef
		check(tier.story_only == (tier_id == &"heirloom"), "%s: only the Heirloom is story-only" % tier_id)
		check(tier.allows_perk == (tier.order >= 2), "%s: perks from Rare up" % tier_id)


func test_every_item_has_a_real_rarity_and_text() -> void:
	check_eq(ContentDB.load_all(), PackedStringArray(), "the shipped content has no dangling ids")
	for item: EquipDef in _items():
		check(ContentDB.get_def("rarity", item.rarity) != null, "%s has rarity %s" % [item.id, item.rarity])
		check(tr(item.name_key) != item.name_key and tr(item.desc_key) != item.desc_key, "%s has text" % item.id)


func test_item_ids_are_unique_across_kinds_and_within_the_budget() -> void:
	var seen: Dictionary[StringName, bool] = {}
	for item: EquipDef in _items():
		check(not seen.has(item.id), "%s is in one kind only" % item.id)
		seen[item.id] = true
		check(ContentDB.get_def("item", item.id) == item, "get_def(item) finds %s" % item.id)
	check_eq(seen.size(), 4 + 8 + 5 + 4 + 4, "4 old items + 8 new ones + 5 armors + 4 pistol parts + 4 rings")


func test_the_heirloom_hilt_is_the_start_hilt_and_never_loot() -> void:
	var start := ContentDB.get_def("loadout", &"zayd_start") as LoadoutDef
	check_eq((ContentDB.get_def("hilt", start.hilt) as HiltDef).rarity, &"heirloom", "Zayd starts with the Heirloom")
	var given: Array[StringName] = []
	for encounter_id: StringName in ContentDB.ids("encounter"):
		given.append_array((ContentDB.get_def("encounter", encounter_id) as EncounterDef).loot)
	for chest_id: StringName in ContentDB.ids("chest"):
		given.append((ContentDB.get_def("chest", chest_id) as ChestDef).item)
	for item_id: StringName in given:
		var item := ContentDB.get_def("item", item_id) as EquipDef
		check(not (ContentDB.get_def("rarity", item.rarity) as RarityDef).story_only, "%s is not story-only" % item_id)


func test_the_prototype_plan_is_in_the_data() -> void:
	var patrol := ContentDB.get_def("encounter", &"rooftop_patrol") as EncounterDef
	check_eq(patrol.loot, [&"anvil_hilt"] as Array[StringName], "the patrol drops one Rare")
	check_eq((ContentDB.get_def("hilt", &"anvil_hilt") as HiltDef).rarity, &"rare", "anvil hilt is Rare")
	var tiers: Dictionary[StringName, int] = {}
	for item: EquipDef in _items():
		tiers[item.rarity] = tiers.get(item.rarity, 0) + 1
	check(tiers.get(&"legendary", 0) >= 1, "a Legendary exists in data")
	var obtainable: Array[StringName] = []
	for chest_id: StringName in ContentDB.ids("chest"):
		obtainable.append((ContentDB.get_def("chest", chest_id) as ChestDef).item)
	obtainable.append_array(patrol.loot)
	for item: EquipDef in _items():
		if item.rarity == &"legendary":
			check(not obtainable.has(item.id), "%s (Legendary) is not obtainable yet" % item.id)
	check_eq((ContentDB.get_def("prosthetic", &"arc_arm") as ProstheticDef).rarity, &"epic", "a chest holds an Epic prosthetic")
	check_eq((ContentDB.get_def("prosthetic", &"lens_array") as ProstheticDef).rarity, &"uncommon", "a chest holds an Uncommon one")


func test_bad_content_is_reported() -> void:
	var db: Node = load("res://core/content_db.gd").new()
	var problems: PackedStringArray = db.call("load_all", "res://features/items/tests/fixtures/bad_items")
	var joined: String = "\n".join(problems)
	check(joined.contains("needs missing rarity 'mythic'"), "unknown rarity: " + joined)
	check(joined.contains("is not a hex colour"), "bad colour: " + joined)
	check(joined.contains("rarity: missing"), "a hilt without a rarity: " + joined)
	check(joined.contains("needs missing perk 'ghost_perk'"), "unknown perk: " + joined)
	db.free()
