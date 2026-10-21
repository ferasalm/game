class_name PixelMotion
extends RefCounted
## The body-shape motions of a pixel character (PixelSource): whole-body squash and stretch (`pulse`), the cast
## crouch, the victory hop, the hit flash, knocked out and revive. They move `visual.pulse`, `visual.lift`,
## `visual.down_scale` and the shader's flash / desat / glow; the slides (lunge, dash, hurt push) are CharacterMotion's.
## rules.pulse_squash false turns every squash off (puppets bend their limbs instead). Numbers: VisualRulesDef.

const IMPACT_IN: float = 0.04  ## seconds to reach the impact squash
const HURT_IN: float = 0.05
const DOWN_WIDEN: float = 1.12  ## a knocked-out body spreads a little wider

var _v: CharacterVisual
var _rules: VisualRulesDef
var _material: ShaderMaterial
var _squash: Tween
var _down_tween: Tween


func setup(visual: CharacterVisual, rules: VisualRulesDef, material: ShaderMaterial) -> void:
	_v = visual
	_rules = rules
	_material = material


func turn() -> void:
	pulse(Vector2(1.0 - _rules.turn_squash, 1.0 + _rules.turn_squash * 0.4), _rules.turn_time * 0.4, _rules.turn_time * 0.6)


## The squash that goes with a root move: &"anticipate", &"dash", &"impact", &"hurt", &"turn", &"flash".
func cue(kind: StringName) -> void:
	var stretch := Vector2(1.0 - _rules.impact_stretch * 0.5, 1.0 + _rules.impact_stretch)
	var crush := Vector2(1.0 + _rules.impact_stretch, 1.0 - _rules.impact_stretch)
	match kind:
		&"anticipate":
			pulse_hold(Vector2(1.0 + _rules.anticipate_squash * 0.5, 1.0 - _rules.anticipate_squash), _rules.anticipate_time)
		&"dash":
			pulse_hold(stretch, _rules.lunge_time)
		&"impact":
			pulse(crush, IMPACT_IN, _rules.recoil_time)
		&"hurt":
			flash()
			pulse(crush, HURT_IN, _rules.hurt_time)
		&"turn":
			turn()
		&"flash":
			flash()


## Crouch, rise onto the toes and hold while a spell or shot leaves.
func cast_pose(hold: float) -> void:
	if not _v.is_inside_tree():
		return
	pulse_hold(Vector2(1.0 + _rules.anticipate_squash * 0.5, 1.0 - _rules.anticipate_squash), _rules.anticipate_time)
	await _v.get_tree().create_timer(_rules.anticipate_time).timeout
	pulse_hold(Vector2(1.0 - _rules.impact_stretch * 0.4, 1.0 + _rules.impact_stretch * 0.8), hold)
	var tween: Tween = _v.create_tween()
	tween.tween_property(_v, "lift", _rules.hop_height * 0.3, hold * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_v, "lift", 0.0, hold * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	pulse(Vector2(1.0 + _rules.impact_stretch * 0.5, 1.0 - _rules.impact_stretch * 0.5), 0.03, _rules.recoil_time)


func flash() -> void:
	if not _v.is_inside_tree():
		return
	var tween: Tween = _v.create_tween()
	tween.tween_method(_set_flash, 1.0, 0.0, _rules.flash_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Fall (squash, drain the colour) or rise (spring up with a glow). Snaps when `animate` is off.
func set_down(down: bool, animate: bool) -> void:
	var squash := Vector2(DOWN_WIDEN, _rules.down_squash) if down else Vector2.ONE
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
		tween.tween_callback(cue.bind(&"impact"))
	await tween.finished


## Squash to `target` and ease back to normal.
func pulse(target: Vector2, time_in: float, time_out: float) -> void:
	if not _v.is_inside_tree() or not _rules.pulse_squash:
		return
	if _squash != null and _squash.is_valid():
		_squash.kill()
	_squash = _v.create_tween()
	_squash.tween_property(_v, "pulse", target, time_in).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_squash.tween_property(_v, "pulse", Vector2.ONE, time_out).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Squash to `target` and stay there for `time` (the caller pulses back later).
func pulse_hold(target: Vector2, time: float) -> void:
	if not _v.is_inside_tree() or not _rules.pulse_squash:
		return
	if _squash != null and _squash.is_valid():
		_squash.kill()
	_squash = _v.create_tween()
	_squash.tween_property(_v, "pulse", target, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_flash(amount: float) -> void:
	_material.set_shader_parameter(&"flash", amount)


func _set_glow(amount: float) -> void:
	_material.set_shader_parameter(&"glow", amount * _rules.revive_glow)
