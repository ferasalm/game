extends TestCase
## T4: a cancel move landing on a casting enemy interrupts it (back to INTERRUPT_POS) inside BattleSim.
## Setup: the foe is faster to COMMAND and casts a slow move; the hero's cancel is fast enough to land first.


func _setup(hero_move: ActionDef, foe_props: Dictionary = {}) -> BattleSim:
	var foe_props_full: Dictionary = {"agility": 99, "actions": [&"slow"] as Array[StringName]}
	foe_props_full.merge(foe_props, true)
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h", {"agility": 70, "max_hp": 999,
		"actions": [hero_move.id] as Array[StringName]})]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", foe_props_full)]
	var moves: Array[ActionDef] = [hero_move, BattleProbe.move(&"slow", {"cast_speed": 0.4})]
	return BattleProbe.sim(heroes, [0] as Array[int], foes, [0] as Array[int], moves)


func _picker(move_id: StringName) -> Callable:
	return func(s: BattleSim, hero: UnitState) -> void:
		s.choose(hero.unit_id, s.actions[move_id], &"f_1")


func _hero_acts(sim: BattleSim, move_id: StringName) -> Array[TimelineEvent]:
	return BattleProbe.play_until(sim, &"act", _picker(move_id))


func test_cancel_interrupts_a_casting_enemy() -> void:
	var sim: BattleSim = _setup(BattleProbe.move(&"cut", {"cast_speed": 2.0, "cancels_cast": true}))
	var foe: UnitState = sim.timeline.find(&"f_1")
	var trace: Array[TimelineEvent] = BattleProbe.play_until(sim, &"interrupted", _picker(&"cut"))
	var event: TimelineEvent = BattleProbe.first(trace, &"interrupted")
	check(event != null, "the foe was interrupted")
	check_eq(event.value, Timeline.INTERRUPT_POS, "event carries the new position")
	check_eq(foe.pos, Timeline.INTERRUPT_POS, "back to 2500")
	check_eq(foe.phase, UnitState.Phase.WAIT, "no longer casting")
	check(foe.action == null, "its move is lost")
	check_eq(BattleProbe.count(trace, &"act"), 1, "only the hero acted, the foe's blow never lands")


func test_a_move_without_cancel_only_knocks_back() -> void:
	var sim: BattleSim = _setup(BattleProbe.move(&"poke", {"cast_speed": 2.0, "knockback": 500}))
	var trace: Array[TimelineEvent] = _hero_acts(sim, &"poke")
	var event: TimelineEvent = BattleProbe.first(trace, &"knocked_back")
	check(event != null and BattleProbe.count(trace, &"interrupted") == 0, "knocked back, not interrupted")
	check(event.value >= Timeline.COMMAND_POINT, "a casting target is never knocked below COMMAND")
	check_eq(sim.timeline.find(&"f_1").phase, UnitState.Phase.CAST, "it keeps casting")


func test_only_the_first_hit_cancels_later_hits_knock_back() -> void:
	var sim: BattleSim = _setup(BattleProbe.move(&"flurry", {"cast_speed": 2.0, "cancels_cast": true,
		"hit_count": 2, "knockback": 800}))
	var trace: Array[TimelineEvent] = BattleProbe.play_until(sim, &"act", _picker(&"flurry"))
	var kinds: PackedStringArray = []
	for event: TimelineEvent in trace:
		if event.kind in [&"damage", &"interrupted", &"knocked_back"]:
			kinds.append(event.kind)
	check_eq(",".join(kinds), "damage,interrupted,damage,knocked_back", "cancel on hit 1, knockback on hit 2")
	check_eq(sim.timeline.find(&"f_1").pos, 1700, "2500 - 800 x (1 - 0 resist)")


func test_interrupt_ignores_resist_but_knockback_does_not() -> void:
	var sim: BattleSim = _setup(BattleProbe.move(&"cut", {"cast_speed": 2.0, "cancels_cast": true}),
		{"interrupt_resist": 0.9})
	var trace: Array[TimelineEvent] = BattleProbe.play_until(sim, &"interrupted", _picker(&"cut"))
	check(BattleProbe.first(trace, &"interrupted") != null, "even a 90% resistant foe is interrupted")


func test_blade_knockback_bonus_pushes_a_waiting_target_further() -> void:
	var plain := Timeline.new()
	var bonus := Timeline.new()
	var a: UnitState = UnitState.create(BattleProbe.fighter(&"u"), &"u", 1, 0)
	var b: UnitState = UnitState.create(BattleProbe.fighter(&"u"), &"u", 1, 0)
	a.pos = 6000
	b.pos = 6000
	plain.units = [a]
	bonus.units = [b]
	var by: ActionDef = BattleProbe.move(&"m", {"knockback": 800})
	plain.hit(&"u", by, 0)
	bonus.hit(&"u", by, 1500)
	check_eq(a.pos, 5200, "no bonus")
	check_eq(b.pos, 3700, "knockback_bonus 1500 added to the hit")
