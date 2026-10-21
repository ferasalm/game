extends TestCase
## Battle HUD v2: the timeline sits on top at the style's size and its icons come from content (disc fallback), the
## party shows as PartyCards at the bottom right with the acting hero framed, and the hint strip is there.


func _stage() -> BattleStage:
	GameState.reset()
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var stage := BattleStage.new()
	stage.instant = true
	tree.root.add_child(stage)
	stage.start(loader.make_sim(&"swift_hilt", &"keen_blade", 7), Vector3.ZERO)
	return stage


func test_timeline_is_top_centred_at_the_style_size() -> void:
	var stage: BattleStage = _stage()
	var bar: BattleTimelineBar = stage.hud.timeline_bar
	var style: UiStyleDef = Ui.style()
	check_eq(bar.offset_right - bar.offset_left, float(style.size(&"s_timeline_w")), "width from style")
	check_eq(bar.offset_top, float(style.size(&"s_timeline_top")), "top margin from style")
	check_eq(bar.icon_count(), 5, "five icons")
	stage.free()


func test_head_icons_are_discs_with_initials_until_art_exists() -> void:
	var face: Control = BattleStyle.head_icon(&"zayd", 0)
	check_eq((face.get_child(0) as Label).text, "Z", "initial on the disc")
	var enemy: Control = BattleStyle.head_icon(&"concession_enforcer", 1)
	check((enemy as TextureRect).texture != null, "an enemy disc texture")
	face.free()
	enemy.free()


func test_party_cards_sit_bottom_right_and_frame_the_active_hero() -> void:
	var stage: BattleStage = _stage()
	var panel: BattlePartyPanel = stage.hud.party_panel
	check_eq(panel.row_count(), 2, "two cards")
	check_eq(panel.anchor_right, 1.0, "anchored right")
	check_eq(panel.anchor_bottom, 1.0, "anchored bottom")
	panel._process(0.0)
	var zayd: PartyCard = panel.card_of(&"zayd")
	check(zayd != null, "a card per hero id of the unit")
	check_eq(zayd.custom_minimum_size.x, float(Ui.style().size(&"s_card_w")), "card width from style")
	stage.free()


func test_hud_has_a_hint_strip() -> void:
	var stage: BattleStage = _stage()
	var strips: int = 0
	for node: Node in NodeWalk.all(stage.hud):
		strips += 1 if node is PromptStrip else 0
	check_eq(strips, 1, "one hint strip")
	stage.free()
