class_name Follower
extends CharacterBody3D
## Bilqis: trails the leader along the path he recently walked, at the follower distance, closing in with a little
## lag. She is a body that the walls stop (the leader's path always fits her capsule), and a FollowGuard puts her
## back on the trail if she ever wedges on a corner or falls behind the leash: she never sticks. She does not block
## the leader (her layer is off; her mask is the world).

var _rules: ExploreRulesDef
var _leader: Node3D
var _visual: CharacterVisual
var _guard: FollowGuard
var _trail: Array[Vector3] = []
var _keep_from: int = 0
var _active: bool = true


func _init(rules: ExploreRulesDef, leader: Node3D) -> void:
	_rules = rules
	_leader = leader
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = 1
	_guard = FollowGuard.new(rules.follower_stuck_seconds, rules.follower_leash, rules.follower_stuck_ratio)
	_visual = CharacterVisual.new()
	_visual.set_sprite(&"bilqis")
	add_child(_visual)
	_visual.clip_event.connect(_on_clip_event)
	ActorBody.add_capsule(self, rules)


func _ready() -> void:
	stand_by_player()


## Jumps to one follower distance behind the leader and forgets the old trail (after a teleport).
func stand_by_player() -> void:
	var start: Vector3 = _leader.position
	position = start - Vector3(0.0, 0.0, _rules.follower_distance)
	_trail = [position, start]
	_keep_from = 0
	_guard.reset()


## What draws her (the camera frames its head anchor in dialogue).
func visual() -> CharacterVisual:
	return _visual


## Off: stops, hides and does not collide. On: shows and follows again.
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
	var target: Vector3 = _target_point()
	var to_target: Vector3 = target - position
	to_target.y = 0.0
	var moving: bool = to_target.length() > _rules.follower_stop_distance
	var moved: float = 0.0
	var wanted: float = 0.0
	if moving:
		var step: Vector3 = to_target * (1.0 - exp(-_rules.follower_lag * delta))
		wanted = step.length()
		_move(step)
		var after: Vector3 = target - position
		after.y = 0.0
		moved = to_target.length() - after.length()
		_visual.face_dir(Vector3(to_target.x, 0.0, to_target.z))
	if _guard.update(delta, to_target.length(), wanted, moved):
		position = Vector3(target.x, position.y, target.z)
	_visual.set_moving(moving)
	_prune()


## Moves by this much, sliding along a wall instead of stopping dead.
func _move(motion: Vector3) -> void:
	var hit: KinematicCollision3D = move_and_collide(motion)
	if hit != null:
		move_and_collide(hit.get_remainder().slide(hit.get_normal()))


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


## A foot touched the ground in the walk or run clip (ClipDef.contacts): the step sounds on it, only while she follows.
func _on_clip_event(kind: StringName) -> void:
	if kind == &"footstep" and _active:
		AudioDirector.play_sfx(&"footstep_follower")
