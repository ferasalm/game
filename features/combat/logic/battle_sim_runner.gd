class_name BattleSimRunner
extends RefCounted
## Step loop logic extracted to keep battle_sim.gd under 200 lines.

static func step(sim: BattleSim) -> Array[TimelineEvent]:
	var out: Array[TimelineEvent] = _step(sim)
	if sim.items != null:
		sim.items.sync()
	return out

static func _step(sim: BattleSim) -> Array[TimelineEvent]:
	var out: Array[TimelineEvent] = []
	if not sim.pending_events.is_empty():
		out.append_array(sim.pending_events)
		sim.pending_events.clear()
	if sim.result != &"" or sim.timeline.waiting_for != null:
		return out
	if not sim._opened:
		out.append_array(sim.opening())
		if sim.result != &"":
			return out
	sim.ticks += 1
	for event: TimelineEvent in sim.timeline.tick():
		handle_event(sim, event, out)
		if sim.result != &"":
			return out
	if sim.ticks >= sim.rules.max_ticks:
		sim.result = &"defeat"
		out.append(TimelineEvent.new(&"defeat", &"", sim.ticks))
	return out

static func handle_event(sim: BattleSim, event: TimelineEvent, out: Array[TimelineEvent]) -> void:
	var unit: UnitState = sim.timeline.find(event.unit_id)
	if not unit.is_alive():
		return
	if event.kind == &"command":
		if unit.phase != UnitState.Phase.COMMAND:
			return
		out.append(event)
		if unit.side == 1:
			sim.auto_choose(unit)
			if not sim.pending_events.is_empty():
				out.append_array(sim.pending_events)
				sim.pending_events.clear()
	elif event.kind == &"act" and unit.acted is ItemAction:
		out.append(event)
		out.append_array(sim.items.resolve(unit))
	elif event.kind == &"act":
		out.append(event)
		if unit.acted != null and unit.acted.id == &"flee":
			out.append_array(BattleFleeLogic.resolve_flee(sim, unit))
		else:
			out.append_array(sim._resolver.resolve(unit))
		if BattleTargets.side_is_down(sim.timeline, 1):
			sim.result = &"victory"
			out.append(TimelineEvent.new(&"victory", &"", sim.ticks))
		elif BattleTargets.side_is_down(sim.timeline, 0):
			sim.result = &"defeat"
			out.append(TimelineEvent.new(&"defeat", &"", sim.ticks))
	else:
		out.append(event)
