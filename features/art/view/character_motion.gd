class_name CharacterMotion
extends RefCounted
## The root moves of a CharacterVisual: they slide `root` and nothing else (the picture and its squash belong to the
## VisualSource). Anticipation pulls back from the target, the dash springs to it with afterimages, return_home
## slides back, lunge is all three, and hurt shakes the root away from the attacker. Numbers: the VisualRulesDef.

var _v: CharacterVisual
var _rules: VisualRulesDef
var _slide: Tween


func setup(visual: CharacterVisual, rules: VisualRulesDef) -> void:
	_v = visual
	_rules = rules


## Pull back away from the target.
func anticipate(toward: Vector3) -> void:
	if not _v.is_inside_tree():
		return
	var back: float = -_dir(toward) * _rules.anticipate_pull
	var tween: Tween = _new_slide()
	tween.tween_property(_v.root, "position:x", back, _rules.anticipate_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished


## Springs to the target (afterimages) and returns once in contact.
func dash(toward: Vector3) -> void:
	if not _v.is_inside_tree():
		return
	var flat := Vector3(toward.x - _v.global_position.x, 0.0, toward.z - _v.global_position.z)
	var goal: Vector3 = flat.limit_length(_rules.lunge_distance)
	_v.fx.trail(_v.root.position, goal, _rules.lunge_time)
	var tween: Tween = _new_slide()
	tween.tween_property(_v.root, "position", goal, _rules.lunge_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished


func return_home() -> void:
	if not _v.is_inside_tree():
		return
	var tween: Tween = _new_slide()
	tween.tween_property(_v.root, "position", Vector3.ZERO, _rules.recoil_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


## A shaking slide away from the attacker (push_x < 0 = left), then back home.
func hurt(push_x: float) -> void:
	if not _v.is_inside_tree():
		return
	var tween: Tween = _new_slide()
	var base: float = push_x
	tween.tween_property(_v.root, "position:x", base, _rules.hurt_time * 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var jitter: float = _rules.hurt_shake
	for i: int in 4:
		tween.tween_property(_v.root, "position:x", base + jitter * (1.0 if i % 2 == 0 else -1.0), _rules.hurt_time * 0.12)
		jitter *= 0.6
	tween.tween_property(_v.root, "position", Vector3.ZERO, _rules.recoil_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _dir(toward: Vector3) -> float:
	return 1.0 if toward.x >= _v.global_position.x else -1.0


func _new_slide() -> Tween:
	if _slide != null and _slide.is_valid():
		_slide.kill()
	_slide = _v.create_tween()
	return _slide
