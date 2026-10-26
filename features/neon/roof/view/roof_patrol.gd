class_name RoofPatrol
extends RefCounted
## purpose: manages one guard's patrol: walks every point of its path and back (ping-pong), pauses at both ends, faces its motion.

var actor: IsoActor
var path: PackedVector2Array
var speed: float
var pause_duration: float
var _target_idx: int = 1
var _dir: int = 1
var _pause_timer: float = 0.0


func _init(p_actor: IsoActor, p_path: PackedVector2Array, p_speed: float, p_pause: float) -> void:
	actor = p_actor
	path = p_path
	speed = p_speed
	pause_duration = p_pause
	if path.size() > 0:
		actor.position = path[0]
	if path.size() > 1:
		actor.face((path[1] - path[0]).normalized())


func step(delta: float) -> void:
	if path.size() < 2:
		return
	if _pause_timer > 0.0:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			var dir: Vector2 = (path[_target_idx] - actor.position).normalized()
			actor.face(dir)
			actor.play(&"walk")
		else:
			actor.play(&"idle")
		return
	var target: Vector2 = path[_target_idx]
	var to_target: Vector2 = target - actor.position
	var dist: float = to_target.length()
	var step_dist: float = speed * delta
	if dist <= step_dist or dist < 1.0:
		actor.position = target
		if _target_idx + _dir < 0 or _target_idx + _dir >= path.size():
			_dir = -_dir
			_pause_timer = pause_duration
			actor.play(&"idle")
		_target_idx += _dir
	else:
		var dir: Vector2 = to_target / dist
		actor.position += dir * step_dist
		actor.face(dir)
		actor.play(&"walk")
