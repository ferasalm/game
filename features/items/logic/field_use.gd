class_name FieldUse
extends RefCounted
## Using a consumable outside battle, pure: the item must be usable in the field, aimed at living allies, and must
## change something (a full hero is refused). One item is taken from the Bag and ItemEffect writes the carried
## vitals. `maxes` is {hero id: Vector2i(max hp, max sp)}.

const NOT_FIELD: StringName = &"not_field"
const NO_EFFECT: StringName = &"no_effect"
const NONE_LEFT: StringName = &"none_left"


## What the item would give this hero now: {"hp", "sp", "revive"} (ItemEffect.gains on the carried vitals).
static func preview(def: ConsumableDef, vitals: Dictionary, hero: StringName, maxes: Dictionary) -> Dictionary:
	var top: Vector2i = maxes.get(hero, Vector2i.ZERO)
	return ItemEffect.gains(def, Vitals.hp_of(vitals, hero, top.x), Vitals.sp_of(vitals, hero, top.y), top.x, top.y)


## True when the item is allowed in the field and would change this hero.
static func can_target(def: ConsumableDef, vitals: Dictionary, hero: StringName, maxes: Dictionary) -> bool:
	return def.use_in != &"battle" and def.target != &"ko_ally" and ItemEffect.changes(preview(def, vitals, hero, maxes))


## True when the item can be used on at least one of these heroes.
static func can_use(def: ConsumableDef, vitals: Dictionary, heroes: Array[StringName], maxes: Dictionary) -> bool:
	for hero: StringName in heroes:
		if can_target(def, vitals, hero, maxes):
			return true
	return false


## Uses one on `targets` (one hero for an ally item, the whole party for all_allies). Returns {"ok": bool,
## "reason": StringName, "gains": {hero id: gains}}; nothing changes unless ok.
static func use(
		def: ConsumableDef, held: Holdings, vitals: Dictionary, targets: Array[StringName], maxes: Dictionary) -> Dictionary:
	var out: Dictionary = {"ok": false, "reason": &"", "gains": {}}
	if def.use_in == &"battle" or def.target == &"ko_ally":
		out["reason"] = NOT_FIELD
	elif held.bag.available(def.id) < 1:
		out["reason"] = NONE_LEFT
	elif not can_use(def, vitals, targets, maxes):
		out["reason"] = NO_EFFECT
	else:
		held.bag.remove(def.id, 1)
		for hero: StringName in targets:
			if can_target(def, vitals, hero, maxes):
				var top: Vector2i = maxes.get(hero, Vector2i.ZERO)
				out["gains"][hero] = ItemEffect.apply(def, vitals, hero, top.x, top.y)
		out["ok"] = true
	return out
