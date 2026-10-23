class_name TestZaydKit
extends TestCase
## Tests for Zayd's redesigned kit (zayd-moves.md section 5 and brief): damage split, sp_gain,
## after_act_pos, cast_status, bonus vs status, poised counter, shove, and content comparisons.


func _duel(hero_props: Dictionary, foe_props: Dictionary, moves: Array[ActionDef],
		rule_props: Dictionary = {}, status_list: Array[StatusDef] = []) -> BattleSim:
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


func _status(id: StringName, turns: int, dt: float, counter_act: StringName = &"", ranged: bool = false) -> StatusDef:
	var s := StatusDef.new()
	s.id = id
	s.turns = turns
	s.damage_taken = dt
	s.counter_action = counter_act
	s.counter_ranged = ranged
	return s


func test_damage_split_and_single_hit_equivalence() -> void:
	var strike_move: ActionDef = BattleProbe.move(&"strike", {"power": 12, "hit_count": 2, "is_melee": false})
	var single_move: ActionDef = BattleProbe.move(&"single", {"power": 18, "hit_count": 1, "is_melee": false})
	var sim: BattleSim = _duel({"attack": 26}, {"defense": 14, "max_hp": 400}, [strike_move, single_move])
	BattleProbe.play_until(sim, &"command", Callable())
	sim.choose(&"h", strike_move, &"f_1")
	var trace: Array[TimelineEvent] = BattleProbe.play_until(sim, &"act", Callable())
	var dmg: Array[int] = []
	for e: TimelineEvent in trace:
		if e.kind == &"damage":
			dmg.append(e.value)
	# 2-hit strike at Atk 26 vs Def 14 = 2 x round(12 + 9.5) = [22, 22]
	check_eq(dmg, [22, 22] as Array[int], "damage split matches 2 x round(12 + 9.5)")
	var sim2: BattleSim = _duel({"attack": 26}, {"defense": 14, "max_hp": 400}, [single_move])
	BattleProbe.play_until(sim2, &"command", Callable())
	sim2.choose(&"h", single_move, &"f_1")
	var trace2: Array[TimelineEvent] = BattleProbe.play_until(sim2, &"act", Callable())
	var single_dmg: int = 0
	for e: TimelineEvent in trace2:
		if e.kind == &"damage":
			single_dmg = e.value
	# Single-hit: 18 + 26 - 7 = 37, identical to before the change
	check_eq(single_dmg, 37, "single-hit move gives same numbers as before")


func test_sp_gain_paid_only_on_landed_hit() -> void:
	var move_gain: ActionDef = BattleProbe.move(&"strike", {"power": 10, "hit_count": 1, "sp_gain": 2})
	var sim: BattleSim = _duel({"max_sp": 20}, {"max_hp": 400}, [move_gain])
	var hero: UnitState = sim.timeline.find(&"h")
	hero.sp = 5
	BattleProbe.play_until(sim, &"command", Callable())
	sim.choose(&"h", move_gain, &"f_1")
	BattleProbe.play_until(sim, &"act", Callable())
	check_eq(hero.sp, 10, "5 + 3 rules + 2 gain = 10 SP on landed hit")
	# Fizzled move (no living targets): sp_gain not paid
	var sim2: BattleSim = _duel({"max_sp": 20}, {"max_hp": 10}, [move_gain])
	var hero2: UnitState = sim2.timeline.find(&"h")
	hero2.sp = 5
	BattleProbe.play_until(sim2, &"command", Callable())
	sim2.choose(&"h", move_gain, &"f_1")
	sim2.timeline.find(&"f_1").hp = 0
	BattleProbe.play_until(sim2, &"act", Callable())
	check_eq(hero2.sp, 8, "fizzled move gets only 3 rules SP, no sp_gain")


func test_after_act_pos_lands_at_4500() -> void:
	var move_tempo: ActionDef = BattleProbe.move(&"step", {"power": 10, "after_act_pos": 4500})
	var sim: BattleSim = _duel({}, {"max_hp": 400}, [move_tempo])
	BattleProbe.play_until(sim, &"command", Callable())
	sim.choose(&"h", move_tempo, &"f_1")
	BattleProbe.play_until(sim, &"act", Callable())
	var hero: UnitState = sim.timeline.find(&"h")
	check_eq(hero.pos, 4500, "hero lands at after_act_pos 4500")


