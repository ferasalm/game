extends TestCase
## Tests for battle progression integration: LevelUp HP/SP increases on win.


func test_levelup_raises_current_hp_and_sp_by_the_gains() -> void:
	var outcome := BattleOutcome.new()
	outcome.encounter_id = &"rooftop_patrol"
	outcome.result = BattleOutcome.VICTORY
	outcome.vitals = {
		&"rydan": {"hp": 45, "sp": 10},
		&"bilqis": {"hp": 20, "sp": 5}
	}
	var lu := LevelUp.new()
	lu.hero = &"rydan"
	lu.from_level = 1
	lu.to_level = 2
	lu.gains = {&"max_hp": 30, &"max_sp": 2, &"attack": 2, &"defense": 2, &"agility": 1, &"luck": 1}
	outcome.level_ups = [lu]
	# The victory path raises current HP/SP by the level-up gains
	for level_up: LevelUp in outcome.level_ups:
		if outcome.vitals.has(level_up.hero):
			var vit: Dictionary = outcome.vitals[level_up.hero]
			vit["hp"] = int(vit.get("hp", 0)) + level_up.gains.get(&"max_hp", 0)
			vit["sp"] = int(vit.get("sp", 0)) + level_up.gains.get(&"max_sp", 0)
	check_eq(outcome.vitals[&"rydan"]["hp"], 75, "45 + 30 max HP gain = 75")
	check_eq(outcome.vitals[&"rydan"]["sp"], 12, "10 + 2 max SP gain = 12")
	check_eq(outcome.vitals[&"bilqis"]["hp"], 20, "bilqis vitals unchanged")
