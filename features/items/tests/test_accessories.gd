extends TestCase
## Rings (accessories): socket counts follow rarity (Common 1 ... Epic 2), stones fit by the hilt rule,
## a socketed stone adds to whoever wears the ring, and every hero has an accessory slot.


const SOCKETS_BY_RARITY: Dictionary[StringName, int] = {
	&"common": 1, &"uncommon": 1, &"rare": 2, &"epic": 2,
}


func _ring(id: StringName) -> AccessoryDef:
	return ContentDB.get_def("accessory", id) as AccessoryDef


func _stone(id: StringName) -> StoneDef:
	return ContentDB.get_def("stone", id) as StoneDef


func test_ring_sockets_follow_rarity() -> void:
	var seen: Array[StringName] = []
	for ring_id: StringName in ContentDB.ids("accessory"):
		var ring: AccessoryDef = _ring(ring_id)
		seen.append(ring.rarity)
		var expected: int = SOCKETS_BY_RARITY.get(ring.rarity, -1)
		check_eq(ring.sockets, expected,
			"%s: %s rarity opens %d socket(s)" % [ring_id, ring.rarity, maxi(expected, 0)])
	check_eq(seen.size(), 4, "four rings in the slice")
	for rarity: StringName in SOCKETS_BY_RARITY:
		check(seen.has(rarity), "one ring of each rarity up to Epic")


func test_ring_stones_fit_by_the_hilt_rule() -> void:
	var silver: AccessoryDef = _ring(&"silver_band")
	var lattice: AccessoryDef = _ring(&"lattice_ring")
	check(Accessory.fits(_stone(&"sulaimani"), silver), "a Common stone fits the Common ring")
	check(not Accessory.fits(_stone(&"qamar_stone"), lattice), "a Rare stone needs at least an Uncommon ring")
	check(Accessory.fits(_stone(&"sulaimani"), _ring(&"qamariya_ring")), "a Common stone fits the Rare ring")
	check(Accessory.fits(_stone(&"qamar_stone"), _ring(&"qamariya_ring")), "a Rare stone fits the Rare ring")
	check(not Accessory.fits(_stone(&"jadd_aqiq"), silver), "Heirloom stones never fit a ring")
	check(not Accessory.fits(_stone(&"jadd_aqiq"), _ring(&"sheba_signet")), "not even the Epic signet")


func test_any_hero_may_wear_any_ring() -> void:
	var owned: Array[StringName] = [&"silver_band", &"lattice_ring", &"qamariya_ring", &"sheba_signet"]
	for hero: StringName in [&"zayd", &"bilqis"]:
		for ring_id: StringName in owned:
			var problem: String = Inventory.equip_problem(owned, Inventory.slot_key(hero, &"accessory"), _ring(ring_id))
			check_eq(problem, "", "%s may wear %s" % [hero, ring_id])


func test_a_socketed_stone_adds_to_the_ring_s_wearer() -> void:
	var state := GearState.new()
	state.base = ContentDB.get_def("combatant", &"zayd") as CombatantDef
	state.accessory = _ring(&"silver_band")
	state.accessory_stones = [_stone(&"sulaimani")]
	var out: CombatantDef = Gear.build_hero(&"zayd", state)
	check_eq(out.defense, state.base.defense + 2, "the Sulaimani Agate adds Def +2 from the ring")
	var bare := GearState.new()
	bare.base = state.base
	bare.accessory = _ring(&"silver_band")
	check_eq(Gear.build_hero(&"zayd", bare).defense, state.base.defense, "an empty ring adds nothing")


func test_both_heroes_share_the_start_ring_and_its_stones() -> void:
	var loader := BattleLoader.from_db(ContentDB)
	GameState.start_new()
	GameState.sockets[&"silver_band"] = [&"sulaimani"]
	for hero: StringName in [&"zayd", &"bilqis"]:
		var with_stone: CombatantDef = loader.hero_from_state(hero, GameState)
		GameState.sockets[&"silver_band"] = []
		var without: CombatantDef = loader.hero_from_state(hero, GameState)
		GameState.sockets[&"silver_band"] = [&"sulaimani"]
		check_eq(with_stone.defense - without.defense, 2, "%s wears the one ring and gets its stone" % hero)
	GameState.reset()
