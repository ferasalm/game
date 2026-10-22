extends TestCase
## Battle HUD v3: at rest only a thin timeline and a slim strip under each hero; a hero's turn adds a card and a compact
## menu beside them; pointing shows an info card that fades; targeting names the target on the top bar; hits pulse a
## hero's strip and reveal a foe's; and at 1920x1080 nothing the HUD draws at rest covers a fighter.

const SCREEN: Vector2i = Vector2i(1920, 1080)


func _stage(auto: bool = false) -> BattleStage:
	GameState.reset()
	tree.root.size = SCREEN
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var stage := BattleStage.new()
	stage.instant = true
	stage.auto_play = auto
	tree.root.add_child(stage)
	stage.start(loader.make_sim(&"swift_hilt", &"keen_blade", 7), Vector3.ZERO)
	stage.hud.refresh(0.0, Vector2(-100.0, -100.0))
	return stage


func _view() -> BattleViewDef:
	return ContentDB.get_def("battle_view", &"default") as BattleViewDef


## The stage at the first hero's turn (the menu open, the HUD refreshed).
func _at_turn() -> BattleStage:
	var stage: BattleStage = _stage()
	stage.run_to_end(30000)
	stage.hud.refresh(0.0, Vector2(-100.0, -100.0))
	return stage


func test_resting_hud_is_a_thin_bar_and_two_strips() -> void:
	var stage: BattleStage = _stage()
	var view: BattleViewDef = _view()
	check_eq(Vector2i(stage.hud.get_viewport().get_visible_rect().size), SCREEN, "the test screen is 1920x1080")
	check(stage.hud.timeline_bar.height() <= SCREEN.y * 0.06, "the bar is at most 6%% of the height")
	check(not stage.hud.turn_panel.visible, "no turn panel at rest")
	check(not stage.hud.info_card.visible, "no info card at rest")
	check(not stage.hud.notices.hints_visible(), "no key hints at rest")
	for hero: StringName in [&"zayd", &"bilqis"]:
		var strip: BattleUnitStrip = stage.hud.strips.strip_of(hero)
		check(strip.visible and strip.size.x <= 170.0 and strip.size.y <= 20.0, "%s's strip is at most 170x20" % hero)
		check(strip.has_sp_bar(), "a hero's strip carries HP and SP")
		check(strip.position.y >= stage.hud.fighter_rects[hero].end.y, "%s's strip sits below the feet" % hero)
	check_eq(stage.hud.strips.visible_rects().size(), 2, "only the two hero strips show")
	check(not stage.hud.strips.shown(&"concession_enforcer_1"), "no foe strip at rest")
	check(view.strip_w <= 170 and view.strip_h <= 20, "the content sizes obey the same limits")
	stage.free()


## The rule: at rest no HUD control's rect overlaps any fighter's projected screen rect.
func test_nothing_at_rest_covers_a_fighter() -> void:
	var stage: BattleStage = _stage()
	check_eq(stage.hud.fighter_rects.size(), 5, "five fighter rects")
	for unit_id: StringName in stage.hud.fighter_rects:
		check(stage.hud.fighter_rects[unit_id].get_area() > 0.0, "%s has a screen rect" % unit_id)
	var hud_rects: Array[Rect2] = stage.hud.visible_rects()
	check(hud_rects.size() >= 7, "the track, five icons and strips are counted: %d" % hud_rects.size())
	var covered: float = HudLayout.overlap_area(Rect2(), [] as Array[Rect2])
	for rect: Rect2 in hud_rects:
		covered += HudLayout.overlap_area(rect, _all(stage))
	check_eq(covered, 0.0, "no HUD rect covers any fighter at rest")
	stage.free()


func test_fighter_rect_holds_the_feet_and_the_head() -> void:
	var stage: BattleStage = _stage()
	var rect: Rect2 = stage.hud.rects.of(&"zayd")
	var visual: CharacterVisual = stage.fighters.visual(&"zayd")
	for anchor: StringName in [&"feet", &"head"]:
		var point: Vector2 = stage.camera.unproject_position(visual.anchor_position(anchor))
		check(rect.has_point(point), "the rect holds the %s at %s" % [anchor, point])
	stage.free()


