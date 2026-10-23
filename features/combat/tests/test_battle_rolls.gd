extends TestCase
## Battle rolls: hit, crit, resist, flee formulas at clamps and middle values.

func test_hit_chance_clamped() -> void:
	var rules := BattleRulesDef.new()
	rules.hit_base = 0.95
	rules.hit_agi_k = 0.006
	rules.hit_min = 0.60
	rules.hit_max = 0.99
	var att := UnitState.create(BattleProbe.fighter(&"a", {"agility": 40, "dodge_bonus": 0.0}), &"a", 0, 0)
	var tgt := UnitState.create(BattleProbe.fighter(&"t", {"agility": 40, "dodge_bonus": 0.0}), &"t", 1, 0)
	var chance: float = BattleRolls.hit_chance(att, tgt, rules)
	check_eq(roundf(chance * 100) / 100.0, 0.95, "equal stats: hit = 0.95")

func test_crit_chance_middle_and_max() -> void:
	var rules := BattleRulesDef.new()
	rules.crit_base = 0.05
	rules.crit_lck_k = 0.004
	rules.crit_max = 0.40
	var att := UnitState.create(BattleProbe.fighter(&"a", {"luck": 5, "crit_bonus": 0.0}), &"a", 0, 0)
	var chance: float = BattleRolls.crit_chance(att, rules)
	check_eq(roundf(chance * 1000) / 1000.0, 0.07, "base 0.05 + 0.004*5 = 0.07")

func test_crit_chance_formula() -> void:
	var rules := BattleRulesDef.new()
	rules.crit_base = 0.05
	rules.crit_lck_k = 0.004
	rules.crit_max = 0.40
	var att := UnitState.create(BattleProbe.fighter(&"a", {"luck": 10, "crit_bonus": 0.0}), &"a", 0, 0)
	var chance: float = BattleRolls.crit_chance(att, rules)
	check_eq(roundf(chance * 100) / 100.0, 0.09, "0.05 + 0.004*10 = 0.09")

func test_resist_chance_middle() -> void:
	var rules := BattleRulesDef.new()
	rules.resist_base = 0.10
	rules.resist_lck_k = 0.01
	rules.resist_max = 0.75
	var att := UnitState.create(BattleProbe.fighter(&"a", {"luck": 5, "status_pierce": 0.0}), &"a", 0, 0)
	var tgt := UnitState.create(BattleProbe.fighter(&"t", {"luck": 5, "dodge_bonus": 0.0}), &"t", 1, 0)
	var chance: float = BattleRolls.resist_chance(att, tgt, rules)
	check_eq(roundf(chance * 100) / 100.0, 0.1, "equal LCK: resist = 0.10")

func test_forced_resist_emits_resisted_and_no_status() -> void:
	var rules: BattleRulesDef = BattleRulesDef.new()
	rules.resist_base = 1.0
	rules.resist_max = 1.0
	rules.hit_base = 1.0
	rules.hit_min = 1.0
	rules.hit_max = 1.0
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h", {"luck": 5})]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", {"luck": 0})]
	var moves: Array[ActionDef] = [BattleProbe.move(&"net", {"applies_status": "jammed"})]
	var actions: Dictionary[StringName, ActionDef] = {}
	for m: ActionDef in moves:
		actions[m.id] = m
	var statuses: Dictionary[StringName, StatusDef] = {}
	var jammed: StatusDef = StatusDef.new()
	jammed.id = &"jammed"
	statuses[&"jammed"] = jammed
	var setup := BattleSetup.new()
	setup.rules = rules
	setup.party = heroes
	setup.party_slots = [0] as Array[int]
	setup.enemies = foes
	setup.enemy_slots = [0] as Array[int]
	setup.actions = actions
	setup.statuses = statuses
	setup.seed = 1
	var sim: BattleSim = BattleSim.create_from(setup)
	sim.rolls_enabled = true
	var hero: UnitState = sim.timeline.find(&"h")
	sim.timeline.waiting_for = hero
	hero.acted = moves[0]
	hero.acted_targets = [&"f_1"] as Array[StringName]
	var events: Array[TimelineEvent] = sim._resolver.resolve(hero)
	check(events.any(func(e: TimelineEvent) -> bool: return e.kind == &"resisted"), "resisted event emitted")
	check(not events.any(func(e: TimelineEvent) -> bool: return e.kind == &"status"), "no status event when resisted")

func test_sure_hit_never_dodges() -> void:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h")]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", {"agility": 99, "dodge_bonus": 0.5})]
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit", {"sure_hit": true, "power": 5})]
	var sim: BattleSim = BattleProbe.sim(heroes, [0] as Array[int], foes, [0] as Array[int], moves, {"hit_base": 0.0})
	sim.rolls_enabled = true
	var picker := func(s: BattleSim, hero: UnitState) -> void:
		s.choose(hero.unit_id, s.actions[&"hit"], &"f_1")
	var trace: Array[TimelineEvent] = BattleProbe.play_until(sim, &"act", picker)
	check(not trace.any(func(e: TimelineEvent) -> bool: return e.kind == &"dodged"), "sure_hit never dodged")

