class_name WorkshopStats
extends RefCounted
## The comparison rows the equipment screen shows: base fighter against the fighter built by Jambiyah.equip. Pure.


static func rows(base: CombatantDef, merged: CombatantDef) -> Array[StatRow]:
	var out: Array[StatRow] = []
	out.append(StatRow.new("WORKSHOP_STAT_HP", StatRow.INT, base.max_hp, merged.max_hp))
	out.append(StatRow.new("WORKSHOP_STAT_SP", StatRow.INT, base.max_sp, merged.max_sp))
	out.append(StatRow.new("WORKSHOP_STAT_DAMAGE", StatRow.INT, base.attack, merged.attack))
	out.append(StatRow.new("WORKSHOP_STAT_DEFENSE", StatRow.INT, base.defense, merged.defense))
	out.append(StatRow.new("WORKSHOP_STAT_TURN", StatRow.INT, base.agility, merged.agility))
	out.append(StatRow.new("WORKSHOP_STAT_CHARGE", StatRow.PERCENT, base.cast_speed * 100.0, merged.cast_speed * 100.0))
	out.append(StatRow.new("WORKSHOP_STAT_STAGGER", StatRow.INT, base.knockback_bonus, merged.knockback_bonus))
	out.append(StatRow.new("WORKSHOP_STAT_WEIGHT", StatRow.DECIMAL, base.weight, merged.weight, true))
	return out
