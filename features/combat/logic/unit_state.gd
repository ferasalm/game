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
## Turns left per status id; re-applying a status refreshes it.
var status_turns: Dictionary[StringName, int] = {}
## The action and targets of the act that just resolved (Timeline clears action/targets at ACT).
var acted: ActionDef = null
var acted_targets: Array[StringName] = []
## Speed numbers from the battle rules (BattleRulesDef): weight slows a unit by weight x weight_factor.
var weight_factor: float = 0.0
var min_speed_mult: float = 1.0


static func create(
		from_def: CombatantDef, new_id: StringName, on_side: int, in_slot: int,
		rules: BattleRulesDef = null) -> UnitState:
	var unit := UnitState.new()
	var numbers: BattleRulesDef = rules if rules != null else BattleRulesDef.new()
	unit.weight_factor = numbers.speed_weight_factor
	unit.min_speed_mult = numbers.speed_min_mult
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
	return _speed(phase == Phase.CAST, action)


## Timeline units per tick this unit would cast the given action at, with its current statuses.
func cast_speed_for(chosen: ActionDef) -> int:
	return _speed(true, chosen)


func _speed(casting: bool, chosen: ActionDef) -> int:
	var mult: float = maxf(min_speed_mult, 1.0 - def.weight * weight_factor)
	for status: StatusDef in statuses:
		mult *= status.cast_speed if casting else status.wait_speed
	if casting and chosen != null:
		mult *= chosen.cast_speed * def.cast_speed
	return maxi(1, roundi(def.agility * mult))


## Product of the damage_taken multipliers of the unit's statuses (1.0 with none).
func damage_taken_mult() -> float:
	var mult: float = 1.0
	for status: StatusDef in statuses:
		mult *= status.damage_taken
	return mult


func interrupt_immune() -> bool:
	return statuses.any(func(s: StatusDef) -> bool: return s.interrupt_immune)


func apply_status(status: StatusDef) -> void:
	statuses = statuses.filter(func(s: StatusDef) -> bool: return s.id != status.id)
	statuses.append(status)
	status_turns[status.id] = status.turns


## One of this unit's acts has passed: every status loses a turn, except the ids in skip (statuses the unit
## just gave itself). Returns the ids that ran out.
func tick_statuses(skip: Array[StringName] = []) -> Array[StringName]:
	var ended: Array[StringName] = []
	for status: StatusDef in statuses.duplicate():
		if skip.has(status.id):
			continue
		status_turns[status.id] -= 1
		if status_turns[status.id] <= 0:
			statuses.erase(status)
			status_turns.erase(status.id)
			ended.append(status.id)
	return ended
