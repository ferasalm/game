class_name Crafting
extends RefCounted
## purpose: Pure rules for crafting recipes (consumables and unique gemstones).

const WS_STONE_OWNED: StringName = &"WS_STONE_OWNED"
const WS_SHORT_MONEY: StringName = &"WS_SHORT_MONEY"
const WS_SHORT_MATERIALS: StringName = &"WS_SHORT_MATERIALS"


## Returns "" if the recipe can be crafted, else a reason key (WS_STONE_OWNED, WS_SHORT_MONEY, WS_SHORT_MATERIALS).
static func problem(
		recipe: RecipeDef, holdings: WorkshopHoldings,
		owned: Array[StringName] = []) -> StringName:
	if recipe == null or holdings == null:
		return &""
	if owned.has(recipe.output) or holdings.owned.has(recipe.output):
		return WS_STONE_OWNED
	if holdings.money < recipe.riyal:
		return WS_SHORT_MONEY
	for mat_id: StringName in recipe.materials:
		var needed: int = recipe.materials[mat_id]
		if int(holdings.materials.get(mat_id, 0)) < needed:
			return WS_SHORT_MATERIALS
	return &""


## Crafts the recipe output, deducting riyal and materials from the holdings copy.
static func apply_craft(
		recipe: RecipeDef, holdings: WorkshopHoldings,
		owned: Array[StringName] = [], is_unique: bool = false, max_stack: int = 99) -> bool:
	if problem(recipe, holdings, owned) != &"":
		return false
	holdings.money -= recipe.riyal
	for mat_id: StringName in recipe.materials:
		var needed: int = recipe.materials[mat_id]
		holdings.materials[mat_id] = int(holdings.materials.get(mat_id, 0)) - needed
	if is_unique:
		if not holdings.owned.has(recipe.output):
			holdings.owned.append(recipe.output)
	else:
		holdings.bag.add(recipe.output, recipe.count, max_stack)
	return true
