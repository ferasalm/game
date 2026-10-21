class_name BattleJuice
extends Node
## Hitstop and camera shake for the battle view. A freeze frame drops Engine.time_scale for a moment of real
## time (so tweens, particles and the camera all hold still), then puts it back. Always restored on exit.

var def: JuiceDef
var _camera: BattleCamera
var _freezes: int = 0
var _epoch: int = 0  ## grows when a pause cancels the freezes in flight


func setup(juice: JuiceDef, camera: BattleCamera) -> void:
	def = juice
	_camera = camera


func _ready() -> void:
	EventBus.game_paused.connect(_on_game_paused)


## Freeze frames for `seconds` of real time. Callers await it. A pause cancels the freeze (the wait is pause-safe).
func hitstop(seconds: float) -> void:
	if seconds <= 0.0 or not is_inside_tree():
		return
	_freezes += 1
	var epoch: int = _epoch
	Engine.time_scale = def.freeze_scale
	await PauseWait.seconds(self, seconds, true)
	if epoch != _epoch:
		return  # cancelled by a pause while waiting: the state was already reset
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


func _on_game_paused(paused: bool) -> void:
	if paused:
		_epoch += 1
		_freezes = 0
		Engine.time_scale = 1.0
