class_name ItemEffect
extends RefCounted
## What a consumable does to one hero: gains() computes the real change from current numbers (never past the
## maximum, a herb never helps a downed hero, a white herb only a downed one); apply() writes it into carried
## vitals. The battle uses gains() on a UnitState's hp/sp, the field uses apply() on GameState.vitals. Pure.


## {"hp": HP really gained, "sp": SP really gained, "revive": true when a downed hero stands up}.
static func gains(def: ConsumableDef, hp: int, sp: int, max_hp: int, max_sp: int) -> Dictionary:
	var out: Dictionary = {"hp": 0, "sp": 0, "revive": false}
	if def.revive:
		if hp <= 0:
			out["hp"] = clampi(maxi(1, roundi(max_hp * def.hp_pct)), 1, max_hp)
			out["revive"] = true
		return out
	if hp <= 0:
		return out  # a living-only herb does nothing for a downed hero
	out["hp"] = clampi(def.hp + roundi(max_hp * def.hp_pct), 0, max_hp - hp)
	out["sp"] = clampi(def.sp, 0, max_sp - sp)
	return out


## True when the gains change anything at all.
static func changes(gain: Dictionary) -> bool:
	return int(gain["hp"]) > 0 or int(gain["sp"]) > 0 or bool(gain["revive"])


## Applies the item to one hero's carried vitals (a missing entry is full) and returns the gains.
static func apply(def: ConsumableDef, vitals: Dictionary, hero: StringName, max_hp: int, max_sp: int) -> Dictionary:
	var hp: int = Vitals.hp_of(vitals, hero, max_hp)
	var sp: int = Vitals.sp_of(vitals, hero, max_sp)
	var gain: Dictionary = gains(def, hp, sp, max_hp, max_sp)
	if changes(gain):
		Vitals.store(vitals, hero, hp + int(gain["hp"]), sp + int(gain["sp"]))
	return gain
