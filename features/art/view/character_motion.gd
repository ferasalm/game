class_name CharacterMotion
extends RefCounted
## The tweened motions of a CharacterVisual: turn squash, anticipation (pull back and squash), the lunge with
## afterimages, impact and recoil, hurt (flash, shake, knockback slide), knocked out, revive and the victory hop.
## Everything moves `root` (slides), `pulse` (squash), `lift` (hops) and the shader's flash / desat / glow, so
## the walking code and these motions never fight. Numbers come from the VisualRulesDef.

var _v: CharacterVisual
var _rules: VisualRulesDef
var _slide: Tween
var _squash: Tween
var _down_tween: Tween


func setup(visual: CharacterVisual, rules: VisualRulesDef) -> void:
	_v = visual
	_rules = rules


func turn() -> void:
	_pulse(Vector2(1.0 - _rules.turn_squash, 1.0 + _rules.turn_squash * 0.4), _rules.turn_time * 0.4, _rules.turn_time * 0.6)


## Pull back away from the target and squash, ready to spring.
func anticipate(toward: Vector3) -> void:
	if not _v.is_inside_tree():
		return
	var back: float = -_dir(toward) * _rules.anticipate_pull
	var tween: Tween = _new_slide()
	tween.tween_property(_v.root, "position:x", back, _rules.anticipate_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pulse_hold(Vector2(1.0 + _rules.anticipate_squash * 0.5, 1.0 - _rules.anticipate_squash), _rules.anticipate_time)
	await tween.finished


## Springs to the target (stretched, with afterimages) and returns once in contact.
func dash(toward: Vector3) -> void:
	if not _v.is_inside_tree():
		return
	var flat := Vector3(toward.x - _v.global_position.x, 0.0, toward.z - _v.global_position.z)
	var goal: Vector3 = flat.limit_length(_rules.lunge_distance)
	_v.fx.trail(_v.root.position, goal, _rules.lunge_time)
	var tween: Tween = _new_slide()
	tween.tween_property(_v.root, "position", goal, _rules.lunge_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_pulse_hold(Vector2(1.0 - _rules.impact_stretch * 0.5, 1.0 + _rules.impact_stretch), _rules.lunge_time)
	await tween.finished
	_pulse(Vector2(1.0 + _rules.impact_stretch, 1.0 - _rules.impact_stretch), 0.04, _rules.recoil_time)


func return_home() -> void:
	if not _v.is_inside_tree():
		return
	var tween: Tween = _new_slide()
	tween.tween_property(_v.root, "position", Vector3.ZERO, _rules.recoil_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


## The whole melee swing in one call: anticipate, dash, come back.
func lunge(toward: Vector3) -> void:
	await anticipate(toward)
	await dash(toward)
	await return_home()


## Crouch, rise onto the toes and hold while a spell or shot leaves.
func cast_pose(hold: float) -> void:
	if not _v.is_inside_tree():
		return
	_pulse_hold(Vector2(1.0 + _rules.anticipate_squash * 0.5, 1.0 - _rules.anticipate_squash), _rules.anticipate_time)
	await _v.get_tree().create_timer(_rules.anticipate_time).timeout
	_pulse_hold(Vector2(1.0 - _rules.impact_stretch * 0.4, 1.0 + _rules.impact_stretch * 0.8), hold)
	var tween: Tween = _v.create_tween()
	tween.tween_property(_v, "lift", _rules.hop_height * 0.3, hold * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_v, "lift", 0.0, hold * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	_pulse(Vector2(1.0 + _rules.impact_stretch * 0.5, 1.0 - _rules.impact_stretch * 0.5), 0.03, _rules.recoil_time)


func flash() -> void:
	if not _v.is_inside_tree():
		return
	var tween: Tween = _v.create_tween()
	tween.tween_method(_set_flash, 1.0, 0.0, _rules.flash_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Flash, squash and a shaking slide away from the attacker, then back home.
func hurt(push_x: float) -> void:
	if not _v.is_inside_tree():
		return
	flash()
	_pulse(Vector2(1.0 + _rules.impact_stretch, 1.0 - _rules.impact_stretch), 0.05, _rules.hurt_time)
	var tween: Tween = _new_slide()
	var base: float = push_x
	tween.tween_property(_v.root, "position:x", base, _rules.hurt_time * 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var jitter: float = _rules.hurt_shake
	for i: int in 4:
		tween.tween_property(_v.root, "position:x", base + jitter * (1.0 if i % 2 == 0 else -1.0), _rules.hurt_time * 0.12)
		jitter *= 0.6
	tween.tween_property(_v.root, "position", Vector3.ZERO, _rules.recoil_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


## Fall (squash, drain the colour) or rise (spring up with a glow). Snaps when `animate` is off.
func set_down(down: bool, animate: bool) -> void:
	var squash := Vector2(1.12, _rules.down_squash) if down else Vector2.ONE
	if _down_tween != null and _down_tween.is_valid():
		_down_tween.kill()
	if not animate:
		_v.down_scale = squash
		_v.tint_down(1.0 if down else 0.0)
		return
	_down_tween = _v.create_tween().set_parallel(true)
	var time: float = _rules.ko_time if down else _rules.revive_time
	var trans: Tween.TransitionType = Tween.TRANS_BOUNCE if down else Tween.TRANS_BACK
	_down_tween.tween_property(_v, "down_scale", squash, time).set_trans(trans).set_ease(Tween.EASE_OUT)
	_down_tween.tween_method(_v.tint_down, 0.0 if down else 1.0, 1.0 if down else 0.0, time)
	if not down:
		_down_tween.tween_method(_set_glow, 1.0, 0.0, _rules.revive_time * 1.6)
		_down_tween.tween_property(_v, "lift", 0.0, _rules.revive_time)


## Victory: hop in place hop_count times, squashing on the landing. Callers await it.
func hop() -> void:
	if not _v.is_inside_tree():
		return
	var tween: Tween = _v.create_tween()
	for i: int in _rules.hop_count:
		tween.tween_property(_v, "lift", _rules.hop_height, _rules.hop_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_v, "lift", 0.0, _rules.hop_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(_land)
	await tween.finished


func _land() -> void:
	_pulse(Vector2(1.0 + _rules.impact_stretch, 1.0 - _rules.impact_stretch), 0.04, _rules.recoil_time)


func _dir(toward: Vector3) -> float:
	return 1.0 if toward.x >= _v.global_position.x else -1.0


func _new_slide() -> Tween:
	if _slide != null and _slide.is_valid():
		_slide.kill()
	_slide = _v.create_tween()
	return _slide


## Squash to `target` and ease back to normal.
func _pulse(target: Vector2, time_in: float, time_out: float) -> void:
	if not _v.is_inside_tree():
		return
	if _squash != null and _squash.is_valid():
		_squash.kill()
	_squash = _v.create_tween()
	_squash.tween_property(_v, "pulse", target, time_in).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_squash.tween_property(_v, "pulse", Vector2.ONE, time_out).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Squash to `target` and stay there for `time` (the caller pulses back later).
func _pulse_hold(target: Vector2, time: float) -> void:
	if _squash != null and _squash.is_valid():
		_squash.kill()
	_squash = _v.create_tween()
	_squash.tween_property(_v, "pulse", target, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_flash(amount: float) -> void:
	_v.material.set_shader_parameter(&"flash", amount)


func _set_glow(amount: float) -> void:
	_v.material.set_shader_parameter(&"glow", amount * _rules.revive_glow)
