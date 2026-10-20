extends TestCase
## Starting positions and ambushes, the first-hit-only knockback bonus, downed units, and lands_before().

const RANGES: Dictionary[String, int] = {
	"party_start_min": 3000, "party_start_max": 4500, "enemy_start_min": 100, "enemy_start_max": 2000}


func _crowd(ambush: int) -> BattleSim:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h"), BattleProbe.fighter(&"k")]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f"), BattleProbe.fighter(&"g")]
	return BattleProbe.sim(heroes, [0, 2] as Array[int], foes, [0, 1] as Array[int],
		[BattleProbe.move(&"hit")], RANGES, [] as Array[StatusDef], ambush)


func _all_in(sim: BattleSim, side: int, low: int, high: int) -> bool:
	for unit: UnitState in sim.timeline.units:
		if unit.side == side and (unit.pos < low or unit.pos > high):
			return false
	return true


func _positions(sim: BattleSim) -> Array[int]:
	var out: Array[int] = []
	for unit: UnitState in sim.timeline.units:
		out.append(unit.pos)
	return out


func test_units_start_at_seeded_random_positions() -> void:
	var sim: BattleSim = _crowd(0)
	check(_all_in(sim, 0, 3000, 4500), "party starts in the party range")
	check(_all_in(sim, 1, 100, 2000), "enemies start in the enemy range")
	check_eq(_positions(sim), _positions(_crowd(0)), "same seed, same starts")
	check(_positions(sim)[0] != _positions(sim)[1], "units do not all start together")


func test_ambushed_party_swaps_the_ranges() -> void:
	var sim: BattleSim = _crowd(1)
	check(_all_in(sim, 0, 100, 2000), "ambushed: the party starts low")
	check(_all_in(sim, 1, 3000, 4500), "ambushed: the enemy starts high")


func test_party_ambush_leaves_enemies_at_zero() -> void:
	var sim: BattleSim = _crowd(2)
	check(_all_in(sim, 0, 3000, 4500), "party starts as normal")
	check(_all_in(sim, 1, 0, 0), "enemies start at 0")


func test_shipped_rules_have_the_design_start_ranges() -> void:
	var db: Node = load("res://core/content_db.gd").new()
	db.call("load_all")
	var rules := db.call("get_def", "battle_rules", &"default") as BattleRulesDef
	check_eq([rules.party_start_min, rules.party_start_max, rules.enemy_start_min, rules.enemy_start_max],
		[3000, 4500, 1000, 3000], "start ranges")
	db.free()


func test_knockback_bonus_applies_to_the_first_hit_only() -> void:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h", {"knockback_bonus": 1500})]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", {"max_hp": 999})]
	var moves: Array[ActionDef] = [BattleProbe.move(&"flurry", {"hit_count": 3, "knockback": 800})]
	var sim: BattleSim = BattleProbe.sim(heroes, [0] as Array[int], foes, [0] as Array[int], moves)
	var hero: UnitState = sim.timeline.find(&"h")
	sim.timeline.find(&"f_1").pos = 6000
	hero.acted = moves[0]
	hero.acted_targets = [&"f_1"] as Array[StringName]
	var statuses: Dictionary[StringName, StatusDef] = {}
	var events: Array[TimelineEvent] = BattleResolver.new(sim.rules, sim.rng, sim.timeline, statuses).resolve(hero)
	var positions: Array[int] = []
	for event: TimelineEvent in events:
		if event.kind == &"knocked_back":
			positions.append(event.value)
	check_eq(positions, [3700, 2900, 2100] as Array[int], "800 + 1500 on hit 1, then 800 each")


func test_a_downed_unit_loses_its_cast_and_is_skipped() -> void:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h", {"agility": 70,
		"actions": [&"kill"] as Array[StringName]})]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", {"agility": 99, "max_hp": 5,
		"actions": [&"slow"] as Array[StringName]}), BattleProbe.fighter(&"g", {"agility": 1})]
	var moves: Array[ActionDef] = [BattleProbe.move(&"kill", {"cast_speed": 2.0, "power": 90}),
		BattleProbe.move(&"slow", {"cast_speed": 0.4}), BattleProbe.move(&"hit")]
	var sim: BattleSim = BattleProbe.sim(heroes, [0] as Array[int], foes, [0, 1] as Array[int], moves)
	var picker := func(s: BattleSim, hero: UnitState) -> void:
		s.choose(hero.unit_id, s.actions[&"kill"], &"f_1")
	var trace: Array[TimelineEvent] = BattleProbe.play_until(sim, &"act", picker)
	var foe: UnitState = sim.timeline.find(&"f_1")
	check(foe.phase == UnitState.Phase.CAST or foe.hp == 0, "the foe was casting when it fell")
	check_eq(BattleProbe.count(trace, &"down"), 1, "it went down")
	check_eq(foe.phase, UnitState.Phase.WAIT, "pending cast cleared: phase")
	check(foe.action == null and foe.targets.is_empty(), "pending cast cleared: action and targets")
	var pos: int = foe.pos
	for i: int in 300:
		sim.step()
	check_eq(foe.pos, pos, "a downed unit no longer moves on the timeline")
	check_eq(BattleProbe.count(trace, &"act"), 1, "and never acts")


func test_lands_before_compares_ticks_to_act() -> void:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h", {"agility": 70})]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", {"agility": 99})]
	var fast: ActionDef = BattleProbe.move(&"fast", {"cast_speed": 2.0})
	var slow: ActionDef = BattleProbe.move(&"slow", {"cast_speed": 0.5})
	var sim: BattleSim = BattleProbe.sim(heroes, [0] as Array[int], foes, [0] as Array[int], [fast, slow])
	var hero: UnitState = sim.timeline.find(&"h")
	var foe: UnitState = sim.timeline.find(&"f_1")
	check(not sim.lands_before(hero, fast, foe), "a target that is not casting: false")
	foe.phase = UnitState.Phase.CAST
	foe.action = BattleProbe.move(&"foe", {"cast_speed": 0.4})
	foe.pos = 8000
	# foe: 2000 / 40 = 50 ticks. hero fast: 3000 / 140 = 22. hero slow: 3000 / 35 = 86.
	check(sim.lands_before(hero, fast, foe), "22 ticks beats 50")
	check(not sim.lands_before(hero, slow, foe), "86 ticks loses to 50")
	var jam := StatusDef.new()
	jam.id = &"jammed"
	jam.cast_speed = 0.3
	hero.apply_status(jam)
	check(not sim.lands_before(hero, fast, foe), "a jammed hero is too slow: 3000 / 42 = 72 ticks")


func test_killing_a_unit_that_just_reached_command_releases_the_wait() -> void:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h", {"max_sp": 0})]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", {"max_hp": 5})]
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit", {"power": 90})]
	var sim: BattleSim = BattleProbe.sim(heroes, [0] as Array[int], foes, [0] as Array[int], moves)
	var foe: UnitState = sim.timeline.find(&"f_1")
	foe.phase = UnitState.Phase.COMMAND
	sim.timeline.waiting_for = foe
	var hero: UnitState = sim.timeline.find(&"h")
	hero.acted = moves[0]
	hero.acted_targets = [&"f_1"] as Array[StringName]
	var statuses: Dictionary[StringName, StatusDef] = {}
	BattleResolver.new(sim.rules, sim.rng, sim.timeline, statuses).resolve(hero)
	check(sim.timeline.waiting_for == null, "time is not frozen on a dead unit")
