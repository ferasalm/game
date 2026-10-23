extends TestCase
## Rooftop exploration systems: follower trailing, workshop prompt, camera restore and debug overlay.

const DT: float = 1.0 / 60.0


func _make() -> Rooftop:
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	rooftop.area_id = &"souq_rooftops"
	rooftop.look_id = &"night"
	tree.root.add_child(rooftop)
	return rooftop


func _rules() -> ExploreRulesDef:
	return ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef


func _walk(rooftop: Rooftop, action: String, frames: int) -> void:
	Input.action_press(action)
	for i: int in frames:
		rooftop.player._physics_process(DT)
		rooftop.follower._physics_process(DT)
	Input.action_release(action)


func test_follower_trails_at_the_follower_distance() -> void:
	var rooftop: Rooftop = _make()
	_walk(rooftop, "move_right", 60)
	for i: int in 90:
		rooftop.follower._physics_process(DT)
	var gap: float = rooftop.follower.position.distance_to(rooftop.player.position)
	check(absf(gap - _rules().follower_distance) < 0.15, "follower is %f behind" % gap)
	check(rooftop.follower.position.x < rooftop.player.position.x, "and behind, not ahead")
	rooftop.free()


func test_workshop_prompt_and_interact() -> void:
	var rooftop: Rooftop = _make()
	var opened: Array = []
	rooftop.workshop_opened.connect(func() -> void: opened.append(true))
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	rooftop.workshop._physics_process(DT)
	check(not rooftop.workshop.prompt.visible, "no prompt far from the bench")
	rooftop.workshop._unhandled_input(press)
	check(opened.is_empty(), "interact does nothing far away")
	rooftop.player.position = rooftop.workshop.position + Vector3(0.5, 0.0, 0.0)
	rooftop.workshop._physics_process(DT)
	check(rooftop.workshop.prompt.visible, "prompt shows near the bench")
	check_eq(rooftop.workshop.prompt.text, "E: workshop", "prompt text comes from the localization key")
	rooftop.workshop._unhandled_input(press)
	check_eq(opened.size(), 1, "interact near the bench opens the workshop")
	rooftop.free()


func test_camera_follows_and_can_be_restored() -> void:
	var rooftop: Rooftop = _make()
	rooftop.player.position = Vector3(10.5, rooftop.player.position.y, 8.5)
	for i: int in 60:
		rooftop._process(0.1)
	var look := ContentDB.get_def("look", &"night") as LookDef
	var want: Vector3 = rooftop.camera_rig._follow_cam.camera_position() if rooftop.camera_rig._mode == &"follow" else rooftop.player.position + look.camera_offset
	check(rooftop.camera.position.distance_to(want) < 0.05, "camera sits at the look offset from the player")
	var aim: Vector3 = rooftop.player.position + Vector3(0.0, rooftop.camera_rig._follow_cam.aim_height, 0.0)
	var dir: Vector3 = (aim - rooftop.camera.global_position).normalized()
	var forward: Vector3 = -rooftop.camera.global_transform.basis.z
	check(forward.dot(dir) > 0.99, "camera aims at focus + aim_height, not just camera_position()")
	var other := Camera3D.new()
	rooftop.add_child(other)
	other.make_current()
	check(not rooftop.camera.current, "another camera took over")
	rooftop.restore_camera()
	check(rooftop.camera.current, "restore_camera makes the follow camera current again")
	rooftop.free()


func test_debug_overlay_is_hidden_until_f3() -> void:
	var rooftop: Rooftop = _make()
	check(not rooftop._debug.visible, "players never see the FPS/debug overlay by default")
	var f3 := InputEventKey.new()
	f3.keycode = KEY_F3
	f3.pressed = true
	rooftop._debug._unhandled_key_input(f3)
	check(rooftop._debug.visible, "F3 shows it")
	rooftop._debug._unhandled_key_input(f3)
	check(not rooftop._debug.visible, "F3 again hides it")
	rooftop.free()
