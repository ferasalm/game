extends TestCase
## FollowCam tests: defaults, focus, lazy yaw, walk toward camera, manual orbit, zone blend, input rotation, arm shortening.


func test_follow_cam_defaults() -> void:
	var cam := FollowCam.new()
	check(is_equal_approx(cam.distance, 6.5), "default distance is 6.5 m")
	check(is_equal_approx(cam.pitch, deg_to_rad(28.0)), "default pitch is 28 deg")
	check(is_equal_approx(cam.fov, 50.0), "default fov is 50")
	var focus: Vector3 = FollowCam.compute_focus(Vector3(10.0, 0.0, 0.0), Vector3(0.0, 0.0, 10.0), 0.7, 0.3)
	check(focus.distance_to(Vector3(7.0, 0.0, 3.0)) < 0.01, "focus is player 0.7 + follower 0.3")
	cam.update(Vector3.ZERO, Vector3.ZERO, 0.0, 0.0, Vector3(0.0, 0.0, 1.0))
	var want_aim := Vector3(0.0, 1.2, -1.5)
	check(cam.aim.distance_to(want_aim) < 0.01, "aim = focus + 1.2 m up + 1.5 m into the view (yaw 0 looks along -z)")


func test_lazy_yaw_delay_and_rate() -> void:
	var cam := FollowCam.new()
	cam.yaw = 0.0
	for i: int in 42:
		cam.update(Vector3.ZERO, Vector3(1.0, 0.0, 0.0), 1.0 / 60.0)
	check(is_equal_approx(cam.yaw, 0.0), "yaw does not move before 0.8 s delay")
	for i: int in 60:
		cam.update(Vector3.ZERO, Vector3(1.0, 0.0, 0.0), 1.0 / 60.0)
	check(cam.yaw < -0.4 and cam.yaw > -0.8, "yaw eases at max 0.6 rad/s (got %.2f)" % cam.yaw)


func test_no_turn_when_walking_at_camera() -> void:
	var cam := FollowCam.new()
	cam.yaw = 0.0
	for i: int in 120:
		cam.update(Vector3.ZERO, Vector3(0.0, 0.0, 1.0), 1.0 / 60.0)
	check(is_equal_approx(cam.yaw, 0.0), "yaw does not turn while walking toward camera (dot < -0.3)")


func test_manual_orbit_pauses_auto_yaw() -> void:
	var cam := FollowCam.new()
	cam.yaw = 0.0
	cam.update(Vector3.ZERO, Vector3.ZERO, 0.1, 1.0)
	check(cam.yaw > 0.1, "manual orbit rotates yaw immediately")
	var orbited_yaw: float = cam.yaw
	for i: int in 60:
		cam.update(Vector3.ZERO, Vector3(1.0, 0.0, 0.0), 1.0 / 60.0, 0.0)
	check(is_equal_approx(cam.yaw, orbited_yaw), "auto-yaw is paused for 2.0 s after manual orbit")


func test_camera_zone_blend() -> void:
	var cam := FollowCam.new()
	cam.enter_zone(deg_to_rad(45.0), deg_to_rad(15.0), 10.0, 40.0)
	for i: int in 72:
		cam.update(Vector3.ZERO, Vector3.ZERO, 1.0 / 60.0)
	check(is_equal_approx(cam.distance, 10.0), "eased to zone distance 10 m")
	check(is_equal_approx(cam.pitch, deg_to_rad(15.0)), "eased to zone pitch 15 deg")
	check(is_equal_approx(cam.fov, 40.0), "eased to zone fov 40")
	check(is_equal_approx(cam.yaw, deg_to_rad(45.0)), "eased to zone yaw 45 deg")
	cam.exit_zone()
	for i: int in 72:
		cam.update(Vector3.ZERO, Vector3.ZERO, 1.0 / 60.0)
	check(is_equal_approx(cam.distance, 6.5), "eased back to default distance")
	check(is_equal_approx(cam.pitch, deg_to_rad(28.0)), "eased back to default pitch")


func test_input_rotation_by_yaw() -> void:
	var v_up := Vector2(0.0, -1.0)
	var v_right := Vector2(1.0, 0.0)
	check(FollowCam.rotate_input(v_up, 0.0).distance_to(Vector3(0.0, 0.0, -1.0)) < 0.01, "yaw 0 up is -z")
	check(FollowCam.rotate_input(v_right, 0.0).distance_to(Vector3(1.0, 0.0, 0.0)) < 0.01, "yaw 0 right is +x")
	check(FollowCam.rotate_input(v_up, PI * 0.5).distance_to(Vector3(-1.0, 0.0, 0.0)) < 0.01, "yaw 90 deg up is -x")
	check(FollowCam.rotate_input(v_up, PI).distance_to(Vector3(0.0, 0.0, 1.0)) < 0.01, "yaw 180 deg up is +z")
	check(FollowCam.rotate_input(Vector2.ZERO, PI).is_zero_approx(), "zero input stays zero")


