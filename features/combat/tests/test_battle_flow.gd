extends TestCase
## How a fight starts and ends: carried vitals fill the bars, the end panel shows the riyal, the shatter warp skips
## cleanly without a frame, the Defeat screen opens on a loss and its three picks leave the fight (retry, load, title).


func _dead_stage(auto: bool) -> BattleStage:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var stage := BattleStage.new()
	stage.instant = true
	stage.auto_play = auto
	tree.root.add_child(stage)
	stage.start(loader.make_sim(&"swift_hilt", &"keen_blade", 7, 0), Vector3.ZERO)
	return stage


func test_carried_vitals_fill_the_bars() -> void:
	var h := FlowHarness.new(tree)
	GameState.start_new()
	GameState.set_vitals({&"zayd": {"hp": 120, "sp": 5}})
	var main: PrototypeMain = h.make_main()
	h.touch(main)
	check_eq(main.stage.shown_hp[&"zayd"], 120, "the bar starts at the carried HP")
	check_eq(main.stage.sim.timeline.find(&"zayd").sp, 5, "and the carried SP")
	check_eq(main.stage.shown_hp[&"bilqis"], main.stage.sim.timeline.find(&"bilqis").def.max_hp, "a hero with no entry is full")
	main.free()
	h.finish()


func test_end_panel_shows_the_riyal_of_the_win_and_half_for_a_repeat() -> void:
	var h := FlowHarness.new(tree)
	GameState.start_new()
	var main: PrototypeMain = h.make_main()
	h.touch(main)
	main.stage.hud.show_end(&"victory")
	check_eq(main.stage.hud.end_panel.shown_money(), 70, "the first win lists 70 riyal")
	check(not GameState.flags.get(Rewards.paid_flag(&"rooftop_patrol"), false), "listing it pays and flags nothing yet")
	main.stage.ended.emit(&"victory")
	h.touch(main)
	main.rooftop.encounter_touched.emit(&"rooftop_patrol", false)
	main.stage.hud.show_end(&"victory")
	check_eq(main.stage.hud.end_panel.shown_money(), 35, "a repeat win lists half")
	main.stage.hud.show_end(&"defeat")
	check_eq(main.stage.hud.end_panel.shown_money(), 0, "a defeat lists no riyal")
	main.free()
	h.finish()


func test_shatter_skips_without_a_frame() -> void:
	check(not BattleShatter.can_play(null), "no frame, no shatter")
	check(not BattleShatter.can_play(Image.new()), "an empty image is no frame")
	var shatter := BattleShatter.new()
	tree.root.add_child(shatter)
	shatter.play(null, ContentDB.get_def("battle_juice", &"default") as JuiceDef)
	check(shatter.is_queued_for_deletion(), "play() with no frame frees itself at once")
	shatter.free()
	var stage: BattleStage = _dead_stage(true)
	stage.warp_frame = null
	check(stage.fighters.count() == 5, "a stage without a frame starts as usual")
	stage.free()


func test_shatter_material_carries_the_content_numbers() -> void:
	var juice := ContentDB.get_def("battle_juice", &"default") as JuiceDef
	var transition := ContentDB.get_def("transition", &"shatter") as TransitionDef
	var image := Image.create(160, 90, false, Image.FORMAT_RGBA8)
	var shatter := BattleShatter.new()
	var material: ShaderMaterial = shatter._make_material(image, juice, transition)
	shatter.free()
	check_eq(material.get_shader_parameter(&"fall"), juice.shatter_fall, "fall from juice.json")
	check_eq(material.get_shader_parameter(&"cells"), Vector2(juice.shatter_columns, juice.shatter_columns * 90.0 / 160.0),
		"cells follow the frame's aspect")
	check_eq(material.get_shader_parameter(&"crack_color"), transition.color, "crack colour from transitions.json")
	check(transition.seconds > 0.0, "and its time is content")


func test_a_loss_opens_the_defeat_screen_and_retry_ends_the_fight() -> void:
	var stage: BattleStage = _dead_stage(false)
	var ends: Array[StringName] = []
	stage.ended.connect(func(result: StringName) -> void: ends.append(result))
	stage.sim.result = &"defeat"
	stage._check_end()
	check(Screens.is_open_id(Screens.DEFEAT_ID), "the Defeat screen is up")
	check(not stage.hud.end_panel.visible, "the plain end panel stays hidden")
	Screens.top().close(&"retry")
	check_eq(ends, [&"retry"] as Array[StringName], "Retry fight ends the stage with retry")
	Screens.clear()
	stage.free()


func test_defeat_screen_picks_load_and_title_leave_the_fight() -> void:
	var h := FlowHarness.new(tree)
	GameState.start_new()
	check_eq(Router.save_slot(1), "", "a save exists")
	var main: PrototypeMain = h.make_main()
	h.touch(main)
	main.stage.ended.emit(&"load")
	check_eq(h.reloads, 1, "Load last save rebuilds the game from the slot")
	check(h.outcomes.is_empty(), "and the fight reports no outcome (the area is rebuilt)")
	main.free()
	var again: PrototypeMain = h.make_main()
	Router.state = Router.STATE_EXPLORING
	h.touch(again)
	again.stage.ended.emit(&"title")
	check_eq(h.reloads, 2, "Title rebuilds the game too")
	check_eq(Router.state, Router.STATE_TITLE, "at the title")
	again.free()
	h.finish()


func test_wash_leaves_only_on_victory_or_a_plain_defeat() -> void:
	check(BattleEnding.washes(&"victory") and BattleEnding.washes(&"defeat"), "victory and defeat wash")
	check(not BattleEnding.washes(&"retry") and not BattleEnding.washes(&"load") and not BattleEnding.washes(&"title"),
		"retry, load and title do not")
