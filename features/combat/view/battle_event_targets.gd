class_name BattleEventTargets
extends RefCounted
## Finds unit targets touched by a move from the timeline events that follow it (hits, heals, misses).

const MOVE_KINDS: Array[StringName] = [&"act", &"reverse_stab", &"command"]
const TARGET_KINDS: Array[StringName] = [&"damage", &"healed", &"status", &"revived", &"sp_restored"]


## Who the move after events[i] touches: targets from subsequent hit/heal/status/miss events (until next move).
static func targets_after(sim: BattleSim, events: Array[TimelineEvent], i: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for j: int in range(i + 1, events.size()):
		var next: TimelineEvent = events[j]
		if MOVE_KINDS.has(next.kind):
			break
		if next.kind == &"missed":
			var actor: UnitState = sim.timeline.find(next.unit_id) if sim != null and sim.timeline != null else null
			if actor != null:
				return actor.acted_targets.duplicate()
		if TARGET_KINDS.has(next.kind) and next.detail != &"regen" and not out.has(next.unit_id):
			out.append(next.unit_id)
	return out
