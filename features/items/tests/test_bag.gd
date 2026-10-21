extends TestCase
## Bag: stack caps with overflow, removal, and reservations (two heroes cannot both claim the last herb;
## release gives the claim back; consume uses it up). ItemEffect: real gains, caps, revive, field vitals.


func _herb(id: StringName) -> ConsumableDef:
	return ContentDB.get_def("consumable", id) as ConsumableDef


func test_shipped_consumables_load() -> void:
	for item_id: StringName in [&"pink_herb", &"yellow_herb", &"white_herb", &"qishr_cup"]:
		check(_herb(item_id) != null, "%s exists" % item_id)
	check(ContentDB.get_def("item", &"pink_herb") == null, "consumables are not equippables")
	check_eq(_herb(&"pink_herb").hp, 120, "pink herb heals 120")
	check(_herb(&"white_herb").revive and _herb(&"white_herb").target == &"ko_ally", "white herb revives")


func test_add_respects_max_stack_and_returns_the_overflow() -> void:
	var bag := Bag.new()
	check_eq(bag.add(&"pink_herb", 3, 5), 0, "3 fit")
	check_eq(bag.add(&"pink_herb", 4, 5), 2, "only 2 more fit: 2 overflow")
	check_eq(bag.count(&"pink_herb"), 5, "capped at the stack")
	check_eq(bag.add(&"pink_herb", 1, 5), 1, "a full stack takes nothing")


func test_remove_never_goes_below_zero_or_reserved() -> void:
	var bag: Bag = Bag.from_counts({&"pink_herb": 2})
	check(not bag.remove(&"pink_herb", 3), "cannot remove more than owned")
	check(bag.reserve(&"pink_herb"), "reserve one")
	check(not bag.remove(&"pink_herb", 2), "a reserved herb cannot be sold")
	check(bag.remove(&"pink_herb", 1), "the free one can")
	check_eq(bag.count(&"pink_herb"), 1, "one left")
	check(bag.consume(&"pink_herb"), "the reserved herb is used")
	check(bag.is_empty(), "no zero entries stay in the bag")


func test_two_heroes_cannot_claim_the_last_herb() -> void:
	var bag: Bag = Bag.from_counts({&"pink_herb": 1})
	check(bag.reserve(&"pink_herb"), "Zayd claims it")
	check_eq(bag.available(&"pink_herb"), 0, "none available")
	check(not bag.reserve(&"pink_herb"), "Bilqis cannot claim it")
	bag.release(&"pink_herb")
	check_eq(bag.available(&"pink_herb"), 1, "released: available again, bag unchanged")
	check_eq(bag.count(&"pink_herb"), 1, "the herb was never spent")
	check(bag.reserve(&"pink_herb"), "now Bilqis can")
	check(bag.consume(&"pink_herb") and not bag.consume(&"pink_herb"), "consumed once only")


func test_snapshot_is_a_copy() -> void:
	var bag: Bag = Bag.from_counts({&"yellow_herb": 2, &"white_herb": 0})
	var snap: Dictionary[StringName, int] = bag.snapshot()
	bag.remove(&"yellow_herb", 1)
	check_eq(snap, {&"yellow_herb": 2} as Dictionary[StringName, int], "zero entries dropped, snapshot unchanged")


func test_item_effect_hp_and_sp_gains_are_capped() -> void:
	var pink: ConsumableDef = _herb(&"pink_herb")
	check_eq(ItemEffect.gains(pink, 100, 10, 400, 24)["hp"], 120, "full 120")
	check_eq(ItemEffect.gains(pink, 350, 10, 400, 24)["hp"], 50, "capped at max HP")
	check(not ItemEffect.changes(ItemEffect.gains(pink, 400, 10, 400, 24)), "full HP: nothing changes")
	check(not ItemEffect.changes(ItemEffect.gains(pink, 0, 10, 400, 24)), "a herb does nothing for a downed hero")
	var yellow: ConsumableDef = _herb(&"yellow_herb")
	check_eq(ItemEffect.gains(yellow, 100, 20, 400, 24)["sp"], 4, "SP capped at max")


func test_item_effect_revive_needs_a_downed_hero() -> void:
	var white: ConsumableDef = _herb(&"white_herb")
	var up: Dictionary = ItemEffect.gains(white, 0, 5, 400, 24)
	check(bool(up["revive"]) and int(up["hp"]) == 120, "Zayd back at 30%: 120")
	check_eq(ItemEffect.gains(white, 0, 5, 280, 36)["hp"], 84, "Bilqis at 84")
	check(not ItemEffect.changes(ItemEffect.gains(white, 50, 5, 400, 24)), "a living hero is not revived")


func test_apply_writes_carried_vitals_and_missing_means_full() -> void:
	var vitals: Dictionary = {&"zayd": {"hp": 100, "sp": 4}}
	var gain: Dictionary = ItemEffect.apply(_herb(&"pink_herb"), vitals, &"zayd", 400, 24)
	check_eq(gain["hp"], 120, "gained 120")
	check_eq(Vitals.hp_of(vitals, &"zayd", 400), 220, "carried HP updated")
	check_eq(Vitals.sp_of(vitals, &"zayd", 24), 4, "SP untouched")
	var full: Dictionary = {}
	check(not ItemEffect.changes(ItemEffect.apply(_herb(&"pink_herb"), full, &"zayd", 400, 24)), "a full hero is unchanged")
	check(full.is_empty(), "and nothing was written")
