extends TestCase
## The battle view is ready for 3D models: it waits on the actor's clip events (never a timer), faces by direction with
## a lean toward the camera and never a negative scale, freezes both fighters at impact, places effects, numbers and
## markers from the characters' anchors, spaces lunges by width, plays the ko state, and keeps SceneTreeTimers out.


func _stage() -> BattleStage:
	var loader: BattleLoader = BattleLoader.from_db(ContentDB)
	var stage := BattleStage.new()
	stage.instant = true
	tree.root.add_child(stage)
	stage.start(loader.make_sim(&"swift_hilt", &"keen_blade", 7, 0), Vector3.ZERO)
	return stage


func _fake(stage: BattleStage, unit_id: StringName) -> FakeClipSource:
	var source := FakeClipSource.new()
	stage.fighters.visual(unit_id).use_source(source)
	return source


func _wait_of(host: Node) -> PauseWait:
	for child: Node in host.get_children():
		if child is PauseWait:
			return child
	return null


func test_a_move_waits_on_the_clip_impact_not_a_timer() -> void:
	var stage: BattleStage = _stage()
	var source: FakeClipSource = _fake(stage, &"zayd")
	var actor: CharacterVisual = stage.fighters.visual(&"zayd")
	var strike: ActionDef = stage.sim.actions[&"djanbeyyah_strike"]
	stage._actions.begin(&"zayd", strike, [&"concession_enforcer_1"] as Array[StringName])
	check(stage._actions.is_waiting_for_impact(), "the move waits for the impact event")
	check_eq(source.clips, [&"attack"] as Array[StringName], "the actor plays its attack clip")
	check_eq(stage.vfx.active_count(), 1, "no effect has played yet (only the warm-up sprite)")
	actor.clip_event.emit(&"end")
	check(stage._actions.is_waiting_for_impact(), "another event does not end the wait")
	actor.clip_event.emit(&"impact")
	check(not stage._actions.is_waiting_for_impact(), "the impact event ends it")
	check(stage.vfx.active_count() > 1, "and the effect plays then")
	stage.free()


func test_a_source_that_sends_nothing_cannot_hang_the_fight() -> void:
	var stage: BattleStage = _stage()
	_fake(stage, &"zayd")
	var strike: ActionDef = stage.sim.actions[&"djanbeyyah_strike"]
	stage._actions.begin(&"zayd", strike, [&"concession_enforcer_1"] as Array[StringName])
	var wait: PauseWait = _wait_of(stage._actions)
	check(wait != null, "a pause-safe timeout guards the wait")
	wait._process(stage.juice.def.clip_timeout + 0.1)
	check(not stage._actions.is_waiting_for_impact(), "after the limit the move goes on")
	stage.free()


func test_facing_leans_to_the_camera_and_never_scales_negative() -> void:
	var stage: BattleStage = _stage()
	var source: FakeClipSource = _fake(stage, &"zayd")
	stage.fighters.face_foes(&"zayd")
	check(source.faces[-1].x < 0.0 and source.faces[-1].z > 0.0, "the party faces left and toward the camera")
	stage.fighters.face_foes(&"zayd", true)
	check(source.faces[-1].x > 0.0, "turning away faces right")
	for unit: UnitState in stage.sim.timeline.units:
		var visual: CharacterVisual = stage.fighters.visual(unit.unit_id)
		for node: Node3D in [visual, visual.root, visual.body]:
			check(node.scale.x > 0.0 and node.scale.y > 0.0 and node.scale.z > 0.0,
				"%s: no negative scale on %s" % [unit.unit_id, node.name])
	stage.free()


