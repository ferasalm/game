class_name Patrol
extends Node3D
## A Concession patrol walking its lane (two floor points, a pause at each end). Touching the player (by distance,
## each physics frame) emits `touched`, unless it is cleared (beaten: gone until the sabil brings it back) or still
## in its grace time (after a battle, a drink or an unstuck it cannot touch for touch_grace seconds).

## The patrol reached the player. from_behind: it came from behind the way he faces.
signal touched(from_behind: bool)

## The encounter this patrol starts and the id of its place in the area.
var encounter_id: StringName = &""
var place_id: StringName = &""

var _rules: ExploreRulesDef
var _player: Player
var _visual: CharacterVisual
var _a: Vector3
var _b: Vector3
var _heading_to_b: bool = true
var _pause_left: float = 0.0
var _grace_left: float = 0.0
var _cleared: bool = false
var _active: bool = true


## place: a PlaceDef of kind patrol; floor_y: the floor height the lane lies on.
func _init(rules: ExploreRulesDef, place: PlaceDef, floor_y: float, player: Player) -> void:
	_rules = rules
	_player = player
	encounter_id = place.encounter
	place_id = place.id
	_a = Vector3(place.pos.x, floor_y, place.pos.z)
	_b = Vector3(place.end.x, floor_y, place.end.z)
	position = _a
	_visual = CharacterVisual.new()
	_visual.set_sprite(place.sprite)
	add_child(_visual)


## Off (during a battle or menu): stops, hides and cannot touch. On: resumes unless cleared.
func set_active(on: bool) -> void:
	_active = on
	_refresh_visible()
	if not on:
		_visual.set_moving(false)


## Beaten: hidden and harmless until revive().
func clear() -> void:
	_cleared = true
	_refresh_visible()


## Back in play at its first lane point, harmless for `grace` seconds.
func revive(grace: float) -> void:
	_cleared = false
	send_home(grace)


## Keeps walking where it is but cannot touch for `grace` seconds.
func hold(grace: float) -> void:
	_grace_left = grace


## Goes back to the first lane point and cannot touch for `grace` seconds.
func send_home(grace: float) -> void:
	position = _a
	_heading_to_b = true
	_pause_left = 0.0
	_grace_left = grace
	_refresh_visible()


func is_cleared() -> bool:
	return _cleared


## True while it walks and can touch (not cleared; the grace time may still run).
func is_live() -> bool:
	return _active and not _cleared


## The lane as two floor points.
func lane() -> PackedVector3Array:
	return PackedVector3Array([_a, _b])


## The way it is walking, flat on the floor and unit length (toward the point it is heading for).
func facing() -> Vector3:
	var goal: Vector3 = _b if _heading_to_b else _a
	var dir: Vector3 = goal - position
	if dir.length() < 0.001:
		dir = (_b - _a) if _heading_to_b else (_a - _b)
	dir.y = 0.0
	return dir.normalized()


func _physics_process(delta: float) -> void:
	if not is_live():
		return
	_walk(delta)
	if _grace_left > 0.0:
		_grace_left -= delta
		return
	_check_touch()


func _walk(delta: float) -> void:
	if _pause_left > 0.0:
		_pause_left -= delta
		_visual.set_moving(false)
		return
	var goal: Vector3 = _b if _heading_to_b else _a
	var to_goal: Vector3 = goal - position
	var step: float = _rules.patrol_speed * delta
	_visual.face_dir(Vector3(to_goal.x, 0.0, to_goal.z))
	_visual.set_moving(true)
	if to_goal.length() <= step:
		position = goal
		_heading_to_b = not _heading_to_b
		_pause_left = _rules.patrol_pause
	else:
		position += to_goal.normalized() * step


func _check_touch() -> void:
	var offset: Vector3 = position - _player.position
	offset.y = 0.0
	if offset.length() <= _rules.touch_radius:
		touched.emit(_player.facing.dot(offset) < 0.0)


func _refresh_visible() -> void:
	visible = _active and not _cleared
