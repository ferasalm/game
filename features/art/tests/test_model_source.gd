extends TestCase
## The live 3D source behind the CharacterVisual facade: the model is built and painted, clips announce impact and
## end on the retimed curve (and wait for the hit pause), the body turns by yaw and never by a negative scale, the
## feet pace the ground and sound a footstep on each foot contact, a knocked-out body stays down, the grandfather's hilt is drawn for a strike and sheathed after,
## and a CharacterVisual without a model def falls back to the pixel sprite.

const DT: float = 1.0 / 60.0


func _visual(id: StringName = &"rydan") -> CharacterVisual:
	var visual := CharacterVisual.new()
	visual.source_kind = &"model"
	tree.root.add_child(visual)
	visual.set_sprite(id)
	return visual


func _run(visual: CharacterVisual, seconds: float) -> void:
	for i: int in int(seconds / DT):
		visual._process(DT)


func test_a_model_builds_paints_and_sizes() -> void:
	var visual: CharacterVisual = _visual()
	var source := visual.source as ModelSource
	check(source != null and source.rig != null, "Zayd is a ModelSource with a rig")
	check_eq(visual.height(), 1.8, "height from the def")
	check(visual.width() > 0.4, "width from the def's radius")
	check(not source.materials().is_empty(), "painted materials exist")
	visual.free()


func test_no_negative_scale_anywhere() -> void:
	var visual: CharacterVisual = _visual()
	visual.face_dir(Vector3(-1.0, 0.0, 0.3))
	visual.play(&"idle", Vector2.LEFT)
	_run(visual, 0.3)
	var source := visual.source as ModelSource
	for node: Node3D in [visual.body, source.rig.model, source._holder]:
		check(node.scale.x > 0.0 and node.scale.y > 0.0 and node.scale.z > 0.0, "%s scale stays positive" % node.name)
	visual.free()


func test_facing_turns_by_yaw_at_the_turn_speed() -> void:
	var visual: CharacterVisual = _visual()
	var source := visual.source as ModelSource
	visual.face_dir(Vector3(0.0, 0.0, 1.0))
	_run(visual, 0.05)
	check(absf(source._holder.rotation.y) < 0.01, "facing the camera is yaw 0")
	visual.face_dir(Vector3(-1.0, 0.0, 0.0))
	_run(visual, 0.05)
	var turned: float = absf(wrapf(source._holder.rotation.y, -PI, PI))
	check(turned > 0.2 and turned < PI / 2.0 - 0.1, "a quick step toward the new facing, not a snap (%.2f)" % turned)
	_run(visual, 0.5)
	check(is_equal_approx(source._holder.rotation.y, -PI / 2.0), "then it faces -x")
	visual.free()


func test_attack_announces_impact_then_end_on_the_curve() -> void:
	var visual: CharacterVisual = _visual()
	var seen: Array[StringName] = []
	var times: Array[float] = []
	var clock: Array[float] = [0.0]
	visual.clip_event.connect(func(kind: StringName) -> void:
		seen.append(kind)
		times.append(clock[0]))
	visual.play(&"attack", Vector2.RIGHT)
	var clip := ContentDB.get_def("clip", &"sword_attack") as ClipDef
	for i: int in int((ClipTiming.total(clip) + 0.3) / DT):
		clock[0] += DT
		visual._process(DT)
	check_eq(seen, [&"impact", &"end"] as Array[StringName], "impact then end, once each")
	check(absf(times[0] - ClipTiming.real_at(clip, clip.impact_t)) < DT * 1.5, "impact on the curve (%.3f)" % times[0])
	check(absf(times[1] - ClipTiming.total(clip)) < DT * 1.5, "end after the whole retimed clip (%.3f)" % times[1])
	check(times[0] > 0.3, "the wind-up is slower than the raw clip: impact is not at its raw 0.40 s minus a bit")
	visual.free()


func test_hit_stop_freezes_the_pose_and_the_events() -> void:
	var visual: CharacterVisual = _visual()
	var source := visual.source as ModelSource
	visual.play(&"attack", Vector2.RIGHT)
	_run(visual, 0.1)
	var at: float = source.rig.player.current_animation_position
	visual.hit_stop(0.1)
	_run(visual, 0.08)
	check(is_equal_approx(source.rig.player.current_animation_position, at), "frozen: the pose does not move during the pause")
	_run(visual, 0.1)
	check(source.rig.player.current_animation_position > at, "then it runs on")
	visual.free()


