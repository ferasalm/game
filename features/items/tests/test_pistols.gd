extends TestCase
## Bilqis's rivet pistol: the frame merges like a hilt, the barrel like a blade; both fit only their wielder;
## the start loadout wears the Common pair; upgrades add per level; the ring every hero wears starts empty.


func _pistol(id: StringName) -> PistolDef:
	return ContentDB.get_def("pistol", id) as PistolDef


func _bilqis() -> CombatantDef:
	return (ContentDB.get_def("combatant", &"bilqis") as CombatantDef)


func test_pistol_content_has_two_frames_and_two_barrels() -> void:
	var frames: Array[StringName] = []
	var barrels: Array[StringName] = []
	for part_id: StringName in ContentDB.ids("pistol"):
		var part: PistolDef = _pistol(part_id)
		if part.part == &"frame":
			frames.append(part_id)
		else:
			barrels.append(part_id)
	check_eq(frames.size(), 2, "two frames")
	check_eq(barrels.size(), 2, "two barrels")
	var start_frame: PistolDef = _pistol(&"rivet_frame")
	check_eq(start_frame.rarity, &"common", "the start frame is Common")
	check_eq(_pistol(&"rivet_barrel").rarity, &"common", "the start barrel is Common")
	check(frames.has(&"machined_frame") and barrels.has(&"choke_barrel"), "one Uncommon of each")


func test_frame_merges_like_a_hilt_and_barrel_like_a_blade() -> void:
	var frame: PistolDef = _pistol(&"machined_frame")
	var barrel: PistolDef = _pistol(&"choke_barrel")
	var state := GearState.new()
	state.base = _bilqis()
	state.frame = frame
	state.barrel = barrel
	var out: CombatantDef = Gear.build_hero(&"bilqis", state)
	check_eq(out.attack, state.base.attack + barrel.attack, "the barrel adds attack like a blade")
	check_eq(out.knockback_bonus, state.base.knockback_bonus + barrel.knockback, "and knockback")
	check_eq(out.agility, state.base.agility + frame.agility, "the frame adds agility like a hilt")
	check_eq(out.weight, state.base.weight + frame.weight + barrel.weight, "both parts add weight")
	check_eq(state.base.attack, 16, "the shared base is untouched")


func test_pistol_parts_fit_only_bilqis_in_their_own_slot() -> void:
	var owned: Array[StringName] = [&"rivet_frame", &"machined_frame", &"rivet_barrel", &"choke_barrel"]
	check_eq(Inventory.equip_problem(owned, &"bilqis.frame", _pistol(&"rivet_frame")), "", "the frame in her frame slot")
	check_eq(Inventory.equip_problem(owned, &"bilqis.barrel", _pistol(&"rivet_barrel")), "", "the barrel in her barrel slot")
	check(Inventory.equip_problem(owned, &"bilqis.frame", _pistol(&"rivet_barrel")) != "",
		"a barrel never goes in the frame slot")
	check(Inventory.equip_problem(owned, &"rydan.frame", _pistol(&"rivet_frame")) != "",
		"Rydan has no frame slot")
	var swift: EquipDef = ContentDB.get_def("hilt", &"swift_hilt") as EquipDef
	check(Inventory.equip_problem(owned, &"bilqis.frame", swift) != "", "a hilt never goes in the frame slot")
	check_eq(Inventory.equip_problem(owned, &"nonsense", _pistol(&"rivet_frame")), "'nonsense' is not a slot",
		"a bad slot is refused")


func test_start_loadout_wears_the_common_pair_and_the_ring() -> void:
	var start: LoadoutDef = null
	var rydan_start: LoadoutDef = null
	for l_id: StringName in ContentDB.ids("loadout"):
		var l := ContentDB.get_def("loadout", l_id) as LoadoutDef
		if l.hero == &"bilqis":
			start = l
		elif l.hero == &"rydan":
			rydan_start = l
	check(start != null and rydan_start != null, "both start loadouts exist")
	check_eq(Loadout.worn({}, start, &"frame"), &"rivet_frame", "the saved choice, else the start frame")
	check_eq(Loadout.worn({}, start, &"barrel"), &"rivet_barrel", "and barrel")
	check_eq(Loadout.worn({}, start, &"accessory"), &"silver_band", "and the Common ring")
	check_eq(Loadout.worn({}, start, &"armor"), &"", "armor never comes from the loadout")
	check_eq(Loadout.worn({}, rydan_start, &"accessory"), &"silver_band", "Rydan starts with the ring too")
	check_eq(Loadout.worn({}, rydan_start, &"frame"), &"", "but no pistol")


func test_start_party_fights_with_the_pistol_worn() -> void:
	var loader := BattleLoader.from_db(ContentDB)
	var none: Dictionary[StringName, StringName] = {}
	var party: Array[CombatantDef] = loader.party_from_equipment(none)
	var bilqis: CombatantDef = party[1]
	var bare: CombatantDef = _bilqis()
	var rig: ProstheticDef = ContentDB.get_def("prosthetic", &"wrist_rig") as ProstheticDef
	check_eq(bilqis.attack, bare.attack + _pistol(&"rivet_barrel").attack, "the start barrel is worn")
	check_eq(bilqis.weight, bare.weight + rig.weight + _pistol(&"rivet_frame").weight + _pistol(&"rivet_barrel").weight,
		"both start parts are worn")
	var rydan: CombatantDef = party[0]
	var rydan_base: CombatantDef = ContentDB.get_def("combatant", &"rydan") as CombatantDef
	var rydan_blade: BladeDef = ContentDB.get_def("blade", &"rustwire_blade") as BladeDef
	var rydan_arm: ProstheticDef = ContentDB.get_def("prosthetic", &"salvage_arm") as ProstheticDef
	check_eq(rydan.attack, rydan_base.attack + rydan_blade.attack + rydan_arm.attack, "Rydan keeps his start blade and arm")


func test_pistol_upgrades_add_per_level() -> void:
	var state := GearState.new()
	state.base = _bilqis()
	state.frame = _pistol(&"rivet_frame")
	state.barrel = _pistol(&"rivet_barrel")
	state.upgrades = {&"rivet_barrel": 2}
	var out: CombatantDef = Gear.build_hero(&"bilqis", state)
	check_eq(out.attack, state.base.attack + 2 + 2 * 2, "the barrel upgrade adds attack per level")
	state.upgrades = {&"rivet_frame": 3}
	out = Gear.build_hero(&"bilqis", state)
	check_eq(out.agility, state.base.agility + 3, "the frame upgrade adds agility per level")


func test_machined_frame_casts_faster_and_rivet_frame_is_plain() -> void:
	var machined: PistolDef = _pistol(&"machined_frame")
	var rivet: PistolDef = _pistol(&"rivet_frame")
	check_eq(machined.cast_speed, 0.95, "the machined frame casts 5%% faster")
	check_eq(rivet.cast_speed, 1.0, "the start frame leaves cast speed alone")
	check_eq(machined.ability, &"", "no pistol part grants a move in the slice")
	check_eq(rivet.ability, &"", "the start frame grants no move either")
