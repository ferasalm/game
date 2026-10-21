class_name BattleJuice
extends Node
## Hitstop and camera shake for the battle view. A freeze frame drops Engine.time_scale for a moment of real
## time (so tweens, particles and the camera all hold still), then puts it back. Always restored on exit.

var def: JuiceDef
var _camera: BattleCamera
var _freezes: int = 0


func setup(juice: JuiceDef, camera: BattleCamera) -> void:
	def = juice
	_camera = camera


## Freeze frames for `seconds` of real time. Callers await it.
func hitstop(seconds: float) -> void:
	if seconds <= 0.0 or not is_inside_tree():
		return
	_freezes += 1
	Engine.time_scale = def.freeze_scale
	await get_tree().create_timer(seconds, true, false, true).timeout
	_freezes = maxi(_freezes - 1, 0)
	if _freezes == 0:
		Engine.time_scale = 1.0


func shake(amount: float) -> void:
	if _camera != null and amount > 0.0:
		_camera.shake(amount, def.shake_decay, def.shake_speed)


func is_frozen() -> bool:
	return _freezes > 0


func _exit_tree() -> void:
	if _freezes > 0:
		_freezes = 0
		Engine.time_scale = 1.0
