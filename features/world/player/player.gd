class_name Player
extends CharacterBody3D
## Zayd: 8-way walking from the move_* actions (up = -Z), stopped by solid tiles. Remembers which way he faces
## (the ambush rule reads it). Built in code; numbers come from ExploreRulesDef.

## The walking direction he last had, flat on the floor and unit length. Starts facing the camera.
var facing: Vector3 = Vector3(0.0, 0.0, 1.0)
## Camera yaw in radians for camera-relative movement.
var camera_yaw: float = 0.0

var _rules: ExploreRulesDef
var _visual: CharacterVisual
var _active: bool = true


func _init(rules: ExploreRulesDef) -> void:
	_rules = rules
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_visual = CharacterVisual.new()
	_visual.set_sprite(&"zayd")
	add_child(_visual)
	_visual.clip_event.connect(_on_clip_event)
	ActorBody.add_capsule(self, rules)


## What draws him (the camera frames its head anchor in dialogue).
func visual() -> CharacterVisual:
	return _visual


## Off: stops, hides and ignores input. On: shows and walks again.
func set_active(on: bool) -> void:
	_active = on
	visible = on
	if not on:
		velocity = Vector3.ZERO
		_visual.set_moving(false)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := FollowCam.rotate_input(input, camera_yaw)
	_move(direction * _rules.walk_speed * delta)
	var moving: bool = not direction.is_zero_approx()
	if moving:
		facing = direction.normalized()
		_visual.face_dir(direction)
	_visual.set_moving(moving)


## Moves by this much, sliding along a solid tile instead of stopping dead (own delta, so tests can drive it).
func _move(motion: Vector3) -> void:
	var hit: KinematicCollision3D = move_and_collide(motion)
	if hit != null:
		move_and_collide(hit.get_remainder().slide(hit.get_normal()))


## A foot touched the ground in the walk or run clip (ClipDef.contacts): the step sounds on it, only while he walks.
func _on_clip_event(kind: StringName) -> void:
	if kind == &"footstep" and _active:
		AudioDirector.play_sfx(&"footstep_zayd")
