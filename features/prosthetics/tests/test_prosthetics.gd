extends TestCase
## Prosthetics: the merge (base -> hilt -> blade -> prosthetic -> perks -> caps) builds new fighters and never
## touches the shared defs; each hero's prosthetics grant 1-2 tech moves; a prosthetic fits only its wearer.


func _loader() -> BattleLoader:
	return BattleLoader.from_db(ContentDB)


func test_equip_adds_stats_and_granted_moves_to_a_copy() -> void:
	var loader: BattleLoader = _loader()
	var base: CombatantDef = loader.combatants[&"zayd"]
	var arm: ProstheticDef = loader.prosthetics[&"arc_arm"]
	var out: CombatantDef = Prosthetics.equip(base, arm)
	check(out != base, "a new def")
	check_eq(out.max_sp, base.max_sp + arm.sp, "SP from the prosthetic")
	check_eq(out.attack, base.attack + arm.attack, "attack")
	check_eq(out.agility, base.agility + arm.agility, "agility")
	check_eq(out.weight, base.weight + arm.weight, "weight")
	check(out.actions.has(&"arc_discharge") and out.actions.has(&"piston_jab"), "both granted moves")
	check_eq(base.actions.size(), 2, "the shared base keeps its two moves")
	check_eq(base.max_sp, 24, "and its SP")


func test_a_prosthetic_for_someone_else_changes_nothing() -> void:
	var loader: BattleLoader = _loader()
	var bilqis: CombatantDef = loader.combatants[&"bilqis"]
	var out: CombatantDef = Prosthetics.equip(bilqis, loader.prosthetics[&"arc_arm"])
	check_eq(out.attack, bilqis.attack, "no stats")
	check_eq(out.actions, bilqis.actions, "no moves")


func test_caps_and_floors_hold_for_extreme_gear() -> void:
	var loader: BattleLoader = _loader()
	var wild := ProstheticDef.new()
	wild.id = &"wild"
	wild.wearer = &"zayd"
	wild.agility = 500
	wild.weight = -99.0
	wild.hp = -9999
	wild.actions = [&"piston_jab"] as Array[StringName]
	var out: CombatantDef = Prosthetics.equip(loader.combatants[&"zayd"], wild)
	check_eq(out.agility, CombatantDef.AGILITY_MAX, "agility capped")
	check_eq(out.weight, 0.0, "weight floored at 0")
	check_eq(out.max_hp, 1, "HP floored at 1")


func test_gear_build_follows_the_order_and_adds_perks() -> void:
	var loader: BattleLoader = _loader()
	var base: CombatantDef = loader.combatants[&"zayd"]
	var hilt: HiltDef = loader.hilts[&"anvil_hilt"]
	var blade: BladeDef = loader.blades[&"broad_blade"]
	var arm: ProstheticDef = loader.prosthetics[&"arc_arm"]
	var built: CombatantDef = Gear.build(base, hilt, blade, arm, loader.perks)
	check_eq(built.attack, base.attack + blade.attack + arm.attack, "blade and prosthetic attack add")
	check_eq(built.agility, base.agility + hilt.agility + arm.agility, "hilt and prosthetic agility add")
	check_eq(built.knockback_bonus, blade.knockback + 700, "the blade's knockback plus the anvil hilt's heavy_hand")
	check_eq(built.sp_per_act_bonus, 1 + 2, "broad blade steady_current + arc arm surge_current")
	for move_id: StringName in [&"crushing_blow", &"arc_discharge", &"piston_jab"]:
		check(built.actions.has(move_id), "has %s" % move_id)
	check_eq(base.knockback_bonus, 0, "the shared base is untouched")
	check_eq(base.sp_per_act_bonus, 0, "and its perks")


func test_every_prosthetic_grants_one_or_two_existing_moves_to_its_wearer() -> void:
	var loader: BattleLoader = _loader()
	var per_hero: Dictionary[StringName, int] = {}
	for prosthetic: ProstheticDef in loader.prosthetics.values():
		check(prosthetic.actions.size() >= 1 and prosthetic.actions.size() <= 2, "%s grants 1-2 moves" % prosthetic.id)
		check(loader.combatants.has(prosthetic.wearer), "%s has a real wearer" % prosthetic.id)
		for move_id: StringName in prosthetic.actions:
			check(loader.actions.has(move_id), "%s: %s exists" % [prosthetic.id, move_id])
		per_hero[prosthetic.wearer] = per_hero.get(prosthetic.wearer, 0) + 1
	check_eq(per_hero.get(&"zayd", 0), 3, "three for Zayd")
	check_eq(per_hero.get(&"bilqis", 0), 3, "three for Bilqis")
	check_eq(loader.prosthetics[&"salvage_arm"].part, &"arm", "Zayd's steel arm")


func test_start_party_wears_the_start_gear_and_saved_gear_overrides() -> void:
	var loader: BattleLoader = _loader()
	var none: Dictionary[StringName, StringName] = {}
	var party: Array[CombatantDef] = loader.party_from_equipment(none)
	check(party[0].actions.has(&"elder_cut") and party[0].actions.has(&"piston_jab"), "Zayd: heirloom hilt move + salvage arm move")
	check(party[1].actions.has(&"nanite_mend"), "Bilqis: the wrist rig's heal")
	var saved: Dictionary[StringName, StringName] = {&"bilqis.prosthetic": &"dawn_lens", &"zayd.prosthetic": &"cradle_spine"}
	party = loader.party_from_equipment(saved)
	check(party[1].actions.has(&"reboot_pulse") and not party[1].actions.has(&"nanite_mend"), "the saved Dawn Lens replaces the rig")
	check(party[0].actions.has(&"reactive_guard") and not party[0].actions.has(&"piston_jab"), "and Zayd's saved spine the arm")
	check_eq(party[0].hp_regen, 8, "the Cradle Spine's mender_loop (the heirloom hilt adds no regen)")