func test_the_hilt_is_drawn_for_a_strike_and_sheathed_after() -> void:
	var visual: CharacterVisual = _visual()
	var hilt: HiltParts = (visual.source as ModelSource).rig.hilt
	check(hilt != null and not hilt.drawn, "Zayd carries the hilt sheathed at the belt")
	check(hilt.root.is_ancestor_of(hilt.hilt), "the hilt sits in the sheath at the belt")
	visual.play(&"attack", Vector2.RIGHT)
	check(hilt.drawn and hilt.blade.visible, "drawn: the blade shows")
	check(not hilt.root.is_ancestor_of(hilt.hilt), "in the hand")
	_run(visual, 3.0)
	check(not hilt.drawn and hilt.root.is_ancestor_of(hilt.hilt) and not hilt.blade.visible, "sheathed again at the end of the clip")
	var roya: CharacterVisual = _visual(&"roya")
	check((roya.source as ModelSource).rig.hilt == null, "only Rydan wears it")
	visual.free()
	roya.free()


func test_feet_pace_the_ground_and_gait_follows_speed() -> void:
	var visual: CharacterVisual = _visual()
	var source := visual.source as ModelSource
	visual.play(&"run", Vector2.RIGHT)
	for i: int in 90:
		visual.position.x += 3.5 * DT
		visual._process(DT)
	check(absf(source._move.speed - 3.5) < 0.2, "the speed is measured from the body's own movement (%.2f)" % source._move.speed)
	var clip: ClipDef = source._clips.current()
	check(clip != null and clip.id == &"run", "3.5 m/s runs")
	var expected: float = Locomotion.playback_rate(3.5, 3.6, clip.seconds, 0.5, 2.4)
	check(absf(source.rig.player.speed_scale - expected) < 0.05, "playback rate = speed / stride (%.2f vs %.2f)" % [source.rig.player.speed_scale, expected])
	visual.play(&"walk", Vector2.RIGHT)
	for i: int in 90:
		visual.position.x += 1.6 * DT
		visual._process(DT)
	check_eq((source._clips.current() as ClipDef).id, &"walk", "1.6 m/s walks")
	visual.play(&"idle")
	_run(visual, 1.0)
	check_eq((source._clips.current() as ClipDef).id, &"idle", "standing still idles")
	visual.free()


func test_footsteps_fall_on_the_foot_contacts_of_the_gait() -> void:
	var visual: CharacterVisual = _visual()
	var source := visual.source as ModelSource
	var steps: Array[StringName] = []
	visual.clip_event.connect(func(kind: StringName) -> void: if kind == &"footstep": steps.append(kind))
	visual.play(&"walk", Vector2.RIGHT)
	for i: int in 180:
		visual.position.x += 1.6 * DT
		visual._process(DT)
	var clip: ClipDef = source._clips.current()
	var expected: float = 3.0 * source.rig.player.speed_scale * clip.contacts.size() / clip.seconds
	check(steps.size() >= 3 and absf(steps.size() - expected) <= 1.5, "3 s of walking: one step per contact (%d, about %.1f)" % [steps.size(), expected])
	steps.clear()
	visual.play(&"idle")
	_run(visual, 2.0)
	check_eq(steps.size(), 0, "standing still makes no footsteps")
	visual.free()


func test_ko_stays_down_and_revive_stands_up() -> void:
	var visual: CharacterVisual = _visual()
	var source := visual.source as ModelSource
	visual.play(&"ko")
	_run(visual, 3.0)
	check(visual.is_down() and source._clips.current() == null, "knocked out: the ko clip is done and nothing replaces it")
	visual.play(&"idle")
	_run(visual, 0.3)
	check(not visual.is_down() and source._clips.current() != null, "idle stands them back up")
	visual.free()


func test_anchors() -> void:
	var visual: CharacterVisual = _visual()
	visual.face_dir(Vector3(1.0, 0.0, 0.0))
	_run(visual, 0.3)
	var hand: Vector3 = visual.source.anchor(&"hand")
	var head: Vector3 = visual.source.anchor(&"head")
	check(hand.y > 0.3 and hand.y < head.y, "the hand is between the feet and the head")
	check_eq(visual.source.anchor(&"feet"), Vector3.ZERO, "feet are the origin")
	visual.free()


func test_a_character_without_a_model_falls_back_to_the_pixel_sprite() -> void:
	var visual := CharacterVisual.new()
	visual.source_kind = &"model"
	tree.root.add_child(visual)
	visual.set_sprite(&"workshop_bench")
	check(visual.source is PixelSource, "no model def: the pixel sprite stays")
	check(visual.material != null, "with its own material")
	visual.free()
