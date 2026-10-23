extends TestCase
## Tests for jambiyah hilt gemstones: rarity fit rules, heirloom slot progression, and socket operations.


func _hilt(rarity: StringName) -> HiltDef:
	var hilt := HiltDef.new()
	hilt.id = StringName("%s_hilt" % rarity)
	hilt.rarity = rarity
	return hilt


func _stone(rarity: StringName) -> StoneDef:
	var stone := StoneDef.new()
	stone.id = StringName("%s_stone" % rarity)
	stone.rarity = rarity
	return stone


func test_stones_fit_by_rarity() -> void:
	var common_hilt: HiltDef = _hilt(&"common")
	var uncommon_hilt: HiltDef = _hilt(&"uncommon")
	var rare_hilt: HiltDef = _hilt(&"rare")
	var heirloom_hilt: HiltDef = _hilt(&"heirloom")

	var common_stone: StoneDef = _stone(&"common")
	var uncommon_stone: StoneDef = _stone(&"uncommon")
	var rare_stone: StoneDef = _stone(&"rare")
	var heirloom_stone: StoneDef = _stone(&"heirloom")

	check(not Stones.fits(common_stone, common_hilt), "common hilt has 0 slots")
	check(Stones.fits(common_stone, uncommon_hilt), "common stone fits uncommon hilt")
	check(Stones.fits(uncommon_stone, uncommon_hilt), "uncommon stone fits uncommon hilt")
	check(not Stones.fits(rare_stone, uncommon_hilt), "rare stone cannot fit uncommon hilt")
	check(Stones.fits(rare_stone, rare_hilt), "rare stone fits rare hilt")
	check(not Stones.fits(heirloom_stone, rare_hilt), "heirloom stone fits only heirloom hilt")
	check(Stones.fits(common_stone, heirloom_hilt), "common stone fits heirloom hilt")
	check(Stones.fits(rare_stone, heirloom_hilt), "rare stone fits heirloom hilt")
	check(Stones.fits(heirloom_stone, heirloom_hilt), "heirloom stone fits heirloom hilt")


func test_heirloom_rank_1_opens_1_slot() -> void:
	var heirloom_hilt: HiltDef = _hilt(&"heirloom")
	check_eq(Stones.open_slots(heirloom_hilt, {}), 1, "rank 1 opens 1 slot by default")
	check_eq(Stones.open_slots(heirloom_hilt, {&"heirloom_rank_2": true}), 2, "rank 2 opens 2 slots")
	check_eq(Stones.open_slots(heirloom_hilt, {&"heirloom_rank_3": true}), 3, "rank 3 opens 3 slots")


func test_moving_a_stone_empties_its_old_socket() -> void:
	var sockets: Dictionary = {
		&"grandfather_hilt": [&"aqiq_red", &""],
		&"swift_hilt": [&""]
	}
	Stones.set_stone(sockets, &"swift_hilt", 0, &"aqiq_red")
	check_eq(sockets[&"grandfather_hilt"][0], &"", "old socket is emptied")
	check_eq(sockets[&"swift_hilt"][0], &"aqiq_red", "stone moved to new socket")