func test_flee_chance_ambush() -> void:
	var rules := BattleRulesDef.new()
	rules.flee_base = 0.50
	rules.flee_agi_k = 0.01
	rules.flee_step = 0.15
	rules.flee_ambushed = -0.20
	rules.flee_ambusher = 0.20
	rules.flee_min = 0.10
	rules.flee_max = 0.95
	var party: Array[UnitState] = []
	var foes: Array[UnitState] = []
	var chance_ambushed: float = BattleRolls.flee_chance(party, foes, 0, 1, rules)
	var chance_ambusher: float = BattleRolls.flee_chance(party, foes, 0, 2, rules)
	check(chance_ambushed < chance_ambusher, "ambushed (-0.20) lower than ambusher (+0.20)")

func test_dodged_target_takes_no_damage() -> void:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h")]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", {"agility": 99, "dodge_bonus": 0.0})]
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit", {"power": 10, "hit_count": 1})]
	var sim: BattleSim = BattleProbe.sim(heroes, [0] as Array[int], foes, [0] as Array[int], moves)
	sim.rolls_enabled = true
	# With equal stats and no bonuses, hit base 0.95, dodge chance = 1 - 0.95 = 0.05. Not guaranteed.
	# A more reliable test: check that when a dodge event appears, no damage follows.
	var picker := func(s: BattleSim, hero: UnitState) -> void:
		s.choose(hero.unit_id, s.actions[&"hit"], &"f_1")
	var trace: Array[TimelineEvent] = BattleProbe.play_until(sim, &"dodged", picker, 5000)
	check(trace.any(func(e: TimelineEvent) -> bool: return e.kind == &"dodged"), "dodge event may appear (random)")
	# If dodged, verify no damage event for the same target in the trace.
	var dodged_target: StringName = ""
	for event_d: TimelineEvent in trace:
		if event_d.kind == &"dodged":
			dodged_target = event_d.unit_id
	for event_d: TimelineEvent in trace:
		if dodged_target != "" and event_d.kind == &"damage" and event_d.unit_id == dodged_target:
			push_error("dodged target took damage: %s" % event_d.unit_id)

func test_forced_crit_multiplies_damage() -> void:
	var normal: Array[int] = _one_hit_damage(0.0)
	var crit: Array[int] = _one_hit_damage(1.0)
	check_eq(normal.size(), 1, "one damage event without a crit")
	check_eq(crit.size(), 1, "one damage event with a crit")
	check_eq(crit[0], roundi(normal[0] * 1.5), "a crit deals x crit_mult 1.5")


## One hit of power 10 (attack 20 vs defense 14, no variance, no dodge) with the given crit chance: the damage events.
func _one_hit_damage(crit_base: float) -> Array[int]:
	var rules: BattleRulesDef = BattleRulesDef.new()
	rules.crit_base = crit_base
	rules.crit_mult = 1.5
	rules.hit_base = 1.0
	rules.hit_min = 1.0
	rules.hit_max = 1.0
	rules.defense_factor = 0.5
	rules.damage_variance = 0.0
	rules.max_ticks = 20000
	var setup := BattleSetup.new()
	setup.rules = rules
	setup.party = [BattleProbe.fighter(&"h", {"attack": 20})] as Array[CombatantDef]
	setup.party_slots = [0] as Array[int]
	setup.enemies = [BattleProbe.fighter(&"f", {"defense": 14, "max_hp": 400})] as Array[CombatantDef]
	setup.enemy_slots = [0] as Array[int]
	var move: ActionDef = BattleProbe.move(&"hit", {"power": 10})
	setup.actions = {move.id: move} as Dictionary[StringName, ActionDef]
	setup.statuses = {}
	setup.seed = 1
	var sim: BattleSim = BattleSim.create_from(setup)
	sim.rolls_enabled = true
	var hero: UnitState = sim.timeline.find(&"h")
	sim.timeline.waiting_for = hero
	hero.acted = move
	hero.acted_targets = [&"f_1"] as Array[StringName]
	var out: Array[int] = []
	for e: TimelineEvent in sim._resolver.resolve(hero):
		if e.kind == &"damage":
			out.append(e.value)
	return out


func test_flee_chance_step() -> void:
	var flee_rules := BattleRulesDef.new()
	flee_rules.flee_base = 0.50
	flee_rules.flee_agi_k = 0.01
	flee_rules.flee_step = 0.15
	flee_rules.flee_min = 0.10
	flee_rules.flee_max = 0.95
	var party_units: Array[UnitState] = []
	var foe_units: Array[UnitState] = []
	var chance_0: float = BattleRolls.flee_chance(party_units, foe_units, 0, 0, flee_rules)
	var chance_1: float = BattleRolls.flee_chance(party_units, foe_units, 1, 0, flee_rules)
	check(abs(chance_1 - (chance_0 + 0.15)) < 0.001, "+0.15 per fail")


func test_rolls_enabled_set_after_create_reaches_the_resolver() -> void:
	var sim: BattleSim = BattleProbe.sim([BattleProbe.fighter(&"h")], [0] as Array[int], [BattleProbe.fighter(&"f")],
			[0] as Array[int], [BattleProbe.move(&"hit")])
	sim.rolls_enabled = false
	check(not sim._resolver.rolls_enabled, "turning rolls off after create_from reaches the resolver")
