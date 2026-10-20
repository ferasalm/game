class_name Patrol
extends Node3D
## A Concession enforcer walking between two points with pauses at the ends. Touching the player (by distance, each
## physics frame) emits `touched`; after reset() it is hidden and harmless for the respawn time.

## The patrol reached the player. from_behind: it came from behind the way he faces.
signal touched(from_behind: bool)

var _rules: ExploreRulesDef
var _player: Player
var _visual: CharacterVisual
var _start: Vector3
var _end: Vector3
var _heading_to_end: bool = true
var _pause_left: float = 0.0
var _respawn_left: float = 0.0
var _active: bool = true


func _init(rules: ExploreRulesDef, start: Vector3, end: Vector3, player: Player) -> void:
	_rules = rules
	_start = start
	_end = end
	_player = player
	position = start
	_visual = CharacterVisual.new()
	_visual.set_sprite(&"concession_enforcer")
	add_child(_visual)


## Off (during a battle or menu): stops, hides and cannot touch. On: resumes unless still respawning.
func set_active(on: bool) -> void:
	_active = on
	_refresh_visible()
	if not on:
		_visual.set_moving(false)


## Back to the start point, hidden and harmless until the respawn time has passed.
func reset() -> void:
	position = _start
	_heading_to_end = true
	_pause_left = 0.0
	_respawn_left = _rules.patrol_respawn
	_refresh_visible()


func _physics_process(delta: float) -> void:
	if not _active:
		return
	if _respawn_left > 0.0:
		_respawn_left -= delta
		_refresh_visible()
		return
	_walk(delta)
	_check_touch()


func _walk(delta: float) -> void:
	if _pause_left > 0.0:
		_pause_left -= delta
		_visual.set_moving(false)
		return
	var goal: Vector3 = _end if _heading_to_end else _start
	var to_goal: Vector3 = goal - position
	var step: float = _rules.patrol_speed * delta
	_visual.face(to_goal.x)
	_visual.set_moving(true)
	if to_goal.length() <= step:
		position = goal
		_heading_to_end = not _heading_to_end
		_pause_left = _rules.patrol_pause
	else:
		position += to_goal.normalized() * step


func _check_touch() -> void:
	var offset: Vector3 = position - _player.position
	offset.y = 0.0
	if offset.length() <= _rules.touch_radius:
		touched.emit(_player.facing.dot(offset) < 0.0)


func _refresh_visible() -> void:
	visible = _active and _respawn_left <= 0.0
