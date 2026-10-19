class_name Timeline
extends RefCounted
## Grandia-style initiative track (docs/ARCHITECTURE.md, "Combat"). Pure and deterministic: positions are
## integers, time moves in fixed ticks, units move in list order, and every change comes back as an event.
## A unit reaching COMMAND_POINT freezes time until choose() is called for it (by the player or the AI).

const TICKS_PER_SECOND: int = 60
const COMMAND_POINT: int = 7000
const ACT_POINT: int = 10000
const INTERRUPT_POS: int = 2500
const AFTER_ACT_POS: int = 2000

var units: Array[UnitState] = []
var waiting_for: UnitState = null


## Advances one tick unless a command is pending. Returns what happened, in order.
func tick() -> Array[TimelineEvent]:
	var events: Array[TimelineEvent] = []
	if waiting_for != null:
		return events
	for unit: UnitState in units:
		if unit.is_alive():
			_advance(unit, events)
		if waiting_for != null:
			break
	return events


## Commits the waiting unit to an action. Returns "" or why the choice was refused.
func choose(unit_id: StringName, chosen: ActionDef, target_ids: Array[StringName]) -> String:
	if waiting_for == null or waiting_for.unit_id != unit_id:
		return "not waiting for '%s'" % unit_id
	waiting_for.action = chosen
	waiting_for.targets = target_ids
	waiting_for.phase = UnitState.Phase.CAST
	waiting_for = null
	return ""


## Applies a landed hit's timeline effect: a cancel during a cast interrupts it; anything else knocks the
## target back, never below COMMAND_POINT while it casts.
func hit(target_id: StringName, by: ActionDef) -> TimelineEvent:
	var target: UnitState = find(target_id)
	if target.phase == UnitState.Phase.CAST and by.cancels_cast and not target.interrupt_immune():
		target.phase = UnitState.Phase.WAIT
		target.action = null
		target.targets.clear()
		target.pos = INTERRUPT_POS
		return TimelineEvent.new(&"interrupted", target_id, target.pos)
	var shift: int = roundi(by.knockback * (1.0 - target.def.interrupt_resist))
	var lowest: int = COMMAND_POINT if target.phase == UnitState.Phase.CAST else 0
	target.pos = maxi(lowest, target.pos - shift)
	return TimelineEvent.new(&"knocked_back", target_id, target.pos)


func find(unit_id: StringName) -> UnitState:
	for unit: UnitState in units:
		if unit.unit_id == unit_id:
			return unit
	return null


func _advance(unit: UnitState, events: Array[TimelineEvent]) -> void:
	if unit.phase == UnitState.Phase.WAIT:
		unit.pos = mini(COMMAND_POINT, unit.pos + unit.speed())
		if unit.pos == COMMAND_POINT:
			unit.phase = UnitState.Phase.COMMAND
			waiting_for = unit
			events.append(TimelineEvent.new(&"command", unit.unit_id, unit.pos))
	elif unit.phase == UnitState.Phase.CAST:
		unit.pos = mini(ACT_POINT, unit.pos + unit.speed())
		if unit.pos == ACT_POINT:
			events.append(TimelineEvent.new(&"act", unit.unit_id, unit.pos))
			unit.pos = maxi(0, AFTER_ACT_POS - unit.action.recovery)
			unit.phase = UnitState.Phase.WAIT
			unit.action = null
			unit.targets.clear()
