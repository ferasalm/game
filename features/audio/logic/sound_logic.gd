class_name SoundLogic
extends RefCounted
## Pure sound rules: which variant to play, which sound a move uses and the item chime boost for a rarity.


## A variant index in 0..count-1 that differs from last when there is a choice (last -1 = none yet).
static func pick_variant(count: int, last: int, rng: RandomNumberGenerator) -> int:
	if count <= 1:
		return 0
	var index: int = rng.randi_range(0, count - 2)
	return index + 1 if index >= last and last >= 0 else index


## The sound id for a move: its vfx (own field first, else the rules map), else melee/ranged fallback.
static func action_sound(action_id: StringName, vfx: StringName, is_melee: bool, rules: AudioRulesDef) -> StringName:
	var kind: String = String(vfx) if vfx != &"" else rules.action_vfx.get(String(action_id), "")
	if not kind.is_empty():
		return StringName("vfx_" + kind)
	return rules.fallback_melee if is_melee else rules.fallback_ranged


static func rarity_boost(rarity: int, rules: AudioRulesDef) -> float:
	if rules.item_rarity_db.is_empty():
		return 0.0
	return float(rules.item_rarity_db[clampi(rarity, 0, rules.item_rarity_db.size() - 1)])
