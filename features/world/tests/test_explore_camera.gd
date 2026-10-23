extends TestCase
## ExploreCamera on the rooftop: follow offset, the vista pose inside the zone (lower pitch, eases back out), the
## opening shot (keyframes, frozen actors, skip by key, ends on the exploring pose) and the DoF scale.


func _make() -> Rooftop:
	var rig := ContentDB.get_def("camera_rig", &"explore") as CameraRigDef
	if rig != null:
		rig.mode = &"fixed"
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	rooftop.area_id = &"souq_rooftops"
	rooftop.look_id = &"night"  # the plain follow camera; the painted look and its limits have their own tests
	tree.root.add_child(rooftop)
	return rooftop


func teardown() -> void:
	var rig := ContentDB.get_def("camera_rig", &"explore") as CameraRigDef
	if rig != null:
		rig.mode = &"follow"


func _run(rooftop: Rooftop, seconds: float) -> void:
	for i: int in roundi(seconds * 60.0):
		rooftop._process(1.0 / 60.0)


## The camera follows the player clamped into the rig's limits.
func _subject(rooftop: Rooftop) -> Vector3:
	var rig := ContentDB.get_def("camera_rig", &"explore") as CameraRigDef
	return CameraLimits.clamp_target(rooftop.player.position, rig.limit_x, rig.limit_z)


func _pitch(camera: Camera3D) -> float:
	return -camera.rotation_degrees.x


func test_exploring_camera_is_lower_than_v1() -> void:
	var rooftop: Rooftop = _make()
	_run(rooftop, 2.0)
	var pitch: float = _pitch(rooftop.camera)
	check(pitch > 24.0 and pitch < 29.0, "about 25-28 degrees down (%.1f)" % pitch)
	rooftop.free()


func test_vista_zone_lowers_the_pitch_and_eases_back() -> void:
	var rooftop: Rooftop = _make()
	_run(rooftop, 2.0)
	var explore_pitch: float = _pitch(rooftop.camera)
	var zone: Rect2 = (ContentDB.get_def("area", &"souq_rooftops") as AreaDef).vista_world()
	rooftop.player.position = Vector3(zone.get_center().x, rooftop.player.position.y, zone.get_center().y)
	_run(rooftop, 4.0)
	check(rooftop.camera_rig.vista_amount() > 0.95, "fully in the vista pose after a few seconds")
	check(_pitch(rooftop.camera) < explore_pitch - 15.0, "the camera looks up much flatter (%.1f vs %.1f)" % [
		_pitch(rooftop.camera), explore_pitch])
	rooftop.player.position = Vector3(10.5, rooftop.player.position.y, 12.5)
	_run(rooftop, 4.0)
	check(rooftop.camera_rig.vista_amount() < 0.05, "back to the exploring pose after leaving")
	check(absf(_pitch(rooftop.camera) - explore_pitch) < 1.0, "the same pitch as before")
	rooftop.free()


func test_intro_plays_freezes_actors_and_ends_on_the_exploring_pose() -> void:
	var rooftop: Rooftop = _make()
	var finished: Array = []
	rooftop.camera_rig.intro_finished.connect(func() -> void: finished.append(true))
	rooftop.play_intro()
	check(rooftop.camera_rig.is_intro_playing(), "the intro plays")
	check_eq(rooftop.player.process_mode, Node.PROCESS_MODE_DISABLED, "Zayd stands frozen")
	check(rooftop.player.visible, "but stays visible")
	check(rooftop.camera.rotation_degrees.x > 5.0, "the opening frame looks up at the sky")
	_run(rooftop, 3.0)
	check(rooftop.camera_rig.is_intro_playing(), "still playing after 3 s")
	var dof: float = (rooftop.camera.attributes as CameraAttributesPractical).dof_blur_amount
	check(dof < 0.1, "depth-of-field is eased down for the sky (%.3f)" % dof)
	_run(rooftop, 4.0)
	check(not rooftop.camera_rig.is_intro_playing() and finished.size() == 1, "ended once after its duration")
	check_eq(rooftop.player.process_mode, Node.PROCESS_MODE_INHERIT, "Zayd can walk again")
	var look := ContentDB.get_def("look", &"night") as LookDef
	var want: Vector3 = _subject(rooftop) + look.camera_offset
	check(rooftop.camera.position.distance_to(want) < 0.1, "the shot ends on the exploring pose")
	check(is_equal_approx(rooftop.camera.fov, look.fov), "with the look's field of view")
	rooftop.free()


func test_any_key_or_click_skips_the_intro() -> void:
	var rooftop: Rooftop = _make()
	rooftop.play_intro()
	_run(rooftop, 1.0)
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	rooftop.camera_rig._unhandled_input(key)
	check(not rooftop.camera_rig.is_intro_playing(), "a key press skips it")
	check_eq(rooftop.player.process_mode, Node.PROCESS_MODE_INHERIT, "actors are released")
	_run(rooftop, 2.0)
	var look := ContentDB.get_def("look", &"night") as LookDef
	check(rooftop.camera.position.distance_to(_subject(rooftop) + look.camera_offset) < 0.1,
		"the camera eases to the exploring pose after a skip")
	rooftop.free()
	var other: Rooftop = _make()
	other.play_intro()
	var click := InputEventMouseButton.new()
	click.pressed = true
	other.camera_rig._unhandled_input(click)
	check(not other.camera_rig.is_intro_playing(), "a click skips it")
	other.free()


func test_releasing_a_key_or_echo_does_not_skip() -> void:
	var rooftop: Rooftop = _make()
	rooftop.play_intro()
	var release := InputEventKey.new()
	release.keycode = KEY_A
	rooftop.camera_rig._unhandled_input(release)
	var echo := InputEventKey.new()
	echo.keycode = KEY_A
	echo.pressed = true
	echo.echo = true
	rooftop.camera_rig._unhandled_input(echo)
	check(rooftop.camera_rig.is_intro_playing(), "release and key repeat leave the shot running")
	rooftop.free()


func test_battle_start_ends_the_intro_at_once() -> void:
	var rooftop: Rooftop = _make()
	rooftop.play_intro()
	rooftop.set_exploring(false)
	check(not rooftop.camera_rig.is_intro_playing(), "set_exploring(false) ends the shot")
	rooftop.set_exploring(true)
	check_eq(rooftop.player.process_mode, Node.PROCESS_MODE_INHERIT, "actors run when exploring resumes")
	rooftop.free()
