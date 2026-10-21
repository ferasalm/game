class_name ShopService
extends RefCounted
## Runs the stall against GameState: Shop does the rules on a Holdings copy, this takes the copy back and announces
## it. The ONE place a shop changes the purse: _commit() emits EventBus.money_changed (and item_gained for a buy).


static func shop(shop_id: StringName) -> ShopDef:
	return ContentDB.get_def("shop", shop_id) as ShopDef


static func buy(shop_id: StringName, item_id: StringName, amount: int) -> ShopResult:
	var def: ShopDef = shop(shop_id)
	if def == null:
		return ShopResult.fail(Shop.NOT_IN_STOCK, item_id)
	var held: Holdings = GameState.holdings()
	var result: ShopResult = Shop.buy(def, item_id, amount, held, consumables())
	if result.ok:
		_commit(held, result)
		EventBus.item_gained.emit(item_id, result.count)
	return result


static func sell(item_id: StringName, amount: int) -> ShopResult:
	var held: Holdings = GameState.holdings()
	var result: ShopResult = Shop.sell(item_id, amount, held, rules(), consumables())
	if result.ok:
		_commit(held, result)
	return result


## The keeper's opening line key: first visit (the shop's own greeting), a return visit, or right after a battle.
## Remembers the visit in GameState.flags.
static func greeting(def: ShopDef, after_battle: bool) -> String:
	var seen: StringName = StringName("shop_visited_" + String(def.id))
	var again: bool = GameState.flags.get(seen, false)
	GameState.flags[seen] = true
	if after_battle:
		return "SHOP_GREET_AFTER_BATTLE"
	return "SHOP_GREET_RETURN" if again else def.greeting_key


## How many of the item can change hands now (purse and stack for a buy; bag and purse cap for a sell).
static func limit(item_id: StringName, selling: bool) -> int:
	var def: ConsumableDef = consumables().get(item_id)
	if def == null:
		return 0
	if selling:
		return Shop.max_sell(def, GameState.holdings(), rules())
	return Shop.max_buy(def, GameState.money, GameState.bag.get(item_id, 0))


static func rules() -> EconomyRulesDef:
	var found := ContentDB.get_def("economy_rules", &"default") as EconomyRulesDef
	return found if found != null else EconomyRulesDef.new()


static func consumables() -> Dictionary[StringName, ConsumableDef]:
	var out: Dictionary[StringName, ConsumableDef] = {}
	for item_id: StringName in ContentDB.ids("consumable"):
		out[item_id] = ContentDB.get_def("consumable", item_id) as ConsumableDef
	return out


static func _commit(held: Holdings, result: ShopResult) -> void:
	GameState.take(held)
	EventBus.money_changed.emit(GameState.money, result.money_delta)
