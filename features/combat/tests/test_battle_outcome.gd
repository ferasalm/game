extends TestCase
## The battle contract: BattleSetup carries carried vitals and the bag into units, hero ids come from the party
## list, BattleOutcome reports vitals after (a downed hero stands at ko_stand_hp after a victory only) and the
## bag, and the speed / melee numbers come from the battle rules.


func _setup(vitals: Dictionary = {}, bag: Dictionary = {}) -> BattleSetup:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB, &"patrol_scouts")
	var setup: BattleSetup = loader.make_setup(loader.party_from_equipment({}), 5)
	setup.vitals = vitals
	setup.bag = bag
	return setup


func test_units_start_from_carried_vitals_and_missing_means_full() -> void:
	var sim: BattleSim = BattleSim.create_from(_setup({&"rydan": {"hp": 50, "sp": 3}}))
	var rydan: UnitState = sim.timeline.find(&"rydan")
	var bilqis: UnitState = sim.timeline.find(&"bilqis")
	check(rydan.hp == 50 and rydan.sp == 3, "Rydan starts with his carried HP and SP")
	check(bilqis.hp == bilqis.def.max_hp and bilqis.sp == bilqis.def.max_sp, "Bilqis, no entry: full")


func test_carried_hp_above_max_is_clamped() -> void:
	var sim: BattleSim = BattleSim.create_from(_setup({&"rydan": {"hp": 99999, "sp": 99}}))
	var rydan: UnitState = sim.timeline.find(&"rydan")
	check(rydan.hp == rydan.def.max_hp and rydan.sp == rydan.def.max_sp, "never above the maximum")


func test_hero_ids_come_from_the_party_list() -> void:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB, &"patrol_scouts")
	var solo: Array[CombatantDef] = loader.party_from_equipment({}, [&"bilqis"] as Array[StringName])
	check_eq(solo.size(), 1, "a party of one")
	check_eq(solo[0].id, &"bilqis", "the list decides who fights")
	var setup: BattleSetup = loader.make_setup(solo, 1)
	check_eq(setup.party_ids(), [&"bilqis"] as Array[StringName], "setup.party_ids")
	check_eq(loader.party_from_equipment({}).size(), 2, "empty list: the new-game party")


func test_outcome_reports_vitals_and_bag_after_a_win() -> void:
	var sim: BattleSim = BattleSim.create_from(_setup({}, {&"pink_herb": 2}))
	BattleLoader.autoplay(sim)
	var outcome: BattleOutcome = BattleOutcome.from_sim(sim)
	check_eq(outcome.result, sim.result, "result copied")
	check_eq(outcome.encounter_id, &"patrol_scouts", "encounter id")
	check(outcome.vitals.has(&"rydan") and outcome.vitals.has(&"bilqis"), "a vitals entry per hero")
	check_eq(outcome.bag, {&"pink_herb": 2} as Dictionary, "the unused herbs are still there")
	for hero: StringName in [&"rydan", &"bilqis"]:
		var unit: UnitState = sim.timeline.find(hero)
		check_eq(Vitals.hp_of(outcome.vitals, hero, unit.def.max_hp), maxi(unit.hp, 1) if sim.result == &"victory" else unit.hp, "%s HP after" % hero)


func test_a_downed_hero_stands_at_one_hp_after_victory_only() -> void:
	var sim: BattleSim = BattleSim.create_from(_setup())
	var rydan: UnitState = sim.timeline.find(&"rydan")
	rydan.hp = 0
	sim.timeline.find(&"bilqis").hp = 40
	sim.result = &"victory"
	var won: BattleOutcome = BattleOutcome.from_sim(sim)
	check_eq(Vitals.hp_of(won.vitals, &"rydan", 400), 1, "KO -> ko_stand_hp (1)")
	check_eq(Vitals.hp_of(won.vitals, &"bilqis", 280), 40, "a living hero keeps her HP")
	sim.result = &"defeat"
	var lost: BattleOutcome = BattleOutcome.from_sim(sim)
	check_eq(Vitals.hp_of(lost.vitals, &"rydan", 400), 0, "after a defeat nobody stands up")
	var retry: BattleOutcome = BattleOutcome.from_sim(sim, BattleOutcome.RETRY)
	check_eq(retry.result, BattleOutcome.RETRY, "an explicit result wins")


func test_speed_and_melee_numbers_come_from_the_rules() -> void:
	var rules := BattleRulesDef.new()
	rules.speed_weight_factor = 0.03
	rules.speed_min_mult = 0.5
	var heavy := UnitState.create(BattleProbe.fighter(&"h", {"weight": 10.0, "agility": 20}), &"h", 0, 0, rules)
	check_eq(heavy.speed(), 14, "weight 10 at 3% each costs 30%")
	var plain := UnitState.create(BattleProbe.fighter(&"p", {"weight": 10.0, "agility": 20}), &"p", 0, 0)
	check_eq(plain.speed(), 17, "no rules: the default 1.5% each")
	var shipped := ContentDB.get_def("battle_rules", &"default") as BattleRulesDef
	check_eq(shipped.melee_front_bonus, 0.15, "the shipped front bonus lives in rules.json")
	rules.melee_front_bonus = 0.3
	check_eq(Formation.melee_multiplier(0, 0, rules), 1.3, "and Formation reads it")
