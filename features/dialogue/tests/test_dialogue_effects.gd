extends TestCase
## Dialogue effects: the start_battle effect asks the battle host through EventBus instead of starting a stage.


func test_start_battle_emits_battle_requested() -> void:
	GameState.start_new()
	var seen: Array[BattleRequest] = []
	var handler := func(request: BattleRequest) -> void: seen.append(request)
	EventBus.battle_requested.connect(handler)
	DialogueEffects.apply("start_battle abu_nabil_duel even")
	EventBus.battle_requested.disconnect(handler)
	check_eq(seen.size(), 1, "one request emitted")
	if seen.size() == 1:
		check_eq(seen[0].encounter_id, &"abu_nabil_duel", "the encounter asked for")
