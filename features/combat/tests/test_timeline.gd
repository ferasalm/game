extends TestCase
## Timeline rules: command pause, cast and act, interrupts, knockback limits, determinism.


func _def(agility: int, weight: float = 0.0) -> CombatantDef:
	var def := CombatantDef.new()
	def.id = &"tester"
	def.max_hp = 100
	def.agility = agility
	def.weight = weight
	return def


func _action(cast_speed: float, cancels: bool = false, knockback: int = 0) -> ActionDef:
	var action := ActionDef.new()
	action.id = &"probe"
	action.cast_speed = cast_speed
	action.cancels_cast = cancels
	action.knockback = knockback
	action.recovery = 500
	return action


func _run_until(timeline: Timeline, kind: StringName, max_ticks: int = 5000) -> TimelineEvent:
	for i: int in max_ticks:
		for event: TimelineEvent in timeline.tick():
			if event.kind == kind:
				return event
	return null


func test_weight_slows_speed() -> void:
	check_eq(UnitState.create(_def(20), &"a", 0, 0).speed(), 20, "no weight")
	check_eq(UnitState.create(_def(20, 10.0), &"a", 0, 0).speed(), 17, "weight 10 costs 15%")


func test_command_freezes_time_until_choice() -> void:
	var timeline := Timeline.new()
	timeline.units = [UnitState.create(_def(70), &"a", 0, 0), UnitState.create(_def(10), &"b", 1, 0)]
	var event: TimelineEvent = _run_until(timeline, &"command")
	check_eq(str(event), "command:a:7000", "a reaches the command point first")
	var b_pos: int = timeline.find(&"b").pos
	timeline.tick()
	check_eq(timeline.find(&"b").pos, b_pos, "time is frozen while a chooses")
	check_eq(timeline.choose(&"b", _action(1.0), []), "not waiting for 'b'", "only the waiting unit may choose")
	check_eq(timeline.choose(&"a", _action(1.0), [&"b"]), "", "a chooses")
	check_eq(str(_run_until(timeline, &"act")), "act:a:10000", "a acts after casting")
	check_eq(timeline.find(&"a").pos, Timeline.AFTER_ACT_POS - 500, "recovery sets a back")


func test_cancel_interrupts_a_cast() -> void:
	var timeline := Timeline.new()
	timeline.units = [UnitState.create(_def(70), &"a", 0, 0)]
	_run_until(timeline, &"command")
	timeline.choose(&"a", _action(0.5), [])
	timeline.tick()
	var event: TimelineEvent = timeline.hit(&"a", _action(1.0, true))
	check_eq(str(event), "interrupted:a:%d" % Timeline.INTERRUPT_POS, "a cancel hit interrupts")
	check_eq(timeline.find(&"a").phase, UnitState.Phase.WAIT, "back to waiting")


func test_knockback_never_crosses_command_point_while_casting() -> void:
	var timeline := Timeline.new()
	timeline.units = [UnitState.create(_def(70), &"a", 0, 0)]
	_run_until(timeline, &"command")
	timeline.choose(&"a", _action(1.0), [])
	timeline.tick()
	check_eq(timeline.hit(&"a", _action(1.0, false, 5000)).value, Timeline.COMMAND_POINT, "clamped at command point")


func test_same_battle_same_events() -> void:
	check_eq(_scripted_battle_log(), _scripted_battle_log(), "two identical battles give identical logs")


func _scripted_battle_log() -> String:
	var timeline := Timeline.new()
	timeline.units = [UnitState.create(_def(25, 5.0), &"a", 0, 0), UnitState.create(_def(18, 8.0), &"b", 1, 0)]
	var lines: PackedStringArray = []
	for i: int in 3000:
		for event: TimelineEvent in timeline.tick():
			lines.append("%d %s" % [i, event])
			if event.kind == &"command":
				timeline.choose(event.unit_id, _action(1.2, event.unit_id == &"a", 1200), [])
	return ",".join(lines)