func test_turn_panel_sits_beside_the_hero_and_stays_small() -> void:
	var stage: BattleStage = _at_turn()
	var panel: BattleTurnPanel = stage.hud.turn_panel
	check(panel.visible and stage.hud.menu.is_open(), "the panel shows on the hero's turn")
	check(panel.size.x <= SCREEN.x * 0.22, "at most 22%% of the width: %s" % panel.size.x)
	check(panel.size.y <= SCREEN.y * 0.35, "at most 35%% of the height: %s" % panel.size.y)
	check_eq(panel.card.hero_id(), stage.sim.waiting_hero().unit_id, "the acting hero's card")
	check_eq(HudLayout.overlap_area(panel.rect(), _all(stage)), 0.0, "no fighter is covered")
	check(stage.hud.notices.hints_visible(), "the key hints show while a menu is open")
	check(stage.hud.menu.move_buttons()[0].has_focus(), "the first move has the focus (keyboard and gamepad work)")
	stage.free()


func test_the_turn_panel_goes_away_with_the_menu() -> void:
	var stage: BattleStage = _at_turn()
	stage.hud.close_menu()
	stage.hud.refresh(0.0, Vector2(-100.0, -100.0))
	check(not stage.hud.turn_panel.visible, "the panel hides with the menu")
	check(not stage.hud.notices.hints_visible(), "and so do the hints")
	stage.free()


func test_pointing_shows_an_info_card_that_fades() -> void:
	var stage: BattleStage = _stage()
	var view: BattleViewDef = _view()
	var foe: Rect2 = stage.hud.fighter_rects[&"concession_enforcer_1"]
	stage.hud.refresh(0.0, foe.get_center())
	check_eq(stage.hud.info_card.shown_unit(), &"concession_enforcer_1", "the mouse over a foe points at it")
	check(stage.hud.info_card.vitals.name_text().begins_with(Ui.text("NAME_CONCESSION_ENFORCER")), "its name: %s" % stage.hud.info_card.vitals.name_text())
	check(not stage.hud.info_card.vitals.has_sp_row(), "a foe's card has no SP row")
	check_eq(HudLayout.overlap_area(stage.hud.info_card.get_global_rect(), _others(stage, &"concession_enforcer_1")), 0.0, "the card covers no other fighter")
	stage.hud.refresh(view.info_delay * 0.5, Vector2(-100.0, -100.0))
	check(stage.hud.info_card.visible and stage.hud.info_card.modulate.a == 1.0, "it stays within the delay")
	stage.hud.refresh(view.info_delay * 0.5 + view.info_fade * 0.5, Vector2(-100.0, -100.0))
	check(stage.hud.info_card.visible and stage.hud.info_card.modulate.a < 1.0, "then it fades")
	stage.hud.refresh(view.info_fade, Vector2(-100.0, -100.0))
	check(not stage.hud.info_card.visible, "and is gone")
	var hero: Rect2 = stage.hud.fighter_rects[&"zayd"]
	stage.hud.refresh(0.0, hero.get_center())
	check(stage.hud.info_card.vitals.has_sp_row(), "a hero's card shows SP too")
	check_eq(stage.hud.info_card.vitals.hp_text(), "400/400", "and HP with numbers")
	stage.free()


func _all(stage: BattleStage) -> Array[Rect2]:
	var out: Array[Rect2] = []
	out.assign(stage.hud.fighter_rects.values())
	return out


func _others(stage: BattleStage, unit_id: StringName) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for id: StringName in stage.hud.fighter_rects:
		if id != unit_id:
			out.append(stage.hud.fighter_rects[id])
	return out


