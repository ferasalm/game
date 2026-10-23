class_name PerkDef
extends Def
## One perk an item can carry: a kind that battle logic implements and an amount. Kinds: sp_per_act (extra SP
## after each act), hp_regen (HP healed after each act), bonus_knockback (added to every first hit's
## knockback), start_bonus (timeline units gained at the start of a battle).

const KINDS: Array[StringName] = [&"sp_per_act", &"hp_regen", &"bonus_knockback", &"start_bonus",
	&"dodge_bonus", &"crit_bonus", &"status_pierce"]

var name_key: String = ""
var desc_key: String = ""
var kind: StringName = &""
var amount: int = 0


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	desc_key = r.text("desc_key")
	kind = r.one_of("kind", KINDS)
	amount = r.integer("amount", 1, 9999)
