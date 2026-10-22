class_name FramedShots
extends RefCounted
## Indoor framed shots logic: shot picking with hysteresis, clamped tracking, and input basis retention at cuts.

class Shot extends RefCounted:
	var id: StringName = &""
	var cam_pos: Vector3 = Vector3.ZERO
	var look_target: Vector3 = Vector3.ZERO
	var rect: Rect2 = Rect2()
	var fov: float = 45.0


var shots: Array[Shot] = []
var active_shot: Shot = null
var current_cam_pos: Vector3 = Vector3.ZERO
var current_look_dir: Vector3 = Vector3(0.0, 0.0, -1.0)
var current_fov: float = 45.0
var current_input_yaw: float = 0.0

var hysteresis: float = 0.5
var clamp_angle: float = deg_to_rad(15.0)
var stick_retention_angle: float = deg_to_rad(20.0)

var _cut_stick: Vector2 = Vector2.ZERO
var _retaining_basis: bool = false
var _prev_basis_yaw: float = 0.0
var _active_basis_yaw: float = 0.0


func _init(h: float = 0.5, c_deg: float = 15.0, s_deg: float = 20.0) -> void:
	hysteresis = h
	clamp_angle = deg_to_rad(c_deg)
	stick_retention_angle = deg_to_rad(s_deg)


func add_shot(id: StringName, cam_pos: Vector3, look_target: Vector3, rect: Rect2, fov: float = 45.0) -> Shot:
	var s := Shot.new()
	s.id = id
	s.cam_pos = cam_pos
	s.look_target = look_target
	s.rect = rect
	s.fov = fov
	shots.append(s)
	return s


func is_retaining_basis() -> bool:
	return _retaining_basis


func current_target() -> Vector3:
	return current_cam_pos + current_look_dir


func update(player_pos: Vector3, stick_input: Vector2 = Vector2.ZERO, _delta: float = 0.0) -> void:
	_pick_shot(player_pos, stick_input)
	_update_input_basis(stick_input)
	_update_look_dir(player_pos)


func _pick_shot(player_pos: Vector3, stick_input: Vector2) -> void:
	var p2 := Vector2(player_pos.x, player_pos.z)
	if active_shot != null and active_shot.rect.grow(hysteresis).has_point(p2):
		return
	for s: Shot in shots:
		if s.rect.has_point(p2):
			if s != active_shot:
				_switch_to_shot(s, stick_input)
			return


func _switch_to_shot(new_shot: Shot, stick_input: Vector2) -> void:
	if active_shot != null and stick_input.length() > 0.1:
		_retaining_basis = true
		_cut_stick = stick_input.normalized()
		_prev_basis_yaw = _active_basis_yaw
	else:
		_retaining_basis = false
	active_shot = new_shot
	current_cam_pos = new_shot.cam_pos
	current_fov = new_shot.fov
	var base_vec := (new_shot.look_target - new_shot.cam_pos).normalized()
	_active_basis_yaw = atan2(-base_vec.x, -base_vec.z)
	if not _retaining_basis:
		current_input_yaw = _active_basis_yaw


func _update_input_basis(stick_input: Vector2) -> void:
	if not _retaining_basis:
		current_input_yaw = _active_basis_yaw
		return
	if stick_input.length() <= 0.1:
		_retaining_basis = false
		current_input_yaw = _active_basis_yaw
		return
	var diff: float = absf(stick_input.normalized().angle_to(_cut_stick))
	if diff > stick_retention_angle:
		_retaining_basis = false
		current_input_yaw = _active_basis_yaw
	else:
		current_input_yaw = _prev_basis_yaw


func _update_look_dir(player_pos: Vector3) -> void:
	if active_shot == null:
		return
	var base_vec := (active_shot.look_target - active_shot.cam_pos).normalized()
	var to_player := (player_pos - active_shot.cam_pos).normalized()
	var base_yaw: float = atan2(-base_vec.x, -base_vec.z)
	var base_pitch: float = asin(clampf(base_vec.y, -1.0, 1.0))
	var target_yaw: float = atan2(-to_player.x, -to_player.z)
	var target_pitch: float = asin(clampf(to_player.y, -1.0, 1.0))
	var yaw_diff: float = clampf(angle_difference(base_yaw, target_yaw), -clamp_angle, clamp_angle)
	var pitch_diff: float = clampf(target_pitch - base_pitch, -clamp_angle, clamp_angle)
	var final_yaw: float = base_yaw + yaw_diff
	var final_pitch: float = base_pitch + pitch_diff
	current_look_dir = Vector3(-sin(final_yaw) * cos(final_pitch), sin(final_pitch),
		-cos(final_yaw) * cos(final_pitch)).normalized()
