class_name Shop
extends RefCounted
## The herb stall's rules, pure: buy (refused when the stock lacks it, the purse is short or the stack is full) and
## sell (bag consumables only, never reserved ones; gear is not a consumable so it can never be sold). Both work on
## a Holdings working copy and return a ShopResult; GameState and the money_changed signal belong to ShopService.

const NOT_IN_STOCK: StringName = &"not_in_stock"
const SHORT_MONEY: StringName = &"short_money"
const STACK_FULL: StringName = &"stack_full"
const NOT_SELLABLE: StringName = &"not_sellable"
const NOTHING_TO_SELL: StringName = &"nothing_to_sell"
const PURSE_FULL: StringName = &"purse_full"
const BAD_COUNT: StringName = &"bad_count"
## Why a trade was refused -> the keeper's line (localization/shop.csv).
const REASON_KEYS: Dictionary[StringName, String] = {
	NOT_IN_STOCK: "SHOP_NOT_STOCKED", SHORT_MONEY: "SHOP_NOT_ENOUGH", STACK_FULL: "SHOP_BAG_FULL",
	NOT_SELLABLE: "SHOP_NOTHING_TO_SELL", NOTHING_TO_SELL: "SHOP_NOTHING_TO_SELL", PURSE_FULL: "SHOP_PURSE_FULL",
	BAD_COUNT: "SHOP_NOT_ENOUGH",
}


## How many of this item the purse and the bag room allow right now.
static func max_buy(def: ConsumableDef, money: int, owned: int) -> int:
	var room: int = maxi(0, def.max_stack - owned)
	if def.price <= 0:
		return room
	return mini(floori(float(money) / float(def.price)), room)


## How many the bag can give up and the purse (under its cap) can take.
static func max_sell(def: ConsumableDef, held: Holdings, rules: EconomyRulesDef) -> int:
	var owned: int = held.bag.available(def.id)
	if def.sell <= 0:
		return owned
	return mini(owned, floori(float(maxi(0, rules.money_cap - held.money)) / float(def.sell)))


static func buy(
		shop: ShopDef, item_id: StringName, amount: int, held: Holdings,
		consumables: Dictionary[StringName, ConsumableDef]) -> ShopResult:
	var def: ConsumableDef = consumables.get(item_id)
	if amount < 1:
		return ShopResult.fail(BAD_COUNT, item_id)
	if def == null or not shop.stock.has(item_id):
		return ShopResult.fail(NOT_IN_STOCK, item_id)
	if held.bag.count(item_id) + amount > def.max_stack:
		return ShopResult.fail(STACK_FULL, item_id)
	if held.money < def.price * amount:
		return ShopResult.fail(SHORT_MONEY, item_id)
	held.bag.add(item_id, amount, def.max_stack)
	held.money -= def.price * amount
	return _done(item_id, amount, -def.price * amount)


static func sell(
		item_id: StringName, amount: int, held: Holdings, rules: EconomyRulesDef,
		consumables: Dictionary[StringName, ConsumableDef]) -> ShopResult:
	var def: ConsumableDef = consumables.get(item_id)
	if amount < 1:
		return ShopResult.fail(BAD_COUNT, item_id)
	if def == null:
		return ShopResult.fail(NOT_SELLABLE, item_id)
	if held.bag.available(item_id) < amount:
		return ShopResult.fail(NOTHING_TO_SELL, item_id)
	if held.money + def.sell * amount > rules.money_cap:
		return ShopResult.fail(PURSE_FULL, item_id)
	held.bag.remove(item_id, amount)
	held.money += def.sell * amount
	return _done(item_id, amount, def.sell * amount)


static func _done(item_id: StringName, amount: int, delta: int) -> ShopResult:
	var result := ShopResult.new()
	result.ok = true
	result.item_id = item_id
	result.count = amount
	result.money_delta = delta
	return result
