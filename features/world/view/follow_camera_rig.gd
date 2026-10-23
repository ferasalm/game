class_name FollowCameraRig
extends ExploreCamera
## Drives Camera3D in follow mode (FollowCam), framed mode (FramedShots), or legacy fixed mode (ExploreCamera).

var _player: Player = null
var _follower: Follower = null
var _camera_zones: Array[PlaceDef] = []
var _follow_cam: FollowCam = null
var _framed_shots: FramedShots = null
var _mode: StringName = &"follow"


func setup(camera: Camera3D, look: LookDef, rig: CameraRigDef, zone: Rect2, smoothing: float,
		focus: Vector3) -> void:
	super.setup(camera, look, rig, zone, smoothing, focus)
	_mode = rig.mode
	_follow_cam = FollowCam.new(rig)
	if _mode == &"follow":
		_follow_cam.update(_focus, Vector3.ZERO, 0.0)
		_camera.global_position = _follow_cam.camera_position()
		_camera.look_at(_follow_cam.aim)
		_camera.fov = _follow_cam.fov


func setup_framed(camera: Camera3D, framed_shots: FramedShots, player: Player = null) -> void:
	_camera = camera
	_framed_shots = framed_shots
	_player = player
	_mode = &"framed"
	var p_pos: Vector3 = player.global_position if player != null else Vector3.ZERO
	_framed_shots.update(p_pos)
	_camera.global_position = _framed_shots.current_cam_pos
	_camera.look_at(_framed_shots.current_target())
	_camera.fov = _framed_shots.current_fov


func set_actors(player: Player, follower: Follower) -> void:
	_player = player
	_follower = follower


func set_zones(zones: Array[PlaceDef]) -> void:
	_camera_zones = zones


func update(delta: float, subject: Vector3) -> void:
	if is_intro_playing() or _skip_time >= 0.0:
		super.update(delta, subject)
		return
	if _mode == &"follow":
		_update_follow(delta, subject)
	elif _mode == &"framed":
		_update_framed(delta)
	else:
		super.update(delta, subject)


func _update_follow(delta: float, subject: Vector3) -> void:
	_update_focus(delta, subject)
	_update_zones()
	var attributes := _camera.attributes as CameraAttributesPractical
	if attributes != null:  # the close follow view is sharp: no tilt-shift blur
		attributes.dof_blur_far_enabled = false
		attributes.dof_blur_near_enabled = false
	var move_dir: Vector3 = _player.velocity if _player != null else Vector3.ZERO
	var facing: Vector3 = _player.facing if _player != null else Vector3.ZERO
	_follow_cam.update(_focus, move_dir, delta, 0.0, facing)  # no player camera control (owner 2026-10-23)
	var cam_pos: Vector3 = _shortened_camera_pos()
	_camera.global_position = cam_pos
	_camera.look_at(_follow_cam.aim)
	if not is_zero_approx(_follow_cam.roll):
		_camera.rotate_object_local(Vector3.FORWARD, _follow_cam.roll)
	_camera.fov = _follow_cam.fov
	if _player != null:
		_player.camera_yaw = _follow_cam.yaw


func _update_focus(delta: float, subject: Vector3) -> void:
	if _player != null:
		var p_pos: Vector3 = _player.global_position
		var f_pos: Vector3 = _follower.global_position if _follower != null and is_instance_valid(_follower) else p_pos
		var target: Vector3 = FollowCam.compute_focus(p_pos, f_pos, _rig.focus_player_weight,
			_rig.focus_follower_weight)
		_focus = _focus.lerp(target, 1.0 - exp(-_smoothing * delta))
	else:
		_focus = _focus.lerp(subject, 1.0 - exp(-_smoothing * delta))


func _update_zones() -> void:
	if _player == null:
		return
	var p2 := Vector2(_player.global_position.x, _player.global_position.z)
	for z: PlaceDef in _camera_zones:
		if z.zone_rect.has_point(p2):
			_follow_cam.enter_zone(deg_to_rad(z.yaw), deg_to_rad(z.pitch), z.distance, z.fov, deg_to_rad(z.roll))
			return
	_follow_cam.exit_zone()


func _shortened_camera_pos() -> Vector3:
	var desired_pos: Vector3 = _follow_cam.camera_position()
	var actual_dist: float = _follow_cam.distance
	if is_inside_tree() and get_viewport() != null:
		var world := get_viewport().find_world_3d()
		if world != null:
			var space := world.direct_space_state
			var query := PhysicsRayQueryParameters3D.create(_follow_cam.aim, desired_pos)
			var excludes: Array[RID] = []
			if _player != null:
				excludes.append(_player.get_rid())
			if _follower != null and is_instance_valid(_follower):
				excludes.append(_follower.get_rid())
			query.exclude = excludes
			var hit := space.intersect_ray(query)
			if not hit.is_empty():
				var hit_dist: float = (_follow_cam.aim - (hit.position as Vector3)).length()
				actual_dist = FollowCam.shorten_arm(hit_dist, _rig.collision_min_distance, _rig.collision_margin)
	return _follow_cam.camera_position(actual_dist)


func _update_framed(delta: float) -> void:
	if _framed_shots == null:
		return
	var p_pos: Vector3 = _player.global_position if _player != null else Vector3.ZERO
	var stick: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_framed_shots.update(p_pos, stick, delta)
	_camera.global_position = _framed_shots.current_cam_pos
	_camera.look_at(_framed_shots.current_target())
	_camera.fov = _framed_shots.current_fov
	if _player != null:
		_player.camera_yaw = _framed_shots.current_input_yaw
