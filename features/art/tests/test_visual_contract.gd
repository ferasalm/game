extends TestCase
## The CharacterVisual contract: play(state, facing), the anchors, clip events, the pixel and puppet sources behind
## the facade, and the pulse flag that switches the whole-body squash off for puppets.


func _visual() -> CharacterVisual:
	var visual := CharacterVisual.new()
	tree.root.add_child(visual)
	visual.set_sprite(&"zayd")
	return visual


func test_play_walk_run_idle_and_ko() -> void:
	var visual: CharacterVisual = _visual()
	visual.play(&"walk", Vector2.RIGHT)
	for i: int in 30:
		visual._process(0.016)
	check(visual.body.scale.y != 1.0, "walk squashes and stretches")
	check_eq(visual.state, &"walk", "state is kept")
	visual.play(&"idle")
	check(not visual._moving, "idle stops the walk")
	visual.play(&"ko")
	check(visual.is_down(), "ko puts the character down")
	visual.play(&"run", Vector2.LEFT)
	check(not visual.is_down(), "moving again stands them up")
	visual.free()


func test_every_state_is_accepted() -> void:
	var visual: CharacterVisual = _visual()
	for state: StringName in CharacterVisual.STATES:
		visual.play(state, Vector2.RIGHT)
		check_eq(visual.state, state, "state %s accepted" % state)
	visual.free()


func test_facing_flips_and_zero_keeps_it() -> void:
	var visual: CharacterVisual = _visual()
	visual.play(&"idle", Vector2.LEFT)
	check_eq(visual.material.get_shader_parameter(&"flip"), -1.0, "left mirrors the art")
	visual.play(&"idle", Vector2.ZERO)
	check_eq(visual.material.get_shader_parameter(&"flip"), -1.0, "zero keeps the facing")
	visual.free()


func test_anchors() -> void:
	var visual: CharacterVisual = _visual()
	visual.position = Vector3(2.0, 0.0, 1.0)
	visual.play(&"idle", Vector2.RIGHT)
	check_eq(visual.anchor_position(&"feet"), visual.global_position, "feet are the origin")
	check(is_equal_approx(visual.anchor_position(&"head").y, visual.height()), "head is the sprite height")
	var hand: Vector3 = visual.anchor_position(&"hand")
	check(hand.x > visual.global_position.x and hand.y > 0.0 and hand.y < visual.height(), "hand is forward, mid-height")
	visual.play(&"idle", Vector2.LEFT)
	check(visual.anchor_position(&"hand").x < visual.global_position.x, "and follows the facing")
	visual.free()


func test_clip_events_reach_the_facade() -> void:
	var visual: CharacterVisual = _visual()
	var seen: Array[StringName] = []
	visual.clip_event.connect(func(event: StringName) -> void: seen.append(event))
	visual.source.clip_event.emit(&"impact")
	check_eq(seen, [&"impact"] as Array[StringName], "the source's event arrives on the facade")
	visual.free()


func test_clip_timing_comes_from_the_rules() -> void:
	var rules := ContentDB.get_def("visual_rules", &"default") as VisualRulesDef
	var attack: Vector2 = PixelSource.clip_times(&"attack", rules)
	check(attack.x > 0.0 and attack.y > attack.x, "the hit lands before the clip ends")
	check_eq(PixelSource.clip_times(&"hurt", rules).x, 0.0, "a hurt impact is at once")
	check_eq(PixelSource.clip_times(&"idle", rules), Vector2(-1.0, -1.0), "idle is not a clip")


func test_pulse_flag_turns_the_squash_off() -> void:
	var visual: CharacterVisual = _visual()
	var before: int = tree.get_processed_tweens().size()
	visual.source.cue(&"dash")
	check(tree.get_processed_tweens().size() > before, "pixel characters squash")
	visual.rules.pulse_squash = false
	before = tree.get_processed_tweens().size()
	visual.source.cue(&"dash")
	check_eq(tree.get_processed_tweens().size(), before, "no squash tween when the flag is off")
	visual.rules.pulse_squash = true
	visual.free()


func test_puppet_stub_is_a_valid_empty_character() -> void:
	var visual := CharacterVisual.new()
	visual.use_source(PuppetSource.new())
	tree.root.add_child(visual)
	check(visual.material == null, "a puppet has no pixel material")
	visual.set_sprite(&"zayd")
	for state: StringName in CharacterVisual.STATES:
		visual.play(state, Vector2.LEFT)
	visual._process(0.016)
	check_eq(visual.height(), 0.0, "nothing drawn yet")
	check_eq(visual.anchor_position(&"head"), visual.global_position, "anchors collapse to the feet")
	visual.free()


func test_rules_def_reads_the_puppet_flags() -> void:
	var rules := ContentDB.get_def("visual_rules", &"default") as VisualRulesDef
	check(not rules.puppet and rules.pulse_squash, "pixel characters squash")
