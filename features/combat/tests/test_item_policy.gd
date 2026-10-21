extends TestCase
## ItemPolicy (balance harness): herbs only when the bag has them, deterministic, battles still end.

var _loader: BattleLoader


func _load() -> void:
	var db: Node = load("res://core/content_db.gd").new()
	check_eq(db.call("load_all"), PackedStringArray(), "shipped content loads")
	_loader = BattleLoader.from_db(db)
	db.free()


func _herbs(events: Array[TimelineEvent]) -> int:
	var n: int = 0
	for event: TimelineEvent in events:
		n += 1 if event.kind == &"item_used" else 0
	return n


func test_no_bag_no_herbs() -> void:
	_load()
	var sim: BattleSim = _loader.make_sim(&"swift_hilt", &"keen_blade", 3)
	check_eq(_herbs(BattleLoader.autoplay(sim, true)), 0, "an empty bag never yields an item_used")
	check(sim.result != &"", "the battle still ends")


func test_herbs_spent_never_exceed_the_bag() -> void:
	_load()
	_loader.start_bag = {&"pink_herb": 2, &"white_herb": 1, &"yellow_herb": 1}
	var used: int = 0
	for battle_seed: int in range(1, 21):
		var sim: BattleSim = _loader.make_sim(&"swift_hilt", &"keen_blade", battle_seed)
		var n: int = _herbs(BattleLoader.autoplay(sim, true))
		check(n <= 4, "seed %d used %d herbs of 4" % [battle_seed, n])
		check(sim.result != &"", "seed %d ends" % battle_seed)
		used += n
	check(used > 0, "some fight in 20 spends a herb")


func test_policy_is_deterministic() -> void:
	_load()
	_loader.start_bag = {&"pink_herb": 2}
	var a: String = BattleProbe.text(BattleLoader.autoplay(_loader.make_sim(&"swift_hilt", &"keen_blade", 5), true))
	var b: String = BattleProbe.text(BattleLoader.autoplay(_loader.make_sim(&"swift_hilt", &"keen_blade", 5), true))
	check_eq(a, b, "same seed and bag, same events")
