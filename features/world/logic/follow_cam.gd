class_name FollowCam
extends RefCounted
## Close third-person follow camera logic: focus, lazy auto-yaw, a scripted orbit (never player input: owner 2026-10-23), zone easing and arm shortening.

var yaw: float = 0.0
var pitch: float = 0.0
var distance: float = 6.5
var fov: float = 50.0
var roll: float = 0.0
var aim: Vector3 = Vector3.ZERO
var facing: Vector3 = Vector3(0.0, 0.0, 1.0)

var default_pitch: float = deg_to_rad(28.0)
var default_distance: float = 6.5
var default_fov: float = 50.0
var default_roll: float = 0.0
var follow_side_deg: float = 0.0
var aim_height: float = 1.2
var aim_lead: float = 1.5
var lazy_yaw_delay: float = 0.8
var lazy_yaw_rate: float = 0.6
var walk_toward_dot: float = -0.3
var manual_orbit_speed: float = 1.5
var manual_orbit_pause: float = 2.0
var zone_ease_duration: float = 1.2

var _steady_move_time: float = 0.0
var _manual_orbit_timer: float = 0.0
var _in_zone: bool = false
var _zone_blend: float = 0.0
var _base_yaw: float = 0.0
var _base_pitch: float = 0.0
var _base_distance: float = 0.0
var _base_fov: float = 0.0
var _base_roll: float = 0.0
var _zone_target_yaw: float = 0.0
var _zone_target_pitch: float = 0.0
var _zone_target_distance: float = 0.0
var _zone_target_fov: float = 0.0
var _zone_target_roll: float = 0.0


func _init(rig: CameraRigDef = null) -> void:
	if rig != null:
		setup_from_def(rig)
	else:
		pitch = default_pitch
		distance = default_distance
		fov = default_fov


func setup_from_def(rig: CameraRigDef) -> void:
	default_distance = rig.follow_distance
	default_pitch = deg_to_rad(rig.follow_pitch_deg)
	default_fov = rig.follow_fov
	aim_height = rig.aim_height
	aim_lead = rig.aim_lead
	lazy_yaw_delay = rig.lazy_yaw_delay
	lazy_yaw_rate = rig.lazy_yaw_rate
	walk_toward_dot = rig.walk_toward_dot
	manual_orbit_speed = rig.manual_orbit_speed
	manual_orbit_pause = rig.manual_orbit_pause
	zone_ease_duration = rig.zone_ease_duration
	follow_side_deg = deg_to_rad(rig.follow_side_deg)
	pitch = default_pitch
	distance = default_distance
	fov = default_fov
	roll = default_roll


static func compute_focus(player_pos: Vector3, follower_pos: Vector3, p_weight: float = 0.7,
		f_weight: float = 0.3) -> Vector3:
	return player_pos * p_weight + follower_pos * f_weight


static func rotate_input(input_vec: Vector2, cam_yaw: float) -> Vector3:
	if input_vec.is_zero_approx():
		return Vector3.ZERO
	return Vector3(input_vec.x, 0.0, input_vec.y).rotated(Vector3.UP, cam_yaw)


static func shorten_arm(hit_distance: float, min_distance: float = 2.0, margin: float = 0.2) -> float:
	return maxf(min_distance, hit_distance - margin)


func enter_zone(z_yaw: float, z_pitch: float, z_dist: float, z_fov: float, z_roll: float = 0.0) -> void:
	if not _in_zone:
		_in_zone = true
		_base_yaw = yaw
		_base_pitch = pitch
		_base_distance = distance
		_base_fov = fov
		_base_roll = roll
		_zone_blend = 0.0
	_zone_target_yaw = z_yaw
	_zone_target_pitch = z_pitch
	_zone_target_distance = z_dist
	_zone_target_fov = z_fov
	_zone_target_roll = z_roll


func exit_zone() -> void:
	_in_zone = false


func is_in_zone() -> bool:
	return _in_zone


func zone_blend_amount() -> float:
	return _zone_blend


