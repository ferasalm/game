extends TestCase
## How a fight ends: the shatter warp skips cleanly without a frame, the Defeat screen opens on a loss and its
## picks leave the fight, and the wash follows the outcome.


func _dead_stage(auto: bool) -> BattleStage:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var stage := BattleStage.new()
	stage.instant = true
	stage.auto_play = auto
	tree.root.add_child(stage)
	stage.start(loader.make_sim(&"swift_hilt", &"keen_blade", 7, 0), Vector3.ZERO)
	return stage


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


func test_wash_leaves_only_on_victory_or_a_plain_defeat() -> void:
	check(BattleEnding.washes(&"victory") and BattleEnding.washes(&"defeat"), "victory and defeat wash")
	check(not BattleEnding.washes(&"retry") and not BattleEnding.washes(&"load") and not BattleEnding.washes(&"title"),
		"retry, load and title do not")
