class_name ItemAction
extends ActionDef
## A consumable as a battle cast: an ActionDef built from a ConsumableDef, so the timeline treats it like any move
## (cast speed, recovery, the cast bar, interrupts). item_id says which herb it uses; the effect is BattleItems'.
## Pure; never read from JSON.

var item_id: StringName = &""


static func from_consumable(def: ConsumableDef) -> ItemAction:
	var action := ItemAction.new()
	action.id = StringName("item_%s" % def.id)
	action.item_id = def.id
	action.name_key = def.name_key
	action.desc_key = def.desc_key
	action.cast_speed = def.cast_speed
	action.recovery = def.recovery
	action.is_melee = false
	action.vfx = def.vfx
	action.revive = def.revive
	action.cures = def.cures.duplicate()
	action.target = &"all_allies" if def.target == &"all_allies" else &"ally"
	return action
