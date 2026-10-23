class_name Perks
extends RefCounted
## Applies perks to a fighter. Modifies stats, timeline properties, and passive roll chances.
## Never mutates the fighter it is given.


static func apply(base: CombatantDef, perk_list: Array[PerkDef]) -> CombatantDef:
	var out: CombatantDef = base.clone()
	for perk: PerkDef in perk_list:
		match perk.kind:
			&"sp_per_act":
				out.sp_per_act_bonus += int(perk.amount)
			&"hp_regen":
				out.hp_regen += int(perk.amount)
			&"bonus_knockback":
				out.knockback_bonus += int(perk.amount)
			&"start_bonus":
				out.start_bonus += int(perk.amount)
			&"dodge_bonus":
				out.dodge_bonus += float(perk.amount)
			&"crit_bonus":
				out.crit_bonus += float(perk.amount)
			&"status_pierce":
				out.status_pierce += float(perk.amount)
			&"action_sp_gain", &"counter_ranged", &"interrupt_refund", &"counter_to_command", &"bonus_vs_status":
				# TODO(zayd-kit): Handled in zayd-kit move redesign
				pass
	return out


## The PerkDefs carried by these items, in order (items without a perk, or an unknown one, add nothing).
static func of_items(items: Array[EquipDef], perks: Dictionary[StringName, PerkDef]) -> Array[PerkDef]:
	var out: Array[PerkDef] = []
	for item: EquipDef in items:
		if item != null and perks.has(item.perk):
			out.append(perks[item.perk])
	return out
