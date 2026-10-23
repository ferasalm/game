extends TestCase
## T5: damage, SP, cover, retargeting and status turns follow docs/design/combat.md.
## Heroes are fast (agility 99) and foes crawl (agility 1), so the hero's first act is the only action.


func _duel(hero_props: Dictionary, foe_props: Dictionary, moves: Array[ActionDef], rule_props: Dictionary = {},
		status_list: Array[StatusDef] = []) -> BattleSim:
	hero_props["agility"] = 99
	if not hero_props.has("actions"):
		var ids: Array[StringName] = []
		for move: ActionDef in moves:
			ids.append(move.id)
		hero_props["actions"] = ids
	foe_props["agility"] = 1
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h", hero_props)]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", foe_props)]
	return BattleProbe.sim(heroes, [0] as Array[int], foes, [0] as Array[int], moves, rule_props, status_list)


func _act_once(sim: BattleSim, move_id: StringName) -> Array[TimelineEvent]:
	var picker := func(s: BattleSim, hero: UnitState) -> void:
		s.choose(hero.unit_id, s.actions[move_id], &"f_1")
	return BattleProbe.play_until(sim, &"act", picker)


func _values(trace: Array[TimelineEvent], kind: StringName) -> Array[int]:
	var out: Array[int] = []
	for event: TimelineEvent in trace:
		if event.kind == kind:
			out.append(event.value)
	return out


func test_damage_formula_with_row_multiplier() -> void:
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit", {"power": 10, "hit_count": 2}),
		BattleProbe.move(&"shot", {"power": 14, "is_melee": false})]
	var sim: BattleSim = _duel({"attack": 20}, {"defense": 14, "max_hp": 400}, moves)
	var trace: Array[TimelineEvent] = _act_once(sim, &"hit")
	# (10 + (20 - 14 * 0.5) / 2) * 1.15 (front hits front) = 18.975 -> 19, once per hit
	check_eq(_values(trace, &"damage"), [19, 19] as Array[int], "two melee hits")
	check_eq(sim.timeline.find(&"f_1").hp, 362, "hp after both hits")
	var ranged: BattleSim = _duel({"attack": 16}, {"defense": 14, "max_hp": 400}, moves)
	check_eq(_values(_act_once(ranged, &"shot"), &"damage"), [23] as Array[int], "ranged: 14 + 16 - 7, no row bonus")


func test_damage_is_at_least_one_and_hp_never_negative() -> void:
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit", {"power": 1, "hit_count": 3})]
	var sim: BattleSim = _duel({"attack": 1}, {"defense": 999}, moves)
	check_eq(_values(_act_once(sim, &"hit"), &"damage"), [1, 1, 1] as Array[int], "minimum damage is 1")
	var big: Array[ActionDef] = [BattleProbe.move(&"hit", {"power": 900, "hit_count": 2})]
	var kill: BattleSim = _duel({}, {"max_hp": 10}, big)
	var trace: Array[TimelineEvent] = _act_once(kill, &"hit")
	check_eq(kill.timeline.find(&"f_1").hp, 0, "hp stops at 0")
	check_eq(BattleProbe.count(trace, &"damage"), 1, "a dead target takes no more hits")
	check_eq(BattleProbe.count(trace, &"knocked_back"), 0, "a target at 0 hp gets no timeline effect")
	check_eq(BattleProbe.count(trace, &"down"), 1, "down is reported once")
	check_eq(kill.result, &"victory", "last enemy down wins the battle")


func test_variance_stays_in_range() -> void:
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit", {"power": 10, "hit_count": 9})]
	var sim: BattleSim = _duel({"attack": 20}, {"defense": 14, "max_hp": 9999}, moves, {"damage_variance": 0.1})
	var seen: Dictionary[int, bool] = {}
	for amount: int in _values(_act_once(sim, &"hit"), &"damage"):
		check(amount >= 11 and amount <= 15, "13.16 +-10%% stays in 11..15, got %d" % amount)
		seen[amount] = true
	check(seen.size() > 1, "variance actually varies")


