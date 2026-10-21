class_name Rewards
extends RefCounted
## Rewards for a won battle or an opened chest, paid straight into a Holdings. Pure.
## Victory: the first win of a patrol pays everything (riyal, equippables, herbs) and sets patrol_paid_<id>;
## later wins pay only repeat_payout of the riyal. Chest: once, remembered by chest_opened_<id>.
## Herbs over the stack limit become riyal at their sell price; riyal never goes over the cap.


static func paid_flag(encounter_id: StringName) -> StringName:
	return StringName("patrol_paid_" + String(encounter_id))


static func victory(
		encounter: EncounterDef, held: Holdings, rules: EconomyRulesDef,
		consumables: Dictionary[StringName, ConsumableDef]) -> RewardResult:
	var result := RewardResult.new()
	var flag: StringName = paid_flag(encounter.id)
	if held.flags.get(flag, false):
		_pay(held, result, roundi(encounter.money * rules.repeat_payout), rules)
		return result
	held.flags[flag] = true
	_pay(held, result, encounter.money, rules)
	result.items = Inventory.add_all(held.inventory, encounter.loot)
	_stock(held, result, encounter.consumables, rules, consumables)
	return result


static func chest(
		chest_def: ChestDef, held: Holdings, rules: EconomyRulesDef,
		consumables: Dictionary[StringName, ConsumableDef]) -> RewardResult:
	var result := RewardResult.new()
	if Chests.is_open(chest_def, held.flags):
		result.already_done = true
		return result
	held.flags[Chests.flag(chest_def.id)] = true
	_pay(held, result, chest_def.money, rules)
	if Inventory.add(held.inventory, chest_def.item):
		result.items.append(chest_def.item)
	_stock(held, result, chest_def.consumables, rules, consumables)
	return result


static func _stock(
		held: Holdings, result: RewardResult, wanted: Dictionary[StringName, int], rules: EconomyRulesDef,
		consumables: Dictionary[StringName, ConsumableDef]) -> void:
	for item_id: StringName in wanted:
		var def: ConsumableDef = consumables.get(item_id)
		if def == null:
			continue
		var left: int = held.bag.add(item_id, wanted[item_id], def.max_stack)
		if wanted[item_id] - left > 0:
			result.consumables[item_id] = wanted[item_id] - left
		if left > 0:
			result.overflow_money += left * def.sell
			_pay(held, result, left * def.sell, rules)


static func _pay(held: Holdings, result: RewardResult, amount: int, rules: EconomyRulesDef) -> void:
	var paid: int = clampi(amount, 0, maxi(0, rules.money_cap - held.money))
	held.money += paid
	result.money += paid
	result.money_lost += amount - paid
