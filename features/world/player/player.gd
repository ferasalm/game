class_name Player
extends CharacterBody3D
## Zayd: 8-way walking from the move_* actions (up = -Z), stopped by solid tiles. Remembers which way he faces
## (the ambush rule reads it). Built in code; numbers come from ExploreRulesDef.

## The walking direction he last had, flat on the floor and unit length. Starts facing the camera.
var facing: Vector3 = Vector3(0.0, 0.0, 1.0)

var _rules: ExploreRulesDef
var _visual: CharacterVisual
var _active: bool = true


func _init(rules: ExploreRulesDef) -> void:
	_rules = rules
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_visual = CharacterVisual.new()
	_visual.set_sprite(&"zayd")
	add_child(_visual)
	var capsule := CapsuleShape3D.new()
	capsule.radius = rules.capsule_radius
	capsule.height = rules.capsule_height
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = rules.capsule_height / 2.0
	add_child(shape)


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
	var direction := Vector3(input.x, 0.0, input.y)
	_move(direction * _rules.walk_speed * delta)
	var moving: bool = not direction.is_zero_approx()
	if moving:
		facing = direction.normalized()
		_visual.face(direction.x)
	_visual.set_moving(moving)


## Moves by this much, sliding along a solid tile instead of stopping dead (own delta, so tests can drive it).
func _move(motion: Vector3) -> void:
	var hit: KinematicCollision3D = move_and_collide(motion)
	if hit != null:
		move_and_collide(hit.get_remainder().slide(hit.get_normal()))