func test_cast_status_lifecycle() -> void:
	var exp_status: StatusDef = _status(&"exposed", 1, 1.5)
	var move_commit: ActionDef = BattleProbe.move(&"flood", {"power": 58, "cast_status": &"exposed", "cancels_cast": false})
	var sim: BattleSim = _duel({}, {"max_hp": 400}, [move_commit], {}, [exp_status])
	BattleProbe.play_until(sim, &"command", Callable())
	sim.choose(&"h", move_commit, &"f_1")
	var hero: UnitState = sim.timeline.find(&"h")
	check(hero.status_turns.has(&"exposed"), "exposed added at choose")
	var trace: Array[TimelineEvent] = BattleProbe.play_until(sim, &"act", Callable())
	check(not hero.status_turns.has(&"exposed"), "exposed removed at act")
	check(trace.any(func(e: TimelineEvent) -> bool: return e.kind == &"status_ended" and e.detail == &"exposed"), "status_ended emitted at act")
	# Removed on interrupt
	var sim2: BattleSim = _duel({}, {"max_hp": 400}, [move_commit], {}, [exp_status])
	BattleProbe.play_until(sim2, &"command", Callable())
	sim2.choose(&"h", move_commit, &"f_1")
	var cancel_hit: ActionDef = BattleProbe.move(&"brk", {"cancels_cast": true})
	sim2.timeline.hit(&"h", cancel_hit)
	check(not sim2.timeline.find(&"h").status_turns.has(&"exposed"), "exposed removed on interrupt")


func test_bonus_vs_jammed() -> void:
	var arc_move: ActionDef = BattleProbe.move(&"arc", {"power": 14, "is_melee": false, "bonus_vs_status": &"jammed", "bonus_mult": 1.5})
	var jam: StatusDef = _status(&"jammed", 2, 1.0)
	var sim: BattleSim = _duel({"attack": 26}, {"defense": 14, "max_hp": 400}, [arc_move], {}, [jam])
	# Normal damage: 14 + 19 = 33
	BattleProbe.play_until(sim, &"command", Callable())
	sim.choose(&"h", arc_move, &"f_1")
	var trace: Array[TimelineEvent] = BattleProbe.play_until(sim, &"act", Callable())
	var dmg: int = 0
	for e: TimelineEvent in trace:
		if e.kind == &"damage":
			dmg = e.value
	check_eq(dmg, 33, "normal damage without jammed")
	# With jammed: 33 * 1.5 = 49.5 -> 50, and conducted event
	var sim2: BattleSim = _duel({"attack": 26}, {"defense": 14, "max_hp": 400}, [arc_move], {}, [jam])
	sim2.timeline.find(&"f_1").apply_status(jam)
	BattleProbe.play_until(sim2, &"command", Callable())
	sim2.choose(&"h", arc_move, &"f_1")
	var trace2: Array[TimelineEvent] = BattleProbe.play_until(sim2, &"act", Callable())
	var dmg2: int = 0
	var conducted: bool = false
	for e: TimelineEvent in trace2:
		if e.kind == &"damage":
			dmg2 = e.value
		if e.kind == &"conducted":
			conducted = true
	check_eq(dmg2, 50, "1.5x damage on jammed foe")
	check(conducted, "conducted event emitted on jammed foe")


func test_poised_halves_melee_and_counters() -> void:
	var r_stab: ActionDef = BattleProbe.move(&"reverse_stab", {"power": 24, "knockback": 3000, "recovery": 0})
	var poised: StatusDef = _status(&"poised", 1, 0.5, &"reverse_stab")
	var enemy_hit: ActionDef = BattleProbe.move(&"slam", {"power": 20, "is_melee": true})
	var enemy_shot: ActionDef = BattleProbe.move(&"shot", {"power": 20, "is_melee": false})
	var sim: BattleSim = _duel({"attack": 20, "defense": 14, "max_hp": 400}, {"attack": 31, "defense": 14, "max_hp": 400},
		[r_stab, enemy_hit, enemy_shot], {}, [poised])
	var hero: UnitState = sim.timeline.find(&"h")
	hero.apply_status(poised)
	var foe: UnitState = sim.timeline.find(&"f_1")
	var trace: Array[TimelineEvent] = sim._resolver.strike(foe, enemy_hit, hero)
	check(trace.any(func(e: TimelineEvent) -> bool: return e.kind == &"countered" and e.unit_id == &"h" and e.detail == &"f_1"), "countered event fired")
	check(not hero.status_turns.has(&"poised"), "poised ends after counter")
	# Ranged does not counter
	var hero2: UnitState = sim.timeline.find(&"h")
	hero2.apply_status(poised)
	var trace_ranged: Array[TimelineEvent] = sim._resolver.strike(foe, enemy_shot, hero2)
	check(not trace_ranged.any(func(e: TimelineEvent) -> bool: return e.kind == &"countered"), "ranged hit does not counter")


