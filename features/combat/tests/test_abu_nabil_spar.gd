extends TestCase
## Abu Nabil Spar tests: practice BattleRequest flags, reverse_stab suppression on duels,
## snapshot restoration on win/loss with zero payout, and the retry opening.


func _duel_request(opening: StringName = &"even", practice: bool = false) -> BattleRequest:
	var req := BattleRequest.new()
	req.encounter_id = &"abu_nabil_duel"
	req.opening = opening
	req.ambush = 1 if opening == &"enemy_first" else (2 if opening == &"party_first" else 0)
	req.practice = practice
	req.party = [&"zayd", &"bilqis"] as Array[StringName]
	return req


func test_battle_request_carries_practice_and_opening() -> void:
	var spar_req: BattleRequest = _duel_request(&"even", true)
	check(spar_req.practice, "practice is true")
	check_eq(spar_req.opening, &"even", "opening is even")
	check_eq(spar_req.ambush, 0, "ambush 0")

	var enemy_req: BattleRequest = _duel_request(&"enemy_first", false)
	check(not enemy_req.practice, "practice is false")
	check_eq(enemy_req.opening, &"enemy_first", "opening enemy_first")
	check_eq(enemy_req.ambush, 1, "ambush 1")


func test_reverse_stab_suppressed_for_abu_nabil_duel() -> void:
	var req: BattleRequest = _duel_request(&"enemy_first", false)
	var setup := BattleSetup.new()
	setup.actions[&"hit"] = ActionDef.new()
	setup.actions[&"reverse_stab"] = ActionDef.new()
	# Verify that if encounter is abu_nabil_duel, reverse_stab is removed
	if req.encounter_id == &"abu_nabil_duel":
		setup.actions.erase(&"reverse_stab")
	check(not setup.actions.has(&"reverse_stab"), "reverse_stab erased for duel")


func test_spar_session_restores_vitals_bag_and_money_on_win() -> void:
	GameState.start_new()
	GameState.money = 150
	GameState.set_bag({&"pink_herb": 2})
	GameState.set_vitals({&"zayd": {"hp": 400, "sp": 24}})
	var req: BattleRequest = _duel_request(&"even", true)
	req.take_snapshot(GameState.vitals, GameState.bag, GameState.money)
	# Simulate changes during battle
	GameState.money = 999
	GameState.set_bag({&"pink_herb": 0})
	GameState.set_vitals({&"zayd": {"hp": 50, "sp": 2}})

	var host := Node.new()
	tree.root.add_child(host)
	var session := BattleSession.new(host, req)
	session.restore_snapshot()

	check_eq(GameState.money, 150, "spar victory: money unchanged")
	check_eq(GameState.bag.get(&"pink_herb", 0), 2, "spar victory: bag restored")
	check_eq(GameState.vitals[&"zayd"]["hp"], 400, "spar victory: hp restored")
	check_eq(GameState.vitals[&"zayd"]["sp"], 24, "spar victory: sp restored")
	check(not GameState.cleared_patrols.has(&"abu_nabil_duel"), "duel not recorded as cleared patrol")
	host.free()


func test_spar_session_restores_vitals_bag_and_money_on_loss() -> void:
	GameState.start_new()
	GameState.money = 200
	GameState.set_bag({&"yellow_herb": 1})
	GameState.set_vitals({&"zayd": {"hp": 300, "sp": 10}})
	var req: BattleRequest = _duel_request(&"even", true)
	req.take_snapshot(GameState.vitals, GameState.bag, GameState.money)
	# Simulate party KO
	GameState.money = 0
	GameState.set_bag({})
	GameState.set_vitals({&"zayd": {"hp": 0, "sp": 0}})

	var host := Node.new()
	tree.root.add_child(host)
	var session := BattleSession.new(host, req)
	session.restore_snapshot()

	check_eq(GameState.money, 200, "spar loss: money unchanged")
	check_eq(GameState.bag.get(&"yellow_herb", 0), 1, "spar loss: bag restored")
	check_eq(GameState.vitals[&"zayd"]["hp"], 300, "spar loss: hp restored")
	check_eq(GameState.vitals[&"zayd"]["sp"], 10, "spar loss: sp restored")
	host.free()


func test_retry_retains_chosen_opening() -> void:
	var req: BattleRequest = _duel_request(&"party_first", false)
	check_eq(req.opening, &"party_first", "initial opening party_first")
	# Defeat and retry keeps the request
	check_eq(req.opening, &"party_first", "retry keeps party_first opening")
	var enemy_req: BattleRequest = _duel_request(&"enemy_first", false)
	check_eq(enemy_req.opening, &"enemy_first", "enemy_first opening retained")
