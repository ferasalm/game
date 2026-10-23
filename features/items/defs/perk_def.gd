class_name PerkDef
extends Def
## One perk an item can carry: a kind that battle logic implements and an amount.
## Kinds include stat bonuses, timeline bonuses, roll modifiers, and stone/passive effects.

const KINDS: Array[StringName] = [
	&"sp_per_act", &"hp_regen", &"bonus_knockback", &"start_bonus",
	&"dodge_bonus", &"crit_bonus", &"status_pierce",
	&"action_sp_gain", &"counter_ranged", &"interrupt_refund",
	&"counter_to_command", &"bonus_vs_status"
]

var name_key: String = ""
var desc_key: String = ""
var kind: StringName = &""
var amount: float = 0.0
var action: StringName = &""
var status: StringName = &""


func read(r: DefReader) -> void:
	id = r.id()
	name_key = r.text("name_key")
	desc_key = r.text("desc_key")
	kind = r.one_of("kind", KINDS)
	amount = r.number("amount", 0.0, 9999.0, 1.0, false)
	action = StringName(r.text("action", "", false))
	status = StringName(r.text("status", "", false))


func references() -> Array[Array]:
	var out: Array[Array] = []
	if action != &"":
		out.append(["action", action])
	if status != &"":
		out.append(["status", status])
	return out