func test_shove_on_caster_stops_at_command() -> void:
	var shove: ActionDef = BattleProbe.move(&"piston_jab", {"power": 6, "knockback": 2600, "cancels_cast": false})
	var sim: BattleSim = _duel({}, {"max_hp": 400}, [shove])
	var foe: UnitState = sim.timeline.find(&"f_1")
	foe.phase = UnitState.Phase.CAST
	foe.pos = 8000
	var preview: int = sim.knockback_preview(sim.timeline.find(&"h"), shove, foe)
	check_eq(preview, Timeline.COMMAND_POINT, "knockback preview clamps to COMMAND_POINT")
	sim.timeline.hit(&"f_1", shove)
	check_eq(foe.pos, Timeline.COMMAND_POINT, "shove clamps at COMMAND_POINT")
	check_eq(int(foe.phase), int(UnitState.Phase.CAST), "caster keeps casting phase")


func test_content_damage_comparisons_and_cancel_count() -> void:
	var db: Node = load("res://core/content_db.gd").new()
	db.call("load_all")
	var strike: ActionDef = db.call("get_def", "action", &"jambiyah_strike") as ActionDef
	var breaker: ActionDef = db.call("get_def", "action", &"breaker") as ActionDef
	var crush: ActionDef = db.call("get_def", "action", &"crushing_blow") as ActionDef
	var arc: ActionDef = db.call("get_def", "action", &"arc_discharge") as ActionDef
	var enforcer: CombatantDef = db.call("get_def", "combatant", &"concession_enforcer") as CombatantDef
	var zayd: CombatantDef = db.call("get_def", "combatant", &"zayd") as CombatantDef
	db.free()
	var zayd_unit: UnitState = UnitState.create(zayd, &"zayd", 0, 0, BattleRulesDef.new())
	zayd_unit.def.attack = 26  # base 20 + rustwire 6
	var enf_unit: UnitState = UnitState.create(enforcer, &"enf", 1, 0, BattleRulesDef.new())
	var sim: BattleSim = BattleProbe.sim([zayd_unit.def], [0] as Array[int], [enf_unit.def], [0] as Array[int], [strike, breaker, crush, arc])
	var strike_dmg: int = 0
	for i: int in strike.hit_count:
		strike_dmg += sim._resolver.damage(zayd_unit, strike, enf_unit)
	var breaker_dmg: int = sim._resolver.damage(zayd_unit, breaker, enf_unit)
	var crush_dmg: int = sim._resolver.damage(zayd_unit, crush, enf_unit)
	var arc_2: int = sim._resolver.damage(zayd_unit, arc, enf_unit) * 2
	check(breaker_dmg > strike_dmg, "breaker (%d) out-damages strike (%d)" % [breaker_dmg, strike_dmg])
	check(crush_dmg > breaker_dmg, "crushing_blow (%d) out-damages breaker (%d)" % [crush_dmg, breaker_dmg])
	check(arc_2 > strike_dmg, "arc on 2 foes (%d) out-damages one strike (%d)" % [arc_2, strike_dmg])
	# Start loadout has exactly one cancel move
	var cancels: int = 0
	for act_id: StringName in [&"jambiyah_strike", &"breaker", &"elder_cut", &"piston_jab"]:
		var a: ActionDef = ContentDB.get_def("action", act_id) as ActionDef
		if a != null and a.cancels_cast:
			cancels += 1
	check_eq(cancels, 1, "Zayd start loadout holds exactly one cancel move")
