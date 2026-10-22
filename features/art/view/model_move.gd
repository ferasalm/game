class_name ModelMove
extends RefCounted
## What a model's body does on the ground: the ground speed it is really moving at (measured from its own position, so
## animation and feet agree whoever moves it), the yaw it eases toward at the model's turn speed, and the lean into an
## acceleration. The maths are the pure Locomotion and YawTurn; this only keeps their state between frames.

const SPEED_SMOOTH: float = 12.0

var speed: float = 0.0
var yaw: float = 0.0
var lean: float = 0.0  ## degrees, forward positive
var _target_yaw: float = 0.0
var _last: Vector3 = Vector3.ZERO
var _seen: bool = false
var _turned: bool = false
var _walked: float = 0.0


## Asks for a facing (radians); the very first one is taken at once, later ones are eased to.
func face(target: float) -> void:
	_target_yaw = target
	if not _turned:
		_turned = true
		yaw = target


## Changes the goal without ever snapping (a mirror request; the first real direction still snaps).
func retarget(target: float) -> void:
	_target_yaw = target


func target_yaw() -> float:
	return _target_yaw


func is_turning() -> bool:
	return not YawTurn.arrived(yaw, _target_yaw)


## One frame: `at` is the body's ground position (the visual plus its sliding root).
func update(delta: float, at: Vector3, def: ModelDef, rules: VisualRulesDef) -> void:
	if delta <= 0.0:
		return
	var flat := Vector3(at.x - _last.x, 0.0, at.z - _last.z)
	var measured: float = flat.length() / delta if _seen else 0.0
	_last = at
	_seen = true
	var before: float = speed
	speed = Locomotion.smooth(speed, measured, delta, SPEED_SMOOTH)
	var accel: float = (speed - before) / delta
	var goal: float = Locomotion.lean(accel, def.lean_gain, rules.lean_degrees)
	lean = Locomotion.smooth(lean, goal, delta, rules.lean_speed)
	yaw = YawTurn.step(yaw, _target_yaw, deg_to_rad(def.turn_speed), delta)


## True once per half stride of a run (a footfall that kicks up dust).
func footfall(delta: float, def: ModelDef) -> bool:
	_walked += speed * delta
	if _walked < def.stride_m * 0.5:
		return false
	_walked = 0.0
	return speed >= def.run_speed
