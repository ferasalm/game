class_name TestWorkshopLoot
extends TestCase
## purpose: Tests material payouts on battle victory and repeat victories.


## The victory material rule: every encounter material at full share, the repeat share once the patrol is cleared.
func _pay_materials(outcome: BattleOutcome, cleared: Array[StringName]) -> void:
	var encounter := ContentDB.get_def("encounter", outcome.encounter_id) as EncounterDef
	if encounter == null or encounter.materials.is_empty():
		return
	var rules := ContentDB.get_def("economy_rules", &"default") as EconomyRulesDef
	var share: float = rules.repeat_payout if (cleared.has(outcome.encounter_id) and rules != null) else 1.0
	for mat_id: StringName in encounter.materials:
		var count: int = floori(float(encounter.materials[mat_id]) * share)
		if count > 0:
			Materials.add(GameState.materials, mat_id, count)


func _win(encounter_id: StringName, cleared: Array[StringName]) -> void:
	var outcome := BattleOutcome.new()
	outcome.encounter_id = encounter_id
	outcome.result = BattleOutcome.VICTORY
	_pay_materials(outcome, cleared)
	if not cleared.has(encounter_id):
		cleared.append(encounter_id)


func test_battle_win_pays_materials_and_repeat_win_half() -> void:
	GameState.reset()
	var cleared: Array[StringName] = []

	_win(&"patrol_pair", cleared)
	check_eq(GameState.materials.get(&"scrap_copper", 0), 2, "first win pays 2 scrap copper")
	check(cleared.has(&"patrol_pair"), "patrol marked cleared")

	_win(&"patrol_pair", cleared)
	check_eq(GameState.materials.get(&"scrap_copper", 0), 3, "repeat win pays half (1 scrap copper, 2+1=3)")

	_win(&"patrol_drone", cleared)
	check_eq(GameState.materials.get(&"drone_coil", 0), 1, "first drone win pays 1 drone coil")

	_win(&"patrol_drone", cleared)
	check_eq(GameState.materials.get(&"drone_coil", 0), 1, "repeat drone win pays floor(1*0.5)=0, total stays 1")
	GameState.reset()
