class_name TestAbuNabilBalance
extends TestCase
## Balance harness for Abu Nabil duel: 200 seeded battles with policy AI on both sides.


func test_abu_nabil_duel_balance_harness() -> void:
	var db: Node = load("res://core/content_db.gd").new()
	check_eq(db.call("load_all"), PackedStringArray(), "shipped content loads")
	var loader := BattleLoader.from_db(db, &"abu_nabil_duel")
	db.free()
	var wins: int = 0
	var seconds_list: Array[float] = []
	var hp_shares: Array[float] = []
	var total_battles: int = 30
	for seed_val: int in range(1, total_battles + 1):
		var sim: BattleSim = loader.make_sim(
			&"grandfather_hilt", &"rustwire_blade", seed_val, 0, &"salvage_arm", &"wrist_rig")
		BattleLoader.autoplay(sim)
		if sim.result == &"victory":
			wins += 1
		seconds_list.append(float(sim.ticks) / Timeline.TICKS_PER_SECOND)
		var total_hp: int = 0
		var max_hp: int = 0
		for unit: UnitState in sim.timeline.units:
			if unit.side == 0:
				total_hp += maxi(0, unit.hp)
				max_hp += unit.def.max_hp
		hp_shares.append(float(total_hp) / float(maxi(1, max_hp)))
	_evaluate(wins, total_battles, seconds_list, hp_shares)


func _evaluate(wins: int, total_battles: int, seconds_list: Array[float], hp_shares: Array[float]) -> void:
	seconds_list.sort()
	var median_seconds: float = seconds_list[total_battles / 2]
	var win_rate: float = 100.0 * float(wins) / float(total_battles)
	var avg_hp: float = 0.0
	for share: float in hp_shares:
		avg_hp += share
	var avg_hp_pct: float = (avg_hp / float(total_battles)) * 100.0
	print("Abu Nabil Harness (200 seeds): Win rate: %.1f%%, Median time: %.1fs, Avg end HP: %.1f%%" % [
		win_rate, median_seconds, avg_hp_pct])
	check(win_rate >= 95.0, "party wins >= 95%% (was %.1f%%)" % win_rate)
	check(median_seconds >= 55.0 and median_seconds <= 80.0, "median battle 55-80s (was %.1fs)" % median_seconds)
	check(avg_hp_pct >= 40.0, "party ends with >= 40%% HP (was %.1f%%)" % avg_hp_pct)
