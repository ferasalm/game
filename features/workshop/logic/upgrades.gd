class_name Upgrades
extends RefCounted
## purpose: Pure rules and cost calculations for equipment upgrades (+1 to +3).

const WS_MAX: StringName = &"WS_MAX"
const WS_SHORT_MONEY: StringName = &"WS_SHORT_MONEY"
const WS_SHORT_MATERIALS: StringName = &"WS_SHORT_MATERIALS"


## Computes the {riyal, materials} cost for the next upgrade level, or {} if at or above max level.
static func next_cost(
		item: EquipDef, level: int, costs: UpgradeCostsDef,
		_rarities: Dictionary = {}) -> Dictionary:
	if item == null or costs == null or level < 0 or level >= costs.max_level:
		return {}
	if level >= costs.riyal.size() or level >= costs.materials.size():
		return {}
	var factor: float = costs.rarity_factor.get(item.rarity, 1.0)
	var riyal: int = roundi(float(costs.riyal[level]) * factor)
	var mats: Dictionary = (costs.materials[level] as Dictionary).duplicate()
	return {"riyal": riyal, "materials": mats}


## Returns "" if the upgrade can be purchased, else a reason key (WS_MAX, WS_SHORT_MONEY, WS_SHORT_MATERIALS).
static func problem(
		item: EquipDef, level: int, costs: UpgradeCostsDef,
		rarities: Dictionary, holdings: WorkshopHoldings) -> StringName:
	if item == null or costs == null or level >= costs.max_level:
		return WS_MAX
	var cost: Dictionary = next_cost(item, level, costs, rarities)
	if cost.is_empty():
		return WS_MAX
	if holdings.money < int(cost.get("riyal", 0)):
		return WS_SHORT_MONEY
	var mats: Dictionary = cost.get("materials", {})
	for mat_id: Variant in mats:
		var m_id := mat_id as StringName
		var needed: int = int(mats[mat_id])
		if int(holdings.materials.get(m_id, 0)) < needed:
			return WS_SHORT_MATERIALS
	return &""


## Purchases an upgrade on the given holdings working copy. Returns true on success.
static func apply_upgrade(
		item: EquipDef, costs: UpgradeCostsDef, rarities: Dictionary,
		holdings: WorkshopHoldings) -> bool:
	if item == null or holdings == null:
		return false
	var level: int = int(holdings.upgrades.get(item.id, 0))
	if problem(item, level, costs, rarities, holdings) != &"":
		return false
	var cost: Dictionary = next_cost(item, level, costs, rarities)
	holdings.money -= int(cost.get("riyal", 0))
	var mats: Dictionary = cost.get("materials", {})
	for mat_id: Variant in mats:
		var m_id := mat_id as StringName
		var needed: int = int(mats[mat_id])
		holdings.materials[m_id] = int(holdings.materials.get(m_id, 0)) - needed
	holdings.upgrades[item.id] = level + 1
	return true
