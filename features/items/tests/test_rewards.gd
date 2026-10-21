extends TestCase
## Rewards: the first win pays everything and sets patrol_paid_<id>, a repeat win pays half the riyal and nothing
## else, herbs over the stack turn into riyal, the purse has a cap, a chest pays once. RewardApplier announces.


func _rules() -> EconomyRulesDef:
	return ContentDB.get_def("economy_rules", &"default") as EconomyRulesDef


func _herbs() -> Dictionary[StringName, ConsumableDef]:
	var out: Dictionary[StringName, ConsumableDef] = {}
	for item_id: StringName in ContentDB.ids("consumable"):
		out[item_id] = ContentDB.get_def("consumable", item_id) as ConsumableDef
	return out


func _enc(id: StringName) -> EncounterDef:
	return ContentDB.get_def("encounter", id) as EncounterDef


func test_shipped_economy_and_encounters() -> void:
	var rules: EconomyRulesDef = _rules()
	check(rules != null and rules.start_money == 100 and rules.start_bag == {&"pink_herb": 1}, "100 riyal and a pink herb")
	check_eq(_enc(&"patrol_scouts").money, 40, "scouts pay 40")
	check_eq(_enc(&"rooftop_patrol").money, 70, "the rooftop patrol pays 70")
	check_eq(_enc(&"patrol_gate").consumables, {&"white_herb": 1} as Dictionary[StringName, int], "the gate drops a white herb")
	var chest := ContentDB.get_def("chest", &"chest_saila") as ChestDef
	check(chest.money == 25 and chest.consumables == ({&"yellow_herb": 1} as Dictionary[StringName, int]), "chest_saila pays 25 + yellow")


func test_first_win_pays_everything_then_the_repeat_rate() -> void:
	var held := Holdings.new()
	var first: RewardResult = Rewards.victory(_enc(&"rooftop_patrol"), held, _rules(), _herbs())
	check_eq(first.money, 70, "full pay on the first win")
	check_eq(first.items, [&"anvil_hilt"] as Array[StringName], "and the hilt")
	check(held.flags.get(&"patrol_paid_rooftop_patrol", false), "the paid flag is set")
	var again: RewardResult = Rewards.victory(_enc(&"rooftop_patrol"), held, _rules(), _herbs())
	check_eq(again.money, 35, "a repeat win pays half")
	check(again.items.is_empty() and again.consumables.is_empty(), "and drops nothing")
	check_eq(held.money, 105, "the purse holds both")
	var gate := Holdings.new()
	var drop: RewardResult = Rewards.victory(_enc(&"patrol_gate"), gate, _rules(), _herbs())
	check_eq(drop.consumables, {&"white_herb": 1} as Dictionary[StringName, int], "first gate win gives the herb")
	var repeat: RewardResult = Rewards.victory(_enc(&"patrol_gate"), gate, _rules(), _herbs())
	check_eq(repeat.money, 60, "repeat gate pays 60")
	check_eq(gate.bag.count(&"white_herb"), 1, "no second herb")


func test_overflow_herbs_become_riyal_and_the_purse_is_capped() -> void:
	var held := Holdings.new()
	held.bag = Bag.from_counts({&"white_herb": 3})
	var result: RewardResult = Rewards.victory(_enc(&"patrol_gate"), held, _rules(), _herbs())
	check(result.consumables.is_empty(), "the bag was full of white herbs")
	check_eq(result.overflow_money, 40, "sold at the sell price")
	check_eq(held.money, 160, "120 + 40")
	var rich := Holdings.new()
	rich.money = 9990
	var capped: RewardResult = Rewards.victory(_enc(&"patrol_scouts"), rich, _rules(), _herbs())
	check_eq(rich.money, 9999, "capped")
	check_eq(capped.money_lost, 31, "the rest is dropped and reported")


func test_a_chest_pays_once() -> void:
	var held := Holdings.new()
	var chest := ContentDB.get_def("chest", &"chest_mafraj") as ChestDef
	var first: RewardResult = Rewards.chest(chest, held, _rules(), _herbs())
	check_eq(first.money, 25, "riyal")
	check_eq(first.items, [chest.item] as Array[StringName], "the item")
	check_eq(held.bag.count(&"pink_herb"), 1, "and a pink herb")
	var second: RewardResult = Rewards.chest(chest, held, _rules(), _herbs())
	check(second.already_done and second.is_empty(), "a second opening gives nothing")
	check_eq(held.money, 25, "no second payment")


func test_a_chest_with_an_owned_item_still_pays_the_rest() -> void:
	var held := Holdings.new()
	var chest := ContentDB.get_def("chest", &"chest_saila") as ChestDef
	held.inventory.append(chest.item)
	var result: RewardResult = Rewards.chest(chest, held, _rules(), _herbs())
	check(result.items.is_empty(), "the item was already owned")
	check_eq(result.money, 25, "riyal still paid")


func test_applier_updates_game_state_and_announces() -> void:
	GameState.start_new()
	var log: Array = []
	var money_hook := func(total: int, delta: int) -> void: log.append(["money", total, delta])
	var item_hook := func(item_id: StringName) -> void: log.append(["item", item_id])
	var gain_hook := func(item_id: StringName, count: int) -> void: log.append(["gain", item_id, count])
	EventBus.money_changed.connect(money_hook)
	EventBus.item_obtained.connect(item_hook)
	EventBus.item_gained.connect(gain_hook)
	RewardApplier.victory(&"patrol_gate")
	check_eq(GameState.money, 220, "100 start + 120")
	check_eq(GameState.bag.get(&"white_herb"), 1, "herb in the bag")
	check(log.has(["money", 220, 120]) and log.has(["gain", &"white_herb", 1]), "announced: %s" % [log])
	RewardApplier.chest(&"chest_saila")
	check(GameState.inventory.has(&"arc_arm") and GameState.bag.get(&"yellow_herb") == 1, "chest items arrive")
	log.clear()
	RewardApplier.chest(&"chest_saila")
	check(log.is_empty(), "a second opening announces nothing")
	EventBus.money_changed.disconnect(money_hook)
	EventBus.item_obtained.disconnect(item_hook)
	EventBus.item_gained.disconnect(gain_hook)
	GameState.reset()