func test_targeting_names_the_target_on_the_top_bar() -> void:
	var stage: BattleStage = _at_turn()
	stage.hud.menu.move_buttons()[0].pressed.emit()
	var buttons: Array[Button] = stage.hud.menu.target_buttons()
	check(buttons.size() >= 2, "two foes to pick from")
	buttons[1].grab_focus()
	stage.hud.refresh(0.0, Vector2(-100.0, -100.0))
	var picked: StringName = buttons[1].get_meta("unit_id")
	var unit: UnitState = stage.sim.timeline.find(picked)
	var expected: String = Ui.text("BATTLE_TARGET") % BattleStyle.unit_name(stage.sim, unit)
	check_eq(stage.hud.timeline_bar.target_text(), expected, "the top bar reads the target's name")
	check(stage.hud.timeline_bar.target_text().ends_with("B"), "a letter tells the two Enforcers apart: %s" % expected)
	check(stage.hud.timeline_bar.is_ringed(picked), "its timeline icon is ringed")
	check(not stage.hud.timeline_bar.is_ringed(buttons[0].get_meta("unit_id")), "and only that one")
	check_eq(stage.hud.info_card.shown_unit(), picked, "the focus counts as pointing: the info card follows")
	stage.hud.menu.back()
	check_eq(stage.hud.timeline_bar.target_text(), "", "leaving the picker clears the top bar")
	stage.free()


func test_same_kind_foes_get_letters_everywhere() -> void:
	var stage: BattleStage = _stage()
	check_eq(stage.fighters.letter_text(&"concession_enforcer_1"), "A", "world label A")
	check_eq(stage.fighters.letter_text(&"concession_enforcer_2"), "B", "world label B")
	check_eq(stage.fighters.letter_text(&"survey_drone_1"), "", "a lone drone has no letter")
	check_eq(stage.fighters.letter_text(&"zayd"), "", "nor a lone hero")
	var second: UnitState = stage.sim.timeline.find(&"concession_enforcer_2")
	check(BattleStyle.unit_name(stage.sim, second).ends_with(" B"), "the name carries the letter: %s" % BattleStyle.unit_name(stage.sim, second))
	check(stage.hud.strips.strip_of(&"concession_enforcer_2") != null, "a foe strip exists for each foe")
	stage.free()


func test_a_hit_pulses_a_hero_strip_and_reveals_a_foe_strip() -> void:
	var stage: BattleStage = _stage()
	var view: BattleViewDef = _view()
	var strip: BattleUnitStrip = stage.hud.strips.strip_of(&"zayd")
	check(not strip.pulsing(), "calm before the hit")
	stage.shown_hp[&"zayd"] -= 50
	stage.shown_hp[&"concession_enforcer_1"] -= 50
	stage.hud.refresh(0.016, Vector2(-100.0, -100.0))
	check(strip.pulsing(), "a hit hero's strip pulses")
	check_eq(strip.hp_value(), float(stage.shown_hp[&"zayd"]), "and shows the new HP")
	check(stage.hud.strips.shown(&"concession_enforcer_1"), "a hit foe's HP strip appears")
	check(not stage.hud.strips.shown(&"concession_enforcer_2"), "an untouched foe's does not")
	stage.hud.refresh(view.foe_strip_seconds + view.strip_fade + 0.1, Vector2(-100.0, -100.0))
	check(not stage.hud.strips.shown(&"concession_enforcer_1"), "it fades after the data delay")
	stage.free()


func test_banner_and_end_panel_are_compact() -> void:
	var stage: BattleStage = _stage()
	var view: BattleViewDef = _view()
	check(view.end_panel_w <= SCREEN.x * 0.25, "the end panel is narrow")
	stage.hud.show_banner("Test")
	check_eq(stage.hud.banner_text(), "Test", "the banner still shows")
	stage.hud.show_end(&"defeat")
	stage.hud.refresh(0.0, Vector2(-100.0, -100.0))
	check(stage.hud.end_panel.visible, "the end panel still shows")
	check(stage.hud.end_panel.size.x <= SCREEN.x * 0.3, "at a compact width: %s" % stage.hud.end_panel.size.x)
	check(not stage.hud.turn_panel.visible, "with no turn panel behind it")
	stage.free()