func test_sp_is_paid_at_choice_and_gained_per_act() -> void:
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit"), BattleProbe.move(&"big", {"sp_cost": 8})]
	var props: Dictionary = {"max_sp": 10, "actions": [&"hit", &"big"] as Array[StringName]}
	var sim: BattleSim = _duel(props, {"max_hp": 999}, moves)
	var hero: UnitState = sim.timeline.find(&"h")
	BattleProbe.play_until(sim, &"command", Callable())
	check_eq(sim.choose(&"h", moves[1], &"f_1"), "", "big move chosen")
	check_eq(hero.sp, 2, "8 SP paid when chosen")
	BattleProbe.play_until(sim, &"act", Callable())
	check_eq(hero.sp, 5, "+3 SP for acting")
	var capped: BattleSim = _duel({"max_sp": 10}, {"max_hp": 999}, moves)
	_act_once(capped, &"hit")
	check_eq(capped.timeline.find(&"h").sp, 10, "SP is capped at the maximum")


func test_cover_blocks_moves_without_ignores_cover() -> void:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h"), BattleProbe.fighter(&"k")]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f"), BattleProbe.fighter(&"g")]
	var moves: Array[ActionDef] = [BattleProbe.move(&"melee"), BattleProbe.move(&"shot", {"is_melee": false}),
		BattleProbe.move(&"arc", {"is_melee": false, "ignores_cover": true})]
	var sim: BattleSim = BattleProbe.sim(heroes, [0, 2] as Array[int], foes, [0, 2] as Array[int], moves)
	var hero: UnitState = sim.timeline.find(&"h")
	var ids := func(targets: Array[UnitState]) -> Array:
		return targets.map(func(u: UnitState) -> StringName: return u.unit_id)
	check_eq(ids.call(sim.valid_targets(hero, moves[0])), [&"f_1"], "melee cannot reach the covered rearguard")
	check_eq(ids.call(sim.valid_targets(hero, moves[1])), [&"f_1"], "a plain missile is covered too")
	check_eq(ids.call(sim.valid_targets(hero, moves[2])), [&"f_1", &"g_1"], "ignores_cover reaches the rear")
	check_eq(ids.call(sim.valid_targets(sim.timeline.find(&"f_1"), moves[0])), [&"h"], "the party's rear is covered")
	sim.timeline.find(&"f_1").hp = 0
	check_eq(ids.call(sim.valid_targets(hero, moves[0])), [&"g_1"], "once the front falls the rear is open")


func test_retarget_when_the_target_is_already_down() -> void:
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h"), BattleProbe.fighter(&"k", {"agility": 98})]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", {"agility": 1, "max_hp": 20}),
		BattleProbe.fighter(&"f", {"agility": 1, "max_hp": 400})]
	heroes[0].agility = 99
	var moves: Array[ActionDef] = [BattleProbe.move(&"hit", {"power": 100})]
	var sim: BattleSim = BattleProbe.sim(heroes, [0, 1] as Array[int], foes, [0, 1] as Array[int], moves)
	var picker := func(s: BattleSim, hero: UnitState) -> void:
		s.choose(hero.unit_id, s.actions[&"hit"], &"f_1")
	var trace: Array[TimelineEvent] = BattleProbe.play_until(sim, &"act", picker)
	trace.append_array(BattleProbe.play_until(sim, &"act", picker))
	var damaged: PackedStringArray = []
	for event: TimelineEvent in trace:
		if event.kind == &"damage" or event.kind == &"down":
			damaged.append("%s:%s" % [event.kind, event.unit_id])
	check_eq(",".join(damaged), "damage:f_1,down:f_1,damage:f_2", "second hero retargets to the next living foe")


func test_act_fizzles_with_no_valid_target() -> void:
	var sim: BattleSim = _duel({}, {}, [BattleProbe.move(&"hit")])
	var hero: UnitState = sim.timeline.find(&"h")
	sim.timeline.find(&"f_1").hp = 0
	hero.acted = sim.actions[&"hit"]
	hero.acted_targets = [&"f_1"] as Array[StringName]
	var statuses: Dictionary[StringName, StatusDef] = {}
	var resolver := BattleResolver.new(sim.rules, sim.rng, sim.timeline, statuses)
	var events: Array[TimelineEvent] = resolver.resolve(hero)
	check_eq(BattleProbe.text(events), "fizzled:h:0", "nothing to hit: the act fizzles")
	check_eq(hero.sp, 20, "SP is still capped after a fizzle")
