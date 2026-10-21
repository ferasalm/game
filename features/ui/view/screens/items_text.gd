class_name ItemsText
extends RefCounted
## Item screen wording: the effect line ("HP +120") and a hero's "HP 200 -> 320" preview. Text only; FieldUse decides.


static func preview(def: ConsumableDef, vitals: Dictionary, hero: StringName, maxes: Dictionary) -> String:
	var gain: Dictionary = FieldUse.preview(def, vitals, hero, maxes)
	var top: Vector2i = maxes.get(hero, Vector2i.ZERO)
	var hp: int = Vitals.hp_of(vitals, hero, top.x)
	var sp: int = Vitals.sp_of(vitals, hero, top.y)
	if not FieldUse.can_target(def, vitals, hero, maxes):
		return Ui.text("ITEMS_FULL")
	if int(gain["hp"]) > 0:
		return "%s %s" % [Ui.text("UI_HP"), Ui.text("ITEMS_PREVIEW") % [hp, hp + int(gain["hp"])]]
	return "%s %s" % [Ui.text("UI_SP"), Ui.text("ITEMS_PREVIEW") % [sp, sp + int(gain["sp"])]]


static func effect(def: ConsumableDef) -> String:
	var parts := PackedStringArray()
	if def.revive:
		parts.append(Ui.text("ITEMS_EFFECT_REVIVE"))
	if def.hp > 0:
		parts.append(Ui.text("ITEMS_EFFECT_HP") % def.hp)
	if def.sp > 0:
		parts.append(Ui.text("ITEMS_EFFECT_SP") % def.sp)
	return "  ".join(parts)
