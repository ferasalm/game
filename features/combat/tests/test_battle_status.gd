extends TestCase
## T5 (statuses): applied by a move, refreshed on re-apply, one turn lost per act of the afflicted unit,
## and the cast-speed / knockback-bonus numbers of a CombatantDef.


func _jammed() -> StatusDef:
	var status := StatusDef.new()
	status.id = &"jammed"
	status.turns = 2
	status.wait_speed = 0.6
	status.cast_speed = 0.6
	return status


func _unit(props: Dictionary = {}) -> UnitState:
	return UnitState.create(BattleProbe.fighter(&"u", props), &"u", 0, 0)


func test_move_applies_the_status_to_a_living_target() -> void:
	var statuses: Array[StatusDef] = [_jammed()]
	var moves: Array[ActionDef] = [BattleProbe.move(&"net", {"applies_status": &"jammed"})]
	var heroes: Array[CombatantDef] = [BattleProbe.fighter(&"h", {"agility": 99})]
	var foes: Array[CombatantDef] = [BattleProbe.fighter(&"f", {"agility": 1})]
	heroes[0].actions = [&"net"] as Array[StringName]
	var sim: BattleSim = BattleProbe.sim(heroes, [0] as Array[int], foes, [0] as Array[int], moves, {}, statuses)
	var picker := func(s: BattleSim, hero: UnitState) -> void:
		s.choose(hero.unit_id, s.actions[&"net"], &"f_1")
	var trace: Array[TimelineEvent] = BattleProbe.play_until(sim, &"act", picker)
	var event: TimelineEvent = BattleProbe.first(trace, &"status")
	check(event != null and event.unit_id == &"f_1" and event.value == 2 and event.detail == &"jammed", "status event")
	var foe: UnitState = sim.timeline.find(&"f_1")
	check_eq(foe.status_turns[&"jammed"], 2, "2 turns")
	check_eq(foe.speed(), 1, "agility 1 never drops below 1")


func test_status_slows_and_refreshes_and_expires() -> void:
	var unit: UnitState = _unit({"agility": 50})
	check_eq(unit.speed(), 50, "no status")
	unit.apply_status(_jammed())
	check_eq(unit.speed(), 30, "jammed: wait speed x0.6")
	check_eq(unit.tick_statuses(), [] as Array[StringName], "first act: still jammed")
	check_eq(unit.status_turns[&"jammed"], 1, "one turn left")
	unit.apply_status(_jammed())
	check_eq(unit.status_turns[&"jammed"], 2, "re-applying refreshes the turns")
	check_eq(unit.statuses.size(), 1, "and never stacks")
	unit.tick_statuses()
	check_eq(unit.tick_statuses(), [&"jammed"] as Array[StringName], "the second act ends it")
	check_eq(unit.speed(), 50, "back to normal")


func test_status_turns_pass_when_the_afflicted_unit_acts() -> void:
	var sim: BattleSim = BattleProbe.sim(
		[BattleProbe.fighter(&"h")] as Array[CombatantDef], [0] as Array[int],
		[BattleProbe.fighter(&"f")] as Array[CombatantDef], [0] as Array[int], [BattleProbe.move(&"hit")])
	var hero: UnitState = sim.timeline.find(&"h")
	hero.apply_status(_jammed())
	hero.status_turns[&"jammed"] = 1
	hero.acted = sim.actions[&"hit"]
	hero.acted_targets = [&"f_1"] as Array[StringName]
	var statuses: Dictionary[StringName, StatusDef] = {}
	var events: Array[TimelineEvent] = BattleResolver.new(sim.rules, sim.rng, sim.timeline, statuses).resolve(hero)
	var tail: TimelineEvent = events[-1]
	check(tail.kind == &"status_ended" and tail.unit_id == &"h" and tail.detail == &"jammed", "status_ended after the act")
	check(hero.statuses.is_empty(), "the status is gone")


func test_def_cast_speed_applies_only_while_casting() -> void:
	var unit: UnitState = _unit({"agility": 40, "cast_speed": 1.5})
	check_eq(unit.speed(), 40, "waiting: cast_speed does not apply")
	unit.phase = UnitState.Phase.CAST
	unit.action = BattleProbe.move(&"m", {"cast_speed": 1.0})
	check_eq(unit.speed(), 60, "casting: agility 40 x 1.5")
	unit.action = BattleProbe.move(&"m", {"cast_speed": 0.5})
	check_eq(unit.speed(), 30, "multiplies the move's own cast speed")


func test_knockback_bonus_is_added_before_resist() -> void:
	var timeline := Timeline.new()
	var target: UnitState = _unit({"interrupt_resist": 0.2})
	target.pos = 5000
	timeline.units = [target]
	var by: ActionDef = BattleProbe.move(&"m", {"knockback": 1000})
	timeline.hit(&"u", by, 500)
	check_eq(target.pos, 3800, "(1000 + 500) x 0.8 = 1200 back")


func test_hit_before_choosing_returns_the_unit_to_waiting() -> void:
	var timeline := Timeline.new()
	var target: UnitState = _unit()
	timeline.units = [target]
	target.pos = Timeline.COMMAND_POINT
	target.phase = UnitState.Phase.COMMAND
	timeline.waiting_for = target
	timeline.hit(&"u", BattleProbe.move(&"m", {"knockback": 1000}))
	check_eq(target.phase, UnitState.Phase.WAIT, "no longer waiting for a command")
	check(timeline.waiting_for == null, "time runs again")
	check_eq(target.pos, 5999, "knocked back from just under the command point")
