class_name Prosthetics
extends RefCounted
## Merges a prosthetic into a fighter (docs/design/prosthetics.md), like Djanbeyyah.equip: stat adds, then the
## granted moves, then the caps. Returns a new CombatantDef; the fighter passed in is never touched. A
## prosthetic that does not fit this fighter changes nothing.


static func equip(base: CombatantDef, prosthetic: ProstheticDef) -> CombatantDef:
	var out: CombatantDef = base.clone()
	if prosthetic.wearer != base.id:
		return out
	out.max_hp = maxi(1, base.max_hp + prosthetic.hp)
	out.max_sp = maxi(0, base.max_sp + prosthetic.sp)
	out.attack = maxi(0, base.attack + prosthetic.attack)
	out.defense = maxi(0, base.defense + prosthetic.defense)
	out.agility = base.agility + prosthetic.agility
	out.weight = base.weight + prosthetic.weight
	for action_id: StringName in prosthetic.actions:
		if not out.actions.has(action_id):
			out.actions.append(action_id)
	out.agility = clampi(out.agility, CombatantDef.AGILITY_MIN, CombatantDef.AGILITY_MAX)
	out.cast_speed = clampf(out.cast_speed, CombatantDef.CAST_SPEED_MIN, CombatantDef.CAST_SPEED_MAX)
	out.weight = maxf(0.0, out.weight)
	return out
