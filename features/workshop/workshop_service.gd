class_name WorkshopService
extends RefCounted
## purpose: Executes workshop operations against GameState and emits toasts and bus events.


## Creates an isolated working copy of GameState for workshop operations.
static func holdings() -> WorkshopHoldings:
	var h := WorkshopHoldings.new()
	h.money = GameState.money
	h.materials = GameState.materials.duplicate()
	h.owned = GameState.inventory.duplicate()
	h.upgrades = GameState.upgrades.duplicate()
	h.sockets = GameState.sockets.duplicate(true)
	h.bag = Bag.from_counts(GameState.bag)
	return h


## Writes a modified working copy back to GameState and notifies listeners.
static func commit(h: WorkshopHoldings) -> void:
	if h == null:
		return
	var money_delta: int = h.money - GameState.money
	GameState.money = h.money
	GameState.materials = h.materials.duplicate()
	GameState.inventory = h.owned.duplicate()
	GameState.upgrades = h.upgrades.duplicate()
	GameState.sockets = h.sockets.duplicate(true)
	GameState.set_bag(h.bag.snapshot())
	if money_delta != 0:
		EventBus.money_changed.emit(GameState.money, money_delta)


## Returns the default upgrade costs definition.
static func costs() -> UpgradeCostsDef:
	var found := ContentDB.get_def("upgrade_costs", &"default") as UpgradeCostsDef
	return found if found != null else UpgradeCostsDef.new()


## Collects all rarity definitions as a lookup dictionary.
static func rarities() -> Dictionary[StringName, RarityDef]:
	var out: Dictionary[StringName, RarityDef] = {}
	for r_id: StringName in ContentDB.ids("rarity"):
		out[r_id] = ContentDB.get_def("rarity", r_id) as RarityDef
	return out


## Attempts to upgrade the given item; commits on success and emits a toast.
static func upgrade(item_id: StringName) -> bool:
	var item := ContentDB.get_def("item", item_id) as EquipDef
	if item == null:
		return false
	var h: WorkshopHoldings = holdings()
	if not Upgrades.apply_upgrade(item, costs(), rarities(), h):
		return false
	commit(h)
	var new_level: int = GameState.upgrades.get(item_id, 0)
	var item_name: String = Ui.text(item.name_key) if item.name_key != "" else String(item_id)
	Ui.toast("%s +%d" % [item_name, new_level], &"good")
	return true


## Attempts to craft the given recipe; commits on success and emits a toast.
static func craft(recipe_id: StringName) -> bool:
	var recipe := ContentDB.get_def("recipe", recipe_id) as RecipeDef
	if recipe == null:
		return false
	var h: WorkshopHoldings = holdings()
	var is_stone: bool = ContentDB.get_def("stone", recipe.output) != null
	var con: ConsumableDef = ContentDB.get_def("consumable", recipe.output) as ConsumableDef
	var max_stack: int = con.max_stack if con != null else 99
	if not Crafting.apply_craft(recipe, h, h.owned, is_stone, max_stack):
		return false
	commit(h)
	var out_name: String = _output_name(recipe.output, is_stone, con)
	Ui.toast("Crafted %s" % out_name, &"good")
	return true


## Sets a stone into a hilt's socket, moving it from any other socket if already set.
static func set_stone(hilt_id: StringName, slot: int, stone_id: StringName) -> void:
	var h: WorkshopHoldings = holdings()
	Stones.set_stone(h.sockets, hilt_id, slot, stone_id)
	commit(h)


## Removes a stone from a hilt's socket for free.
static func remove_stone(hilt_id: StringName, slot: int) -> void:
	var h: WorkshopHoldings = holdings()
	Stones.set_stone(h.sockets, hilt_id, slot, &"")
	commit(h)


static func _output_name(id: StringName, is_stone: bool, con: ConsumableDef) -> String:
	if is_stone:
		var st := ContentDB.get_def("stone", id) as StoneDef
		if st != null and st.name_key != "":
			return Ui.text(st.name_key)
	elif con != null and con.name_key != "":
		return Ui.text(con.name_key)
	return String(id)
