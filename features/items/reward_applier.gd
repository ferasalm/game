class_name RewardApplier
extends RefCounted
## Pays rewards (Rewards) into GameState and announces them: item_obtained per new equippable, item_gained per
## herb stack, money_changed for the riyal. Called by the Router (battles) and the area (chests); holds no rules.


static func victory(encounter_id: StringName) -> RewardResult:
	var encounter := ContentDB.get_def("encounter", encounter_id) as EncounterDef
	if encounter == null:
		return RewardResult.new()
	var held: Holdings = GameState.holdings()
	return _commit(held, Rewards.victory(encounter, held, _rules(), _consumables()))


static func chest(chest_id: StringName) -> RewardResult:
	var def := ContentDB.get_def("chest", chest_id) as ChestDef
	if def == null:
		push_warning("RewardApplier: no chest '%s' in content/items/chests.json" % chest_id)
		return RewardResult.new()
	var held: Holdings = GameState.holdings()
	return _commit(held, Rewards.chest(def, held, _rules(), _consumables()))


## Opens every chest of this place that is still closed (the workshop bench stock).
static func chests_at(place: StringName) -> Array[RewardResult]:
	var out: Array[RewardResult] = []
	var chests: Array[ChestDef] = []
	for chest_id: StringName in ContentDB.ids("chest"):
		chests.append(ContentDB.get_def("chest", chest_id) as ChestDef)
	for def: ChestDef in Chests.at_place(chests, place):
		out.append(chest(def.id))
	return out


static func _commit(held: Holdings, result: RewardResult) -> RewardResult:
	var before: int = GameState.money
	GameState.take(held)
	for item_id: StringName in result.items:
		EventBus.item_obtained.emit(item_id)
	for item_id: StringName in result.consumables:
		EventBus.item_gained.emit(item_id, result.consumables[item_id])
	if GameState.money != before:
		EventBus.money_changed.emit(GameState.money, GameState.money - before)
	return result


static func _rules() -> EconomyRulesDef:
	var rules := ContentDB.get_def("economy_rules", &"default") as EconomyRulesDef
	return rules if rules != null else EconomyRulesDef.new()


static func _consumables() -> Dictionary[StringName, ConsumableDef]:
	var out: Dictionary[StringName, ConsumableDef] = {}
	for item_id: StringName in ContentDB.ids("consumable"):
		out[item_id] = ContentDB.get_def("consumable", item_id) as ConsumableDef
	return out
