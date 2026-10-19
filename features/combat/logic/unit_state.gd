class_name UnitState
extends RefCounted
## One fighter during one battle: the numbers that change (hp, timeline position, the action being cast),
## built from a read-only CombatantDef. Pure data plus small rules; no nodes.

enum Phase { WAIT, COMMAND, CAST }

var unit_id: StringName
var def: CombatantDef
var side: int = 0
var slot: int = 0
var hp: int = 0
var sp: int = 0
var pos: int = 0
var phase: Phase = Phase.WAIT
var action: ActionDef = null
var targets: Array[StringName] = []
var statuses: Array[StatusDef] = []


static func create(from_def: CombatantDef, new_id: StringName, on_side: int, in_slot: int) -> UnitState:
	var unit := UnitState.new()
	unit.unit_id = new_id
	unit.def = from_def
	unit.side = on_side
	unit.slot = in_slot
	unit.hp = from_def.max_hp
	unit.sp = from_def.max_sp
	return unit


func is_alive() -> bool:
	return hp > 0


## Timeline units gained per tick: agility, slowed by equipment weight and statuses; while casting,
## the chosen action's cast speed applies too.
func speed() -> int:
	var mult: float = maxf(0.5, 1.0 - def.weight * 0.015)
	for status: StatusDef in statuses:
		mult *= status.cast_speed if phase == Phase.CAST else status.wait_speed
	if phase == Phase.CAST and action != null:
		mult *= action.cast_speed
	return maxi(1, roundi(def.agility * mult))


func interrupt_immune() -> bool:
	return statuses.any(func(s: StatusDef) -> bool: return s.interrupt_immune)
