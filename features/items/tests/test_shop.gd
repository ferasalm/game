extends TestCase
## The herb stall: buy and sell rules and their edge cases (economy.md section 9), the ShopService purse signal,
## and using consumables in the field (FieldUse, ItemService).


func _shop() -> ShopDef:
	return ContentDB.get_def("shop", &"herb_stall") as ShopDef


func _herbs() -> Dictionary[StringName, ConsumableDef]:
	return ShopService.consumables()


func _held(money: int, counts: Dictionary, flags: Dictionary[StringName, bool] = {}) -> Holdings:
	var held := Holdings.new()
	held.money = money
	held.bag = Bag.from_counts(counts)
	held.flags = flags
	return held


func test_the_shipped_stall() -> void:
	var shop: ShopDef = _shop()
	check(shop != null, "herb_stall loads")
	check_eq(shop.stock, [&"pink_herb", &"yellow_herb", &"white_herb"] as Array[StringName], "stock")
	for item_id: StringName in _herbs():
		var def: ConsumableDef = _herbs()[item_id]
		check(def.sell * 2 <= def.price, "%s sells for at most half its price" % item_id)


func test_buy_pays_and_fills_the_bag() -> void:
	var held: Holdings = _held(100, {&"pink_herb": 1})
	var greedy: ShopResult = Shop.buy(_shop(), &"pink_herb", 1, held, _herbs())
	check(not greedy.ok and greedy.reason == Shop.SHORT_MONEY, "300 riyal needed before beaten")
	held.flags[&"abu_nabil_beaten"] = true
	var result: ShopResult = Shop.buy(_shop(), &"pink_herb", 2, held, _herbs())
	check(result.ok and result.count == 2, "bought two")
	check_eq(result.money_delta, -60, "60 riyal paid")
	check_eq(held.money, 40, "purse")
	check_eq(held.bag.count(&"pink_herb"), 3, "bag")


func test_buy_refusals_change_nothing() -> void:
	var held: Holdings = _held(25, {&"pink_herb": 5}, {&"abu_nabil_beaten": true})
	var short: ShopResult = Shop.buy(_shop(), &"yellow_herb", 2, held, _herbs())
	check_eq(short.reason, Shop.SHORT_MONEY, "40 needed, 25 held")
	var full: ShopResult = Shop.buy(_shop(), &"pink_herb", 1, held, _herbs())
	check_eq(full.reason, Shop.STACK_FULL, "a full stack")
	var none: ShopResult = Shop.buy(_shop(), &"pink_herb", 0, held, _herbs())
	check_eq(none.reason, Shop.BAD_COUNT, "zero is not a purchase")
	var limited := ShopDef.new()
	limited.stock = [&"pink_herb"] as Array[StringName]
	var absent: ShopResult = Shop.buy(limited, &"white_herb", 1, held, _herbs())
	check_eq(absent.reason, Shop.NOT_IN_STOCK, "not in this stall's stock")
	var unknown: ShopResult = Shop.buy(_shop(), &"anvil_hilt", 1, held, _herbs())
	check_eq(unknown.reason, Shop.NOT_IN_STOCK, "gear is not stock")
	check(held.money == 25 and held.bag.count(&"pink_herb") == 5 and held.bag.count(&"yellow_herb") == 0, "all refusals left it alone")


func test_buy_limits() -> void:
	var pink: ConsumableDef = _herbs()[&"pink_herb"]
	check_eq(Shop.max_buy(pink, 100, 1), 3, "100 riyal buys three")
	check_eq(Shop.max_buy(pink, 1000, 3), 2, "the stack leaves room for two")
	check_eq(Shop.max_buy(pink, 10, 0), 0, "too poor")
	check_eq(Shop.max_buy(pink, 1000, 5), 0, "full")


func test_sell_pays_the_sell_value_of_consumables_only() -> void:
	var held: Holdings = _held(0, {&"pink_herb": 2})
	var result: ShopResult = Shop.sell(&"pink_herb", 2, held, ShopService.rules(), _herbs())
	check(result.ok, "sold")
	check_eq(held.money, 30, "2 x 15")
	check(held.bag.is_empty(), "bag emptied")
	var gear: ShopResult = Shop.sell(&"anvil_hilt", 1, held, ShopService.rules(), _herbs())
	check_eq(gear.reason, Shop.NOT_SELLABLE, "gear never sells")
	var missing: ShopResult = Shop.sell(&"pink_herb", 1, held, ShopService.rules(), _herbs())
	check_eq(missing.reason, Shop.NOTHING_TO_SELL, "none left")


func test_a_reserved_herb_cannot_be_sold_and_the_purse_cap_holds() -> void:
	var held: Holdings = _held(0, {&"white_herb": 1})
	held.bag.reserve(&"white_herb")
	var blocked: ShopResult = Shop.sell(&"white_herb", 1, held, ShopService.rules(), _herbs())
	check_eq(blocked.reason, Shop.NOTHING_TO_SELL, "reserved by a pending cast")
	var rich: Holdings = _held(9990, {&"white_herb": 1})
	var capped: ShopResult = Shop.sell(&"white_herb", 1, rich, ShopService.rules(), _herbs())
	check_eq(capped.reason, Shop.PURSE_FULL, "40 riyal does not fit under the cap")
	check_eq(Shop.max_sell(_herbs()[&"white_herb"], rich, ShopService.rules()), 0, "max_sell agrees")
	check_eq(rich.money, 9990, "untouched")


