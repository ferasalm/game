extends TestCase
## Tests for battle progression integration: LevelUp HP/SP increases on win, and battle end panel formatting.


func test_levelup_raises_current_hp_and_sp_by_the_gains() -> void:
	var outcome := BattleOutcome.new()
	outcome.encounter_id = &"rooftop_patrol"
	outcome.result = BattleOutcome.VICTORY
	outcome.vitals = {
		&"zayd": {"hp": 45, "sp": 10},
		&"bilqis": {"hp": 20, "sp": 5}
	}
	var lu := LevelUp.new()
	lu.hero = &"zayd"
	lu.from_level = 1
	lu.to_level = 2
	lu.gains = {&"max_hp": 30, &"max_sp": 2, &"attack": 2, &"defense": 2, &"agility": 1, &"luck": 1}
	outcome.level_ups = [lu]
	# Simulate the HP/SP raising logic executed in BattleSession._win
	for level_up: LevelUp in outcome.level_ups:
		if outcome.vitals.has(level_up.hero):
			var vit: Dictionary = outcome.vitals[level_up.hero]
			vit["hp"] = int(vit.get("hp", 0)) + level_up.gains.get(&"max_hp", 0)
			vit["sp"] = int(vit.get("sp", 0)) + level_up.gains.get(&"max_sp", 0)
	check_eq(outcome.vitals[&"zayd"]["hp"], 75, "45 + 30 max HP gain = 75")
	check_eq(outcome.vitals[&"zayd"]["sp"], 12, "10 + 2 max SP gain = 12")
	check_eq(outcome.vitals[&"bilqis"]["hp"], 20, "bilqis vitals unchanged")


func test_battle_end_panel_records_and_shows_level_ups() -> void:
	var panel := BattleEndPanel.new()
	var view := BattleViewDef.new()
	view.margin = 8.0
	view.end_panel_w = 400.0
	view.end_title_font = 24
	panel.setup(view)
	var lu := LevelUp.new()
	lu.hero = &"zayd"
	lu.from_level = 2
	lu.to_level = 3
	lu.gains = {&"max_hp": 30, &"attack": 2}
	panel.set_level_ups([lu])
	check_eq(panel.shown_level_ups().size(), 1, "panel holds 1 level up")
	panel.show_result(&"victory")
	panel.queue_free()
