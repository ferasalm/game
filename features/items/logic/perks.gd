class_name Perks
extends RefCounted
## Applies perks to a fighter. Four kinds (PerkDef.KINDS): bonus_knockback folds into the fighter's knockback
## bonus; the other three become fields that BattleSim reads. Never mutates the fighter it is given.


static func apply(base: CombatantDef, perk_list: Array[PerkDef]) -> CombatantDef:
	var out: CombatantDef = base.clone()
	for perk: PerkDef in perk_list:
		match perk.kind:
			&"sp_per_act":
				out.sp_per_act_bonus += perk.amount
			&"hp_regen":
				out.hp_regen += perk.amount
			&"bonus_knockback":
				out.knockback_bonus += perk.amount
			&"start_bonus":
				out.start_bonus += perk.amount
	return out


## The PerkDefs carried by these items, in order (items without a perk, or an unknown one, add nothing).
static func of_items(items: Array[EquipDef], perks: Dictionary[StringName, PerkDef]) -> Array[PerkDef]:
	var out: Array[PerkDef] = []
	for item: EquipDef in items:
		if item != null and perks.has(item.perk):
			out.append(perks[item.perk])
	return out
