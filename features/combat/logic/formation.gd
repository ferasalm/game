class_name Formation
extends RefCounted
## Two rows per side: slots 0-1 are the vanguard, 2-3 the rearguard, and slot n+2 stands behind slot n.
## A living unit in front covers the one behind it from direct melee and missile attacks.


static func is_vanguard(slot: int) -> bool:
	return slot < 2


static func is_covered(slot: int, living_slots: Array[int]) -> bool:
	return not is_vanguard(slot) and living_slots.has(slot - 2)


## Melee damage factor for the rows of attacker and target; the numbers come from the battle rules.
static func melee_multiplier(attacker_slot: int, target_slot: int, rules: BattleRulesDef) -> float:
	var mult: float = 1.0
	mult += rules.melee_front_bonus if is_vanguard(attacker_slot) else -rules.melee_back_penalty
	if not is_vanguard(target_slot):
		mult -= rules.melee_back_penalty
	return clampf(mult, rules.melee_min, rules.melee_max)
