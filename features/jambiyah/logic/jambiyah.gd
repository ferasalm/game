class_name Jambiyah
extends RefCounted
## Builds Rydan's fighter from a base CombatantDef plus one hilt and one blade (docs/design/combat.md).
## Merge order: base -> hilt -> blade -> caps. Returns a new CombatantDef; the shared base is never touched.

## The hero who wields the jambiyah (hilt and blade slots exist for this combatant only).
const WIELDER: StringName = &"rydan"


static func equip(base: CombatantDef, hilt: HiltDef, blade: BladeDef) -> CombatantDef:
	var out: CombatantDef = base.clone()
	out.attack = base.attack + blade.attack
	out.agility = base.agility + hilt.agility
	out.cast_speed = base.cast_speed * hilt.cast_speed
	out.knockback_bonus = base.knockback_bonus + blade.knockback
	out.weight = base.weight + hilt.weight + blade.weight
	if not out.actions.has(hilt.ability):
		out.actions.append(hilt.ability)
	out.agility = clampi(out.agility, CombatantDef.AGILITY_MIN, CombatantDef.AGILITY_MAX)
	out.cast_speed = clampf(out.cast_speed, CombatantDef.CAST_SPEED_MIN, CombatantDef.CAST_SPEED_MAX)
	out.weight = maxf(0.0, out.weight)
	return out