func camera_position(override_distance: float = -1.0) -> Vector3:
	var d: float = distance if override_distance < 0.0 else override_distance
	var offset_h: float = d * cos(pitch)
	var offset_y: float = d * sin(pitch)
	return aim + Vector3(sin(yaw) * offset_h, offset_y, cos(yaw) * offset_h)


func update(focus: Vector3, move_dir: Vector3, delta: float, orbit_input: float = 0.0,
		facing_hint: Vector3 = Vector3.ZERO) -> void:
	_update_aim(focus, move_dir, facing_hint)
	_update_manual_orbit(orbit_input, delta)
	if _in_zone or _zone_blend > 0.0:
		_update_zone_blend(delta)
	else:
		pitch = default_pitch
		distance = default_distance
		fov = default_fov
		roll = default_roll
		_update_lazy_yaw(move_dir, delta)


func _update_aim(focus: Vector3, move_dir: Vector3, facing_hint: Vector3) -> void:
	var move_flat := Vector3(move_dir.x, 0.0, move_dir.z)
	if facing_hint.length_squared() > 0.001:
		facing = Vector3(facing_hint.x, 0.0, facing_hint.z).normalized()
	elif move_flat.length_squared() > 0.001:
		facing = move_flat.normalized()
	if facing.is_zero_approx():
		facing = Vector3(0.0, 0.0, 1.0)
	# The aim leads into the view (away from the camera), so the pair stands in the lower frame with the land ahead.
	aim = focus + Vector3(0.0, aim_height, 0.0) + Vector3(-sin(yaw), 0.0, -cos(yaw)) * aim_lead


func _update_manual_orbit(orbit_input: float, delta: float) -> void:
	if absf(orbit_input) > 0.01:
		yaw += orbit_input * manual_orbit_speed * delta
		yaw = wrapf(yaw, -PI, PI)
		_manual_orbit_timer = manual_orbit_pause
		_steady_move_time = 0.0
	elif _manual_orbit_timer > 0.0:
		_manual_orbit_timer = maxf(0.0, _manual_orbit_timer - delta)


func _update_zone_blend(delta: float) -> void:
	var step: float = delta / maxf(0.001, zone_ease_duration)
	if _in_zone:
		_zone_blend = minf(1.0, _zone_blend + step)
		var t: float = smoothstep(0.0, 1.0, _zone_blend)
		yaw = lerp_angle(_base_yaw, _zone_target_yaw, t)
		pitch = lerpf(_base_pitch, _zone_target_pitch, t)
		distance = lerpf(_base_distance, _zone_target_distance, t)
		fov = lerpf(_base_fov, _zone_target_fov, t)
		roll = lerpf(_base_roll, _zone_target_roll, t)
	else:
		_zone_blend = maxf(0.0, _zone_blend - step)
		var t: float = smoothstep(0.0, 1.0, _zone_blend)
		pitch = lerpf(default_pitch, _zone_target_pitch, t)
		distance = lerpf(default_distance, _zone_target_distance, t)
		fov = lerpf(default_fov, _zone_target_fov, t)
		roll = lerpf(default_roll, _zone_target_roll, t)


func _update_lazy_yaw(move_dir: Vector3, delta: float) -> void:
	var move_flat := Vector3(move_dir.x, 0.0, move_dir.z)
	if _manual_orbit_timer > 0.0 or move_flat.length_squared() <= 0.001:
		_steady_move_time = 0.0
		return
	var move_norm := move_flat.normalized()
	var cam_forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var dot: float = move_norm.dot(cam_forward)
	if dot < walk_toward_dot:
		_steady_move_time = 0.0
		return
	_steady_move_time += delta
	if _steady_move_time >= lazy_yaw_delay:
		var target_yaw: float = wrapf(atan2(-move_norm.x, -move_norm.z) + follow_side_deg, -PI, PI)
		var diff: float = angle_difference(yaw, target_yaw)
		yaw += clampf(diff, -lazy_yaw_rate * delta, lazy_yaw_rate * delta)
		yaw = wrapf(yaw, -PI, PI)
