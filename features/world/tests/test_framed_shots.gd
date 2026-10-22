extends TestCase
## FramedShots tests: shot picking, 0.5 m hysteresis, +-15 deg clamp, and input basis retention.


func test_shot_picking() -> void:
	var fs := FramedShots.new()
	fs.add_shot(&"door", Vector3(1.0, 2.0, 4.0), Vector3(4.0, 1.0, 2.5), Rect2(0.0, 0.0, 4.0, 5.0))
	fs.add_shot(&"window", Vector3(7.0, 2.0, 1.0), Vector3(4.0, 1.0, 2.5), Rect2(4.0, 0.0, 4.0, 5.0))
	fs.update(Vector3(2.0, 0.0, 2.0))
	check_eq(fs.active_shot.id, &"door", "picks door shot when inside its rect")
	check(fs.current_cam_pos.distance_to(Vector3(1.0, 2.0, 4.0)) < 0.01, "instant cut to door cam_pos")
	fs.update(Vector3(6.0, 0.0, 2.0))
	check_eq(fs.active_shot.id, &"window", "picks window shot when moving into its rect")
	check(fs.current_cam_pos.distance_to(Vector3(7.0, 2.0, 1.0)) < 0.01, "instant cut to window cam_pos")


func test_hysteresis_prevents_flip_flop() -> void:
	var fs := FramedShots.new(0.5)
	fs.add_shot(&"door", Vector3(1.0, 2.0, 4.0), Vector3(4.0, 1.0, 2.5), Rect2(0.0, 0.0, 4.0, 5.0))
	fs.add_shot(&"window", Vector3(7.0, 2.0, 1.0), Vector3(4.0, 1.0, 2.5), Rect2(4.0, 0.0, 4.0, 5.0))
	fs.update(Vector3(2.0, 0.0, 2.0))
	check_eq(fs.active_shot.id, &"door", "starts in door shot")
	fs.update(Vector3(4.3, 0.0, 2.0))
	check_eq(fs.active_shot.id, &"door", "stays in door shot within 0.5 m hysteresis (0.3 m past line)")
	fs.update(Vector3(4.6, 0.0, 2.0))
	check_eq(fs.active_shot.id, &"window", "switches to window shot after crossing 0.5 m threshold")
	fs.update(Vector3(3.7, 0.0, 2.0))
	check_eq(fs.active_shot.id, &"window", "stays in window shot within 0.5 m hysteresis heading back")
	fs.update(Vector3(3.4, 0.0, 2.0))
	check_eq(fs.active_shot.id, &"door", "switches back to door shot after crossing 0.5 m threshold")


func test_camera_tracking_clamped_to_15_deg() -> void:
	var fs := FramedShots.new(0.5, 15.0)
	fs.add_shot(&"fixed_look", Vector3(0.0, 2.0, 0.0), Vector3(0.0, 2.0, -5.0), Rect2(-10.0, -10.0, 20.0, 20.0))
	fs.update(Vector3(0.0, 2.0, -5.0))
	var base_look := Vector3(0.0, 0.0, -1.0)
	check(fs.current_look_dir.distance_to(base_look) < 0.01, "looks directly along base look at center")
	fs.update(Vector3(10.0, 2.0, -5.0))
	var angle: float = fs.current_look_dir.angle_to(base_look)
	check(absf(angle - deg_to_rad(15.0)) < 0.01, "look clamped to 15 deg horizontally (got %.1f deg)" % rad_to_deg(angle))


func test_input_basis_retention_across_cut() -> void:
	var fs := FramedShots.new(0.5, 15.0, 20.0)
	fs.add_shot(&"door", Vector3(0.0, 2.0, 5.0), Vector3(0.0, 2.0, 0.0), Rect2(0.0, 0.0, 4.0, 5.0))
	fs.add_shot(&"window", Vector3(0.0, 2.0, -5.0), Vector3(0.0, 2.0, 0.0), Rect2(4.0, 0.0, 4.0, 5.0))
	var stick_up := Vector2(0.0, -1.0)
	fs.update(Vector3(2.0, 0.0, 2.0), stick_up)
	var door_basis: float = fs.current_input_yaw
	fs.update(Vector3(4.6, 0.0, 2.0), stick_up)
	check_eq(fs.active_shot.id, &"window", "cut to window shot occurred")
	check(fs.is_retaining_basis(), "retains previous basis while stick held")
	check(is_equal_approx(fs.current_input_yaw, door_basis), "input yaw is still door shot basis")
	var stick_slight := Vector2(sin(deg_to_rad(10.0)), -cos(deg_to_rad(10.0)))
	fs.update(Vector3(4.6, 0.0, 2.0), stick_slight)
	check(fs.is_retaining_basis(), "still retains basis within 20 deg stick shift")
	var stick_turned := Vector2(1.0, 0.0)
	fs.update(Vector3(4.6, 0.0, 2.0), stick_turned)
	check(not fs.is_retaining_basis(), "basis switches after stick turned > 20 deg")
	check(not is_equal_approx(fs.current_input_yaw, door_basis), "switched to window shot basis")


func test_camera_room_scene_builds_and_switches_shots() -> void:
	var room := (load("res://features/world/interior/camera_room.tscn") as PackedScene).instantiate() as CameraRoom
	tree.root.add_child(room)
	check(room.camera != null, "camera exists")
	check(room.player != null, "player exists")
	check_eq(room.active_shot_id(), &"door_corner", "starts in door_corner shot")
	room.set_player_pos(Vector3(6.0, 0.0, 2.5))
	check_eq(room.active_shot_id(), &"window_corner", "cuts to window_corner shot on x > 4.5")
	room.set_player_pos(Vector3(2.0, 0.0, 2.5))
	check_eq(room.active_shot_id(), &"door_corner", "cuts back to door_corner shot on x < 3.5")
	room.free()
