class_name ItemsText
extends RefCounted
## Item screen wording: the effect line ("HP +120"), a card's gain line and the statuses an item cures. Text only;
## FieldUse decides the numbers.


static func effect(def: ConsumableDef) -> String:
	var parts := PackedStringArray()
	if def.revive:
		parts.append(Ui.text("ITEMS_EFFECT_REVIVE"))
	if def.hp > 0:
		parts.append(Ui.text("ITEMS_EFFECT_HP") % def.hp)
	if def.sp > 0:
		parts.append(Ui.text("ITEMS_EFFECT_SP") % def.sp)
	var cures_text: String = cures(def)
	if not cures_text.is_empty():
		parts.append(cures_text)
	return "  ".join(parts)


## A short list tag: the HP/SP/revive effect only (cures stay in the description).
static func tag(def: ConsumableDef) -> String:
	var parts := PackedStringArray()
	if def.revive:
		parts.append(Ui.text("ITEMS_EFFECT_REVIVE"))
	if def.hp > 0:
		parts.append(Ui.text("ITEMS_EFFECT_HP") % def.hp)
	if def.sp > 0:
		parts.append(Ui.text("ITEMS_EFFECT_SP") % def.sp)
	return "  ".join(parts)


## The real change on one hero as a card line: "+120 HP", "+12 SP", "Revives".
static func gain(gain_data: Dictionary) -> String:
	var parts := PackedStringArray()
	if bool(gain_data.get("revive", false)):
		parts.append(Ui.text("ITEMS_EFFECT_REVIVE"))
	if int(gain_data.get("hp", 0)) > 0:
		parts.append(Ui.text("ITEMS_GAIN_HP") % int(gain_data["hp"]))
	if int(gain_data.get("sp", 0)) > 0:
		parts.append(Ui.text("ITEMS_GAIN_SP") % int(gain_data["sp"]))
	return "  ".join(parts)


## "Cures Confused" for the statuses an item removes, or "" when it cures none.
static func cures(def: ConsumableDef) -> String:
	if def.cures.is_empty():
		return ""
	var names := PackedStringArray()
	for status_id: StringName in def.cures:
		var status := ContentDB.get_def("status", status_id) as StatusDef
		names.append(Ui.text(status.name_key) if status != null else String(status_id))
	return Ui.text("ITEMS_CURES") % ", ".join(names)


## A stat change line with an up arrow: "HP 450 -> 510 (+60) ▲".
static func comparison(stat_tag: String, now_val: int, next_val: int, diff: int) -> String:
	return "%s %d -> %d (+%d) ▲" % [stat_tag, now_val, next_val, diff]