func test_arm_shortening() -> void:
	check(is_equal_approx(FollowCam.shorten_arm(5.0, 4.0, 0.2), 4.8), "shortens to hit distance minus margin")
	check(is_equal_approx(FollowCam.shorten_arm(3.5, 4.0, 0.2), 4.0), "clamped to minimum 4.0 m")


func test_follow_cam_settles_at_side_angle() -> void:
	var rig := ContentDB.get_def("camera_rig", &"explore") as CameraRigDef
	var cam := FollowCam.new(rig)
	check(is_equal_approx(cam.follow_side_deg, deg_to_rad(32.0)), "side angle is 32 deg from camera.json")
	cam.yaw = 0.0
	# Move in -Z direction (straight ahead). Straight behind is 0 yaw. With 32 deg side offset, target is +32 deg.
	for i: int in 300:
		cam.update(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), 1.0 / 60.0)
	check(is_equal_approx(cam.yaw, deg_to_rad(32.0)), "yaw settles 32 deg right of straight behind (got %.2f deg)" % rad_to_deg(cam.yaw))


func test_camera_zone_roll_ease() -> void:
	var cam := FollowCam.new()
	cam.enter_zone(deg_to_rad(45.0), deg_to_rad(15.0), 10.0, 40.0, deg_to_rad(6.0))
	for i: int in 72:
		cam.update(Vector3.ZERO, Vector3.ZERO, 1.0 / 60.0)
	check(is_equal_approx(cam.roll, deg_to_rad(6.0)), "eased to zone roll 6 deg")
	cam.exit_zone()
	for i: int in 72:
		cam.update(Vector3.ZERO, Vector3.ZERO, 1.0 / 60.0)
	check(is_equal_approx(cam.roll, 0.0), "eased back to 0 roll outside zone")


func test_rise_candidates_order_and_end() -> void:
	var cands := FollowCamWall.rise_candidates(deg_to_rad(28.0), deg_to_rad(62.0), deg_to_rad(4.0))
	check(is_equal_approx(cands[0], deg_to_rad(28.0)), "first candidate is base pitch")
	check(is_equal_approx(cands[-1], deg_to_rad(62.0)), "last candidate is max pitch included")
	check(cands.size() >= 2, "at least base and max")


func test_ease_wall_rise_rises_faster_than_falls() -> void:
	var current: float = 0.0
	var target: float = 1.0
	# Rise fast
	var after_rise: float = FollowCamWall.ease_wall_rise(current, target, 1.0, 10.0, 0.5)
	check(after_rise > 0.7, "rises quickly (got %.2f)" % after_rise)
	# Fall slow (using down_rate < up_rate)
	current = 1.0
	var after_fall: float = FollowCamWall.ease_wall_rise(current, 0.0, 1.0, 10.0, 0.5)
	check(after_fall > 0.5, "falls slowly relative to rise (got %.2f)" % after_fall)


func test_ease_wall_rise_never_passes_target() -> void:
	var current: float = 0.5
	var target: float = 0.8
	for i: int in 20:
		current = FollowCamWall.ease_wall_rise(current, target, 0.5, 6.0, 1.5)
		check(current <= target + 0.001, "never exceeds target (%.4f > %.4f)" % [current, target])


func test_camera_position_with_override_pitch() -> void:
	var cam := FollowCam.new()
	cam.yaw = 0.0
	cam.aim = Vector3.ZERO
	cam.pitch = deg_to_rad(28.0)
	cam.distance = 6.5
	var pos_default := cam.camera_position()
	var pos_high := cam.camera_position(6.5, deg_to_rad(62.0))
	check(pos_high.y > pos_default.y, "higher pitch raises camera y")


func test_wall_rise_headless_wall_blocks_camera() -> void:
	# This is a headless physics concept test: with a wall between aim and camera,
	# the camera should rise. Since this is pure logic and no scene is set up,
	# we verify the ease and rise logic directly.
	var cam := FollowCam.new()
	cam.wall_rise = 0.0
	var target: float = deg_to_rad(62.0) - cam.pitch
	for i: int in 120:
		cam.wall_rise = FollowCamWall.ease_wall_rise(cam.wall_rise, target, 1.0 / 60.0, 6.0, 1.5)
	check(cam.wall_rise > 0.5, "wall rises above default after frames (got %.2f)" % rad_to_deg(cam.wall_rise))
