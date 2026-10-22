extends TestCase
## Battle HUD v2 basics (kept in v3): the thin timeline sits on top at the view's size and its icons come from content
## (disc fallback), each hero has a strip and the acting hero a card, and the hint strip is there.


func _stage() -> BattleStage:
	GameState.reset()
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var stage := BattleStage.new()
	stage.instant = true
	tree.root.add_child(stage)
	stage.start(loader.make_sim(&"swift_hilt", &"keen_blade", 7), Vector3.ZERO)
	return stage


func test_timeline_is_a_thin_top_bar_at_the_views_size() -> void:
	var stage: BattleStage = _stage()
	var bar: BattleTimelineBar = stage.hud.timeline_bar
	var view := ContentDB.get_def("battle_view", &"default") as BattleViewDef
	check_eq(bar.anchor_right, 1.0, "the bar spans the screen's width")
	check_eq(bar.anchor_top, 0.0, "and sits on top")
	check_eq(bar.height(), float(view.timeline_top + view.timeline_icon * 2 + view.timeline_track), "height from the view")
	check(bar.height() <= 1080.0 * 0.06, "at most 6%% of a 1080 px screen: %s" % bar.height())
	check_eq(bar.icon_count(), 5, "five icons")
	stage.free()


func test_head_icons_are_discs_with_initials_until_art_exists() -> void:
	var face: Control = BattleStyle.head_icon(&"zayd", 0)
	check_eq((face.get_child(0) as Label).text, "Z", "initial on the disc")
	var enemy: Control = BattleStyle.head_icon(&"concession_enforcer", 1)
	check((enemy as TextureRect).texture != null, "an enemy disc texture")
	face.free()
	enemy.free()


func test_heroes_have_a_strip_and_the_acting_hero_a_card() -> void:
	var stage: BattleStage = _stage()
	check(stage.hud.strips.strip_of(&"zayd") != null, "a strip per hero id of the unit")
	stage.run_to_end(30000)
	stage.hud.refresh(0.0)
	var card: BattleHeroCard = stage.hud.turn_panel.card
	check_eq(card.hero_id(), stage.sim.waiting_hero().unit_id, "the card shows the waiting hero")
	stage.free()


func test_hud_has_a_hint_strip() -> void:
	var stage: BattleStage = _stage()
	var strips: int = 0
	for node: Node in NodeWalk.all(stage.hud):
		strips += 1 if node is PromptStrip else 0
	check_eq(strips, 1, "one hint strip")
	stage.free()
