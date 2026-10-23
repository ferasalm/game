class_name TestWorkshopLoot
extends TestCase
## purpose: Tests material payouts on battle victory and repeat victories.


func test_battle_win_pays_materials_and_repeat_win_half() -> void:
	GameState.reset()
	var host := Node.new()
	var req := BattleRequest.new()
	var session := BattleSession.new(host, req)

	var outcome1 := BattleOutcome.new()
	outcome1.encounter_id = &"patrol_pair"
	outcome1.result = BattleOutcome.VICTORY
	session._win(outcome1)

	check_eq(GameState.materials.get(&"scrap_copper", 0), 2, "first win pays 2 scrap copper")
	check(GameState.cleared_patrols.has(&"patrol_pair"), "patrol marked cleared")

	var outcome2 := BattleOutcome.new()
	outcome2.encounter_id = &"patrol_pair"
	outcome2.result = BattleOutcome.VICTORY
	session._win(outcome2)

	check_eq(GameState.materials.get(&"scrap_copper", 0), 3, "repeat win pays half (1 scrap copper, 2+1=3)")

	var outcome3 := BattleOutcome.new()
	outcome3.encounter_id = &"patrol_drone"
	outcome3.result = BattleOutcome.VICTORY
	session._win(outcome3)

	check_eq(GameState.materials.get(&"drone_coil", 0), 1, "first drone win pays 1 drone coil")

	var outcome4 := BattleOutcome.new()
	outcome4.encounter_id = &"patrol_drone"
	outcome4.result = BattleOutcome.VICTORY
	session._win(outcome4)

	check_eq(GameState.materials.get(&"drone_coil", 0), 1, "repeat drone win pays floor(1*0.5)=0, total stays 1")
	host.free()
	GameState.reset()
