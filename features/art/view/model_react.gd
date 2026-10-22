class_name ModelReact
extends RefCounted
## What a live 3D character does in answer to the battle's cues, on its materials and on `visual.body`: the hit flash,
## the revive glow, the knocked-out tint, the small squash of a hit (squash lives on the facade's body node, never on
## bones) and the victory hop. Numbers: the VisualRulesDef.

const DOWN_TINT: Color = Color(0.72, 0.72, 0.85)

var _visual: CharacterVisual
var _rules: VisualRulesDef
var _materials: Array[ShaderMaterial] = []
var _base_tints: Array[Color] = []
var _squash: Tween = null


func setup(visual: CharacterVisual, rules: VisualRulesDef, materials: Array[ShaderMaterial]) -> void:
	_visual = visual
	_rules = rules
	_materials = materials
	for mat: ShaderMaterial in materials:
		_base_tints.append(mat.get_shader_parameter(&"tint") as Color)


## A root move began (see VisualSource.cue): hits flash and squash, a landed blow squashes a little.
func cue(kind: StringName) -> void:
	match kind:
		&"flash":
			flash()
		&"hurt":
			flash()
			squash(0.6)
		&"impact":
			squash(0.3)


## A brief bright flash of every surface.
func flash() -> void:
	ModelMaterials.set_all(_materials, &"flash", 1.0)
	_fade(&"flash", 1.0, 0.0, _rules.flash_time)


## The green glow of standing up again.
func revive() -> void:
	_fade(&"glow", _rules.revive_glow, 0.0, _rules.revive_time)


## A squash and spring back of the whole body; `share` scales it (a hit 0.6, a landed blow 0.3).
func squash(share: float) -> void:
	if _squash != null and _squash.is_valid():
		_squash.kill()
	var s: float = _rules.impact_stretch * 0.3 * share
	_visual.body.scale = Vector3(1.0 + s * 0.5, 1.0 - s, 1.0 + s * 0.5)
	_squash = _visual.create_tween()
	_squash.tween_property(_visual.body, "scale", Vector3.ONE, _rules.flash_time * 1.5).set_trans(Tween.TRANS_BACK)


## Knocked-out tint and drained colour, `share` 0..1.
func tint_down(share: float) -> void:
	for i: int in _materials.size():
		_materials[i].set_shader_parameter(&"tint", _base_tints[i].lerp(_base_tints[i] * DOWN_TINT, share))
	ModelMaterials.set_all(_materials, &"desat", _rules.ko_desat * share)


## The victory hop(s): the facade's `lift` goes up and down. Callers await it.
func hop() -> void:
	var tween: Tween = _visual.create_tween()
	for i: int in _rules.hop_count:
		tween.tween_property(_visual, "lift", _rules.hop_height, _rules.hop_time * 0.5).set_ease(Tween.EASE_OUT)
		tween.tween_property(_visual, "lift", 0.0, _rules.hop_time * 0.5).set_ease(Tween.EASE_IN)
	await tween.finished


func _fade(parameter: StringName, from: float, to: float, seconds: float) -> void:
	var tween: Tween = _visual.create_tween()
	tween.tween_method(func(v: float) -> void: ModelMaterials.set_all(_materials, parameter, v), from, to, seconds)
