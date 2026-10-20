class_name Follower
extends Node3D
## Bilqis: trails the leader along the path he recently walked, at the follower distance, closing in with a little
## lag. No physics: she only moves toward a point on the leader's trail.

var _rules: ExploreRulesDef
var _leader: Node3D
var _visual: CharacterVisual
var _trail: Array[Vector3] = []
var _keep_from: int = 0
var _active: bool = true


func _init(rules: ExploreRulesDef, leader: Node3D) -> void:
	_rules = rules
	_leader = leader
	_visual = CharacterVisual.new()
	_visual.set_sprite(&"bilqis")
	add_child(_visual)


func _ready() -> void:
	var start: Vector3 = _leader.position
	position = start - Vector3(0.0, 0.0, _rules.follower_distance)
	_trail = [position, start]


## Off: stops and hides. On: shows and follows again.
func set_active(on: bool) -> void:
	_active = on
	visible = on
	if not on:
		_visual.set_moving(false)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	if _trail.back().distance_to(_leader.position) >= _rules.trail_step:
		_trail.append(_leader.position)
	var to_target: Vector3 = _target_point() - position
	to_target.y = 0.0
	var moving: bool = to_target.length() > _rules.follower_stop_distance
	if moving:
		position += to_target * (1.0 - exp(-_rules.follower_lag * delta))
		_visual.face(to_target.x)
	_visual.set_moving(moving)
	_prune()


## The point on the trail one follower distance behind the leader, walking back along the path.
func _target_point() -> Vector3:
	var remaining: float = _rules.follower_distance
	var from: Vector3 = _leader.position
	for i: int in range(_trail.size() - 1, -1, -1):
		var segment: float = from.distance_to(_trail[i])
		if segment >= remaining and segment > 0.0:
			_keep_from = i
			return from.lerp(_trail[i], remaining / segment)
		remaining -= segment
		from = _trail[i]
	_keep_from = 0
	return _trail[0]


func _prune() -> void:
	while _keep_from > 0:
		_trail.remove_at(0)
		_keep_from -= 1
