class_name Formation
extends RefCounted
## Two rows per side: slots 0-1 are the vanguard, 2-3 the rearguard, and slot n+2 stands behind slot n.
## A living unit in front covers the one behind it from direct melee and missile attacks.

const MELEE_FRONT_BONUS: float = 0.15
const MELEE_BACK_PENALTY: float = 0.15


static func is_vanguard(slot: int) -> bool:
	return slot < 2


static func is_covered(slot: int, living_slots: Array[int]) -> bool:
	return not is_vanguard(slot) and living_slots.has(slot - 2)


static func melee_multiplier(attacker_slot: int, target_slot: int) -> float:
	var mult: float = 1.0
	mult += MELEE_FRONT_BONUS if is_vanguard(attacker_slot) else -MELEE_BACK_PENALTY
	if not is_vanguard(target_slot):
		mult -= MELEE_BACK_PENALTY
	return clampf(mult, 0.5, 1.5)
