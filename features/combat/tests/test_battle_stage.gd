extends TestCase
## BattleStage headless (instant mode): it builds with 5 fighters, 5 timeline icons and a camera; an auto-played
## battle ends once; the command menu opens for a waiting hero, lists that hero's moves and the sim's valid
## targets, and choosing through its confirm path calls sim.choose; enemy intent labels; tips; the end panel.


func _stage(auto: bool, ambush: int = 0) -> BattleStage:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var stage := BattleStage.new()
	stage.instant = true
	stage.auto_play = auto
	tree.root.add_child(stage)
	stage.start(loader.make_sim(&"swift_hilt", &"keen_blade", 7, ambush), Vector3.ZERO)
	return stage


func _ids(units: Array[UnitState]) -> Array[StringName]:
	var out: Array[StringName] = []
	for unit: UnitState in units:
		out.append(unit.unit_id)
	return out


func _button_ids(buttons: Array[Button], key: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for button: Button in buttons:
		out.append(button.get_meta(key) as StringName)
	return out


func test_builds_headless() -> void:
	var stage: BattleStage = _stage(true)
	check_eq(stage.fighters.count(), 5, "five fighters on the stage")
	check_eq(stage.hud.timeline_bar.icon_count(), 5, "five timeline icons")
	check_eq(stage.hud.timeline_bar.visible_icons(), 5, "all five icons show at the start")
	check(stage.hud.strips.strip_of(&"zayd") != null and stage.hud.strips.strip_of(&"bilqis") != null, "a vitals strip per hero")
	check(stage.camera != null and stage.camera.current, "the stage camera is current")
	stage.free()


func test_auto_battle_ends_once() -> void:
	var stage: BattleStage = _stage(true, 1)
	var ends: Array[StringName] = []
	stage.ended.connect(func(result: StringName) -> void: ends.append(result))
	var result: StringName = stage.run_to_end(30000)
	check(result == &"victory" or result == &"defeat", "the battle ends (%s)" % result)
	stage.run_to_end(100)
	check_eq(ends.size(), 1, "ended is emitted exactly once")
	check(ends.size() == 1 and ends[0] == result, "ended carries the sim's result")
	for unit: UnitState in stage.sim.timeline.units:
		check_eq(stage.shown_hp[unit.unit_id], unit.hp, "shown HP matches the sim for " + unit.unit_id)
	stage.free()


func test_menu_lists_moves_and_targets() -> void:
	GameState.flags.erase(&"tip_command_seen")
	var stage: BattleStage = _stage(false)
	check_eq(stage.run_to_end(30000), &"", "the battle waits for the player")
	var hero: UnitState = stage.sim.waiting_hero()
	check(hero != null and stage.hud.menu.is_open(), "the menu opens when a hero waits")
	check_eq(_button_ids(stage.hud.menu.move_buttons(), "action_id"), hero.def.actions, "only that hero's moves")
	check(GameState.flags.get(&"tip_command_seen", false), "the command tip was shown once")
	check(not stage.hud.tip_text().is_empty(), "the tip text is on screen")
	var strike: ActionDef = stage.sim.actions[&"jambiyah_strike"]
	stage.hud.menu.move_buttons()[0].pressed.emit()
	check_eq(_button_ids(stage.hud.menu.target_buttons(), "unit_id"), _ids(stage.sim.valid_targets(hero, strike)),
		"the picker lists exactly the valid targets")
	check_eq(stage.fighters.marker_target(), stage.sim.valid_targets(hero, strike)[0].unit_id, "marker on the first target")
	stage.hud.menu.back()
	check_eq(stage.hud.menu.move_buttons().size(), hero.def.actions.size(), "back returns to the moves")
	check_eq(stage.fighters.marker_target(), &"", "the marker hides on back")
	stage.free()


func test_confirm_calls_sim_choose() -> void:
	var stage: BattleStage = _stage(false)
	stage.run_to_end(30000)
	var hero: UnitState = stage.sim.waiting_hero()
	var before_ticks: int = stage.sim.ticks
	stage.hud.menu.move_buttons()[0].pressed.emit()
	stage.hud.menu.target_buttons()[0].pressed.emit()
	check(hero.phase == UnitState.Phase.CAST and hero.action != null, "sim.choose committed the hero")
	check(not stage.hud.menu.is_open(), "the menu closes after a choice")
	stage.run_to_end(30000)
	check(stage.sim.ticks > before_ticks, "the battle continues after the choice")
	check(stage.hud.menu.is_open() or stage.sim.result != &"", "and waits for the next hero or ends")
	stage.free()


func test_refusal_shows_a_notice() -> void:
	var stage: BattleStage = _stage(false)
	stage.run_to_end(30000)
	var hero: UnitState = stage.sim.waiting_hero()
	stage.hud.menu.move_buttons()[0].pressed.emit()
	stage.hud.menu.chosen.emit(stage.sim.actions[&"jambiyah_strike"], &"nobody")
	check(stage.sim.waiting_hero() == hero and stage.hud.menu.is_open(), "a bad target leaves the menu open")
	stage.free()


func test_intent_label_for_a_casting_enemy() -> void:
	var stage: BattleStage = _stage(true)
	var seen: StringName = &""
	for frame: int in 4000:
		stage.step_frame()
		for unit: UnitState in stage.sim.timeline.units:
			if unit.side == 1 and unit.phase == UnitState.Phase.CAST and unit.action != null and seen == &"":
				seen = unit.unit_id
				check_eq(stage.fighters.intent_text(unit.unit_id), BattleStyle.text(unit.action.name_key),
					"the casting enemy shows its move name")
		if seen != &"" and stage.sim.timeline.find(seen).phase != UnitState.Phase.CAST:
			break
	check(seen != &"", "an enemy cast at some point")
	check_eq(stage.fighters.intent_text(seen), "", "the intent label is gone once it acted or was interrupted")
	stage.free()


func test_end_panel_buttons() -> void:
	var stage: BattleStage = _stage(false)
	var ends: Array[StringName] = []
	stage.ended.connect(func(result: StringName) -> void: ends.append(result))
	stage.hud.show_end(&"defeat")
	check_eq(stage.hud.end_panel.buttons().size(), 2, "defeat offers retry and back")
	stage.hud.end_panel.buttons()[0].pressed.emit()
	stage.hud.end_panel.buttons()[1].pressed.emit()
	check_eq(ends, [&"retry"] as Array[StringName], "ended fires once, with retry")
	stage.free()
	var won: BattleStage = _stage(false)
	var wins: Array[StringName] = []
	won.ended.connect(func(result: StringName) -> void: wins.append(result))
	won.hud.show_end(&"victory")
	check_eq(won.hud.end_panel.buttons().size(), 1, "victory offers continue")
	won.hud.end_panel.buttons()[0].pressed.emit()
	check_eq(wins, [&"victory"] as Array[StringName], "continue ends with victory")
	won.free()