func test_both_fighters_freeze_at_impact() -> void:
	var stage: BattleStage = _stage()
	var hit: FakeClipSource = _fake(stage, &"concession_enforcer_1")
	var swing: FakeClipSource = _fake(stage, &"zayd")
	var strike: ActionDef = stage.sim.actions[&"djanbeyyah_strike"]
	stage._actions.begin(&"zayd", strike, [&"concession_enforcer_1"] as Array[StringName])
	stage.fighters.visual(&"zayd").clip_event.emit(&"impact")
	stage._actions.on_hit(stage.fighters.visual(&"concession_enforcer_1"), 5)
	check_eq(hit.pauses, [stage.juice.def.hit_pause] as Array[float], "the target pauses for the light hit")
	check_eq(swing.pauses, [stage.juice.def.hit_pause] as Array[float], "so does the attacker")
	check(hit.clips.has(&"hurt"), "and the target plays its hurt clip")
	stage._actions.on_hit(stage.fighters.visual(&"concession_enforcer_1"), stage.juice.def.heavy_damage)
	check_eq(hit.pauses[-1], stage.juice.def.hit_pause_heavy, "a heavy hit pauses longer")
	stage.free()


func test_effects_numbers_and_markers_come_from_anchors() -> void:
	var stage: BattleStage = _stage()
	var source: FakeClipSource = _fake(stage, &"zayd")
	source.size = Vector2(1.0, 2.5)
	var zayd: CharacterVisual = stage.fighters.visual(&"zayd")
	var foe: CharacterVisual = stage.fighters.visual(&"concession_enforcer_1")
	var head: Vector3 = zayd.anchor_position(&"head")
	check(is_equal_approx(head.y - zayd.global_position.y, 2.5), "the head anchor is the model's height")
	check_eq(stage.vfx._point(&"hand", zayd, zayd, foe), zayd.anchor_position(&"hand"), "the hand anchor of the actor")
	check(is_equal_approx(stage.vfx._middle(zayd).y - zayd.global_position.y, 1.25), "the middle is between feet and head")
	stage.fighters.point_at(&"zayd")
	check(stage.fighters._marker.position.y > head.y, "the marker floats above the anchor head, not a sprite height")
	stage.free()


func test_lunge_spacing_comes_from_widths() -> void:
	var stage: BattleStage = _stage()
	var source: FakeClipSource = _fake(stage, &"zayd")
	var foe_source: FakeClipSource = _fake(stage, &"concession_enforcer_1")
	source.size = Vector2(1.0, 1.8)
	foe_source.size = Vector2(1.4, 1.8)
	var zayd: CharacterVisual = stage.fighters.visual(&"zayd")
	var foe: CharacterVisual = stage.fighters.visual(&"concession_enforcer_1")
	zayd.global_position = Vector3(5.0, 0.0, 0.0)
	foe.global_position = Vector3(2.0, 0.0, 0.0)
	var gap: float = 1.2 + stage.juice.def.contact_gap
	var spot: Vector3 = stage._actions._contact_spot(zayd, foe)
	check(is_equal_approx(spot.x, 2.0 + gap), "the lunge stops one half-width each (and the gap) short of the target")
	zayd.global_position = Vector3(2.5, 0.0, 0.0)
	check_eq(stage._actions._contact_spot(zayd, foe), zayd.global_position, "already in contact: it stays put")
	stage.free()


func test_ko_plays_the_ko_state_and_a_revive_stands_up() -> void:
	var stage: BattleStage = _stage()
	var source: FakeClipSource = _fake(stage, &"concession_enforcer_1")
	var victim: CharacterVisual = stage.fighters.visual(&"concession_enforcer_1")
	stage._player._skip = false
	stage._player._on_down(TimelineEvent.new(&"down", &"concession_enforcer_1"))
	check(victim.is_down() and victim.state == &"ko", "the ko state plays")
	check_eq(source.downs, [true] as Array[bool], "and the source collapses")
	stage._player._on_revived(TimelineEvent.new(&"revived", &"concession_enforcer_1"))
	check(not victim.is_down() and victim.state == &"idle", "a revive stands it back up")
	stage.free()


func test_the_battle_view_uses_no_scene_tree_timer() -> void:
	for file: String in ["battle_action_player", "battle_stage", "battle_fighters", "battle_event_player", "vfx_player"]:
		var text: String = FileAccess.get_file_as_string("res://features/combat/view/%s.gd" % file)
		check(not text.contains("create_timer"), "%s.gd has no create_timer (it keeps running during a pause)" % file)
