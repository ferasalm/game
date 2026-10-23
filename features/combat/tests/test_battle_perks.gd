extends TestCase
## Perks in battle (sp_per_act, hp_regen, start_bonus, bonus_knockback), Perks.apply on a fighter copy, and the
## rarity rule that only Rare and above may carry a perk.


func _sim(hero_props: Dictionary) -> BattleSim:
	var hero := BattleProbe.fighter(&"h", hero_props)
	var foe := BattleProbe.fighter(&"f")
	var heroes: Array[CombatantDef] = [hero]
	var foes: Array[CombatantDef] = [foe]
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit")]
	return BattleProbe.sim(heroes, [0] as Array[int], foes, [0] as Array[int], moves, {"party_start_min": 3000, "party_start_max": 3000})


func _act(sim: BattleSim) -> Array[TimelineEvent]:
	var hero: UnitState = sim.timeline.find(&"h")
	hero.acted = sim.actions[&"hit"]
	hero.acted_targets = [&"f_1"] as Array[StringName]
	return sim._resolver.resolve(hero)


func _perk(kind: StringName, amount: int) -> PerkDef:
	var perk := PerkDef.new()
	perk.id = kind
	perk.kind = kind
	perk.amount = amount
	return perk


func test_sp_per_act_perk_adds_to_the_rules_gain_and_is_capped() -> void:
	var sim: BattleSim = _sim({"sp_per_act_bonus": 2, "max_sp": 20})
	var hero: UnitState = sim.timeline.find(&"h")
	hero.sp = 5
	_act(sim)
	check_eq(hero.sp, 10, "5 + rules 3 + perk 2")
	hero.sp = 19
	_act(sim)
	check_eq(hero.sp, 20, "never above max SP")


func test_hp_regen_perk_heals_after_each_act_up_to_max() -> void:
	var sim: BattleSim = _sim({"hp_regen": 12})
	var hero: UnitState = sim.timeline.find(&"h")
	hero.hp = 50
	var events: Array[TimelineEvent] = _act(sim)
	check_eq(hero.hp, 62, "regen 12 after the act")
	var healed: TimelineEvent = BattleProbe.first(events, &"healed")
	check(healed != null and healed.value == 12 and healed.detail == &"regen", "a healed event tagged regen")
	hero.hp = 95
	_act(sim)
	check_eq(hero.hp, 100, "capped at max HP")
	_act(sim)
	check_eq(BattleProbe.count(_act(sim), &"healed"), 0, "no event at full HP")


func test_start_bonus_perk_moves_the_unit_ahead_on_the_track() -> void:
	var plain: BattleSim = _sim({})
	var ahead: BattleSim = _sim({"start_bonus": 500})
	check_eq(plain.timeline.find(&"h").pos, 3000, "no bonus: the range start")
	check_eq(ahead.timeline.find(&"h").pos, 3500, "start bonus 500")
	var huge: BattleSim = _sim({"start_bonus": 6999})
	check(huge.timeline.find(&"h").pos < Timeline.COMMAND_POINT, "never starts at or past the command point")


func test_perks_apply_to_a_copy_and_stack() -> void:
	var base: CombatantDef = BattleProbe.fighter(&"h", {"knockback_bonus": 100})
	var perks: Array[PerkDef] = [
		_perk(&"sp_per_act", 1), _perk(&"sp_per_act", 2), _perk(&"hp_regen", 8),
		_perk(&"bonus_knockback", 700), _perk(&"start_bonus", 400)]
	var out: CombatantDef = Perks.apply(base, perks)
	check(out != base, "a new def")
	check_eq(out.sp_per_act_bonus, 3, "sp perks add up")
	check_eq(out.hp_regen, 8, "regen")
	check_eq(out.knockback_bonus, 800, "bonus knockback joins the blade's")
	check_eq(out.start_bonus, 400, "start bonus")
	check_eq(base.knockback_bonus, 100, "the shared base is untouched")
	check_eq(base.sp_per_act_bonus, 0, "and so are its perk fields")


func test_perks_exist_only_for_the_four_implemented_kinds() -> void:
	check_eq(PerkDef.KINDS.size(), 7, "seven perk kinds in combat logic")
	for perk_id: StringName in ContentDB.ids("perk"):
		var perk := ContentDB.get_def("perk", perk_id) as PerkDef
		check(PerkDef.KINDS.has(perk.kind) and perk.amount > 0, "%s is a real perk" % perk_id)


func test_shipped_perks_sit_on_rare_and_above_only() -> void:
	for item_id: StringName in _all_items():
		var item := ContentDB.get_def("item", item_id) as EquipDef
		var tier := ContentDB.get_def("rarity", item.rarity) as RarityDef
		check(item.perk_problem(tier).is_empty(), "%s: %s" % [item_id, item.perk_problem(tier)])
		if tier.allows_perk:
			check(item.perk != &"", "%s is %s and carries its extra perk" % [item_id, item.rarity])


func test_a_perk_on_a_common_item_is_reported() -> void:
	var item := BladeDef.new()
	item.id = &"cheat_blade"
	item.perk = &"head_start"
	item.rarity = &"common"
	var tier := ContentDB.get_def("rarity", &"common") as RarityDef
	check(not item.perk_problem(tier).is_empty(), "common cannot carry a perk")
	item.rarity = &"rare"
	check(item.perk_problem(ContentDB.get_def("rarity", &"rare") as RarityDef).is_empty(), "rare can")


func _all_items() -> Array[StringName]:
	var out: Array[StringName] = []
	for kind: String in ContentDB.ITEM_KINDS:
		out.append_array(ContentDB.ids(kind))
	return out
