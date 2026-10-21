class_name BattleCamera
extends Node
## The cinematic battle camera. On start it swoops from wherever the exploration camera was to a low pose that
## frames both sides against the skyline; then it drifts gently, leans toward whoever acts, pushes in on big
## moves, shakes on hits and, after a win, glides to a victory pose. All numbers: content/combat/camera.json.

var camera: Camera3D
var _def: BattleCameraDef
var _look: LookDef
var _anchor: Vector3 = Vector3.ZERO
var _from_pos: Vector3 = Vector3.ZERO
var _from_target: Vector3 = Vector3.ZERO
var _from_fov: float = 30.0
var _time: float = 0.0
var _swoop: float = 0.0
var _follow: float = 0.0
var _follow_goal: float = 0.0
var _push: float = 0.0
var _push_goal: float = 0.0
var _push_left: float = 0.0
var _shake: float = 0.0
var _victory: float = -1.0
var _decay: float = 8.0
var _shake_speed: float = 60.0


## `previous` is the camera that was current (null: start right at the battle pose). `instant` skips the swoop.
func setup(cam: Camera3D, def: BattleCameraDef, look: LookDef, anchor: Vector3, previous: Camera3D, instant: bool) -> void:
	camera = cam
	_def = def
	_look = look
	_anchor = anchor
	if previous != null and not instant:
		_from_pos = previous.global_position
		_from_target = _from_pos - previous.global_transform.basis.z * 10.0
		_from_fov = previous.fov
	else:
		_swoop = def.swoop_time
	_apply(0.0)


func is_swooping() -> bool:
	return _swoop < _def.swoop_time


## Camera shake of this strength (metres); it decays by itself.
func shake(amount: float, decay: float, speed: float) -> void:
	_shake = maxf(_shake, amount)
	_decay = decay
	_shake_speed = speed


## Pushes in (fov narrows by amount x push_fov) for `hold` seconds, then eases back.
func push(amount: float, hold: float) -> void:
	_push_goal = maxf(_push_goal, amount)
	_push_left = hold


## Leans toward a unit standing at this world x (the actor of a big move); clear_focus lets go.
func focus_on(world_x: float) -> void:
	_follow_goal = (world_x - _anchor.x - _def.look.x) * _def.follow


func clear_focus() -> void:
	_follow_goal = 0.0


## Glide to the victory pose.
func victory() -> void:
	if _victory < 0.0:
		_victory = 0.0
		clear_focus()


func in_victory() -> bool:
	return _victory >= 0.0


func _process(delta: float) -> void:
	_time += delta
	_swoop = minf(_swoop + delta, _def.swoop_time)
	_follow = lerpf(_follow, _follow_goal, 1.0 - exp(-_def.follow_speed * delta))
	_push_left -= delta
	if _push_left <= 0.0:
		_push_goal = 0.0
	_push = lerpf(_push, _push_goal, 1.0 - exp(-_def.push_speed * delta))
	_shake *= exp(-_decay * delta)
	if _victory >= 0.0:
		_victory = minf(_victory + delta, _def.victory_time)
	_apply(delta)


func _apply(_delta: float) -> void:
	var s: float = 1.0 if _def.swoop_time <= 0.0 else clampf(_swoop / _def.swoop_time, 0.0, 1.0)
	s = s * s * s * (s * (s * 6.0 - 15.0) + 10.0)
	var drift := Vector3(sin(_time * _def.drift_speed) * _def.drift.x, sin(_time * _def.drift_speed * 1.3) * _def.drift.y, 0.0)
	var pos: Vector3 = _anchor + _def.pos + drift + Vector3(_follow, 0.0, 0.0)
	var target: Vector3 = _anchor + _def.look + Vector3(_follow * 1.2, 0.0, 0.0)
	var fov: float = _def.fov
	if _victory >= 0.0:
		var v: float = smoothstep(0.0, 1.0, _victory / maxf(_def.victory_time, 0.01))
		pos = pos.lerp(_anchor + _def.victory_pos, v)
		target = target.lerp(_anchor + _def.victory_look, v)
		fov = lerpf(fov, _def.victory_fov, v)
	fov -= _push * _def.push_fov
	camera.position = _from_pos.lerp(pos, s) + _shake_offset()
	camera.look_at(_from_target.lerp(target, s))
	camera.fov = lerpf(_from_fov, fov, s)
	var practical := camera.attributes as CameraAttributesPractical
	if practical != null:
		practical.dof_blur_near_distance = _def.dof_near
		practical.dof_blur_far_distance = _def.dof_far
		practical.dof_blur_amount = _def.dof_amount * lerpf(1.0, _def.dof_scale, s)


func _shake_offset() -> Vector3:
	if _shake < 0.001:
		return Vector3.ZERO
	var speed: float = _time * _shake_speed
	return Vector3(sin(speed * 1.7), cos(speed * 2.3) * 0.6, 0.0) * _shake