func test_every_refusal_has_a_keeper_line() -> void:
	for reason: StringName in [Shop.NOT_IN_STOCK, Shop.SHORT_MONEY, Shop.STACK_FULL, Shop.NOT_SELLABLE,
			Shop.NOTHING_TO_SELL, Shop.PURSE_FULL, Shop.BAD_COUNT]:
		var key: String = Shop.REASON_KEYS.get(reason, "")
		check(not key.is_empty() and Ui.text(key) != key, "text for %s" % reason)


func test_service_writes_game_state_and_announces_the_purse() -> void:
	GameState.start_new()
	GameState.flags[&"abu_nabil_beaten"] = true
	var log: Array = []
	var hook := func(total: int, delta: int) -> void: log.append([total, delta])
	EventBus.money_changed.connect(hook)
	check(ShopService.buy(&"herb_stall", &"yellow_herb", 2).ok, "bought")
	check_eq(GameState.money, 60, "100 - 40")
	check_eq(GameState.bag.get(&"yellow_herb"), 2, "bag")
	check(not ShopService.buy(&"herb_stall", &"white_herb", 2).ok, "160 is too much")
	check(ShopService.sell(&"yellow_herb", 1).ok, "sold one")
	check_eq(GameState.money, 70, "60 + 10")
	EventBus.money_changed.disconnect(hook)
	check_eq(log, [[60, -40], [70, 10]], "one signal per trade, none for the refusal")


func _maxes() -> Dictionary:
	return {&"zayd": Vector2i(400, 24), &"bilqis": Vector2i(280, 36)}


func test_field_use_heals_a_hurt_hero_and_takes_one() -> void:
	var held: Holdings = _held(0, {&"pink_herb": 2})
	var vitals: Dictionary = {&"zayd": {"hp": 100, "sp": 24}}
	var pink: ConsumableDef = _herbs()[&"pink_herb"]
	var result: Dictionary = FieldUse.use(pink, held, vitals, [&"zayd"] as Array[StringName], _maxes())
	check(result["ok"], "used")
	check_eq(Vitals.hp_of(vitals, &"zayd", 400), 220, "100 + 120")
	check_eq(held.bag.count(&"pink_herb"), 1, "one herb gone")


func test_field_use_refuses_a_full_hero_and_battle_items() -> void:
	var held: Holdings = _held(0, {&"pink_herb": 1, &"white_herb": 1})
	var vitals: Dictionary = {}
	var full: Dictionary = FieldUse.use(_herbs()[&"pink_herb"], held, vitals, [&"zayd"] as Array[StringName], _maxes())
	check(not full["ok"] and full["reason"] == FieldUse.NO_EFFECT, "full HP: refused")
	var ko: Dictionary = {&"zayd": {"hp": 0, "sp": 24}}
	var white: Dictionary = FieldUse.use(_herbs()[&"white_herb"], held, ko, [&"zayd"] as Array[StringName], _maxes())
	check(not white["ok"] and white["reason"] == FieldUse.NOT_FIELD, "the white herb is battle only")
	var pink: Dictionary = FieldUse.use(_herbs()[&"pink_herb"], held, ko, [&"zayd"] as Array[StringName], _maxes())
	check(not pink["ok"], "a hp herb does nothing for a downed hero")
	check(held.bag.count(&"pink_herb") == 1 and held.bag.count(&"white_herb") == 1, "nothing was used")
	var empty: Dictionary = FieldUse.use(_herbs()[&"yellow_herb"], held, {&"zayd": {"hp": 5, "sp": 0}}, [&"zayd"] as Array[StringName], _maxes())
	check_eq(empty["reason"], FieldUse.NONE_LEFT, "none in the bag")


func test_qishr_cup_heals_the_whole_party_with_one_cup() -> void:
	GameState.start_new()
	GameState.set_bag({&"qishr_cup": 1})
	GameState.set_vitals({&"zayd": {"hp": 100, "sp": 24}, &"bilqis": {"hp": 280, "sp": 36}})
	var result: Dictionary = ItemService.use(&"qishr_cup", &"zayd")
	check(result["ok"], "used")
	check_eq((result["gains"] as Dictionary).keys(), [&"zayd"], "only the hurt hero gained")
	check_eq(GameState.vitals[&"zayd"]["hp"], 175, "100 + 75")
	check(GameState.bag.is_empty(), "the cup is gone")


func test_item_service_writes_carried_vitals() -> void:
	GameState.start_new()
	GameState.set_vitals({&"bilqis": {"hp": 280, "sp": 10}})
	var result: Dictionary = ItemService.use(&"yellow_herb", &"bilqis")
	check(not result["ok"], "no yellow herb in the starting bag")
	GameState.set_bag({&"yellow_herb": 1})
	result = ItemService.use(&"yellow_herb", &"bilqis")
	check(result["ok"], "now used")
	check_eq(GameState.vitals[&"bilqis"]["sp"], 22, "10 + 12")
	check(GameState.bag.is_empty(), "bag empty")
