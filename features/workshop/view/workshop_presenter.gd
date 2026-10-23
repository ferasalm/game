class_name WorkshopPresenter
extends RefCounted
## purpose: Prepares stat comparison defs and status reasons for workshop views.

class StagedState extends RefCounted:
	var xp: Dictionary = {}
	var equipment: Dictionary[StringName, StringName] = {}
	var sockets: Dictionary = {}
	var upgrades: Dictionary[StringName, int] = {}


static func preview_upgrade(item_id: StringName) -> Dictionary:
	var item := ContentDB.get_def("item", item_id) as EquipDef
	var lvl: int = int(GameState.upgrades.get(item_id, 0))
	var costs: UpgradeCostsDef = WorkshopService.costs()
	var rarities: Dictionary = WorkshopService.rarities()
	var cost: Dictionary = Upgrades.next_cost(item, lvl, costs, rarities)
	var prob: StringName = Upgrades.problem(item, lvl, costs, rarities, WorkshopService.holdings())

	var loader := BattleLoader.from_db(ContentDB)
	var now_def: CombatantDef = loader.hero_from_state(&"zayd", GameState)
	var staged := StagedState.new()
	for up_k: StringName in GameState.upgrades:
		staged.upgrades[up_k] = GameState.upgrades[up_k]
	for slot_k: StringName in GameState.equipment:
		staged.equipment[slot_k] = GameState.equipment[slot_k]
	staged.sockets = GameState.sockets
	staged.xp = GameState.xp
	staged.upgrades[item_id] = lvl + 1
	var after_def: CombatantDef = loader.hero_from_state(&"zayd", staged)
	return {"now": now_def, "after": after_def, "cost": cost, "prob": prob, "max": lvl >= costs.max_level}


static func preview_gemstone(stone_id: StringName, slot: int) -> Dictionary:
	var stone := ContentDB.get_def("stone", stone_id) as StoneDef
	var hilt_id: StringName = GameState.equipment.get(&"zayd.hilt", &"grandfather_hilt")
	var hilt := ContentDB.get_def("hilt", hilt_id) as HiltDef
	var fits: bool = (stone != null and hilt != null and Stones.fits(stone, hilt))

	var loader := BattleLoader.from_db(ContentDB)
	var now_def: CombatantDef = loader.hero_from_state(&"zayd", GameState)
	var staged := StagedState.new()
	for up_k: StringName in GameState.upgrades:
		staged.upgrades[up_k] = GameState.upgrades[up_k]
	for slot_k: StringName in GameState.equipment:
		staged.equipment[slot_k] = GameState.equipment[slot_k]
	staged.sockets = GameState.sockets.duplicate(true)
	staged.xp = GameState.xp
	if fits:
		Stones.set_stone(staged.sockets, hilt_id, slot, stone.id)
	var after_def: CombatantDef = loader.hero_from_state(&"zayd", staged)
	return {"now": now_def, "after": after_def, "fits": fits}


static func preview_crafting(recipe_id: StringName) -> Dictionary:
	var recipe := ContentDB.get_def("recipe", recipe_id) as RecipeDef
	var prob: StringName = Crafting.problem(recipe, WorkshopService.holdings(), GameState.inventory)
	return {"recipe": recipe, "prob": prob}
