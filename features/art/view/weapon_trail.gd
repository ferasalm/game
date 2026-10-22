class_name WeaponTrail
extends Node3D
## The weapon's swing in the air: a ribbon between two tracked points (hilt and the blade's point) that fades along its
## age, and an arc smear card (a crescent) flashed on the strike frame. World-space and top level, so it stays where the
## blade was while the character moves on. Numbers: the VisualRulesDef (trail_*, smear_*). Both are flat alpha-blended
## unlit meshes, one draw call each; neither is lit, neither casts a shadow.

const SMEAR_SHADER: Shader = preload("res://features/art/view/weapon_smear.gdshader")
const MAX_SAMPLES: int = 14

var _rules: VisualRulesDef
var _ribbon := MeshInstance3D.new()
var _mesh := ImmediateMesh.new()
var _smear := MeshInstance3D.new()
var _smear_mat := ShaderMaterial.new()
var _top: Node3D = null
var _tip: Node3D = null
var _from: PackedVector3Array = PackedVector3Array()
var _to: PackedVector3Array = PackedVector3Array()
var _age: PackedFloat32Array = PackedFloat32Array()
var _smear_tween: Tween


func setup(rules: VisualRulesDef) -> void:
	_rules = rules
	top_level = true
	var ribbon_mat := StandardMaterial3D.new()
	ribbon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ribbon_mat.vertex_color_use_as_albedo = true
	ribbon_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ribbon_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ribbon.mesh = _mesh
	_ribbon.material_override = ribbon_mat
	_ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ribbon.extra_cull_margin = 4.0
	add_child(_ribbon)
	var quad := QuadMesh.new()
	_smear.mesh = quad
	_smear_mat.shader = SMEAR_SHADER
	_smear_mat.set_shader_parameter(&"smear_color", rules.smear_color)
	_smear.material_override = _smear_mat
	_smear.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_smear.visible = false
	add_child(_smear)
	set_process(false)


## Starts recording the ribbon between these two nodes (the hilt and the blade's point).
func track(top: Node3D, tip: Node3D) -> void:
	_top = top
	_tip = tip
	set_process(true)


## Stops adding to the ribbon; what is drawn fades out.
func release() -> void:
	_top = null
	_tip = null


## The arc smear card: a crescent at `at` (world) sweeping toward `dir_x`, once.
func smear(at: Vector3, dir_x: float) -> void:
	_smear.global_position = at
	_smear.scale = Vector3(_rules.smear_size, _rules.smear_size, 1.0)
	_smear_mat.set_shader_parameter(&"flip", 1.0 if dir_x >= 0.0 else -1.0)
	_smear.visible = true
	_smear_mat.set_shader_parameter(&"progress", 0.0)
	if _smear_tween != null and _smear_tween.is_valid():
		_smear_tween.kill()
	_smear_tween = create_tween()
	_smear_tween.tween_property(_smear_mat, "shader_parameter/progress", 1.0, _rules.smear_time)
	_smear_tween.tween_callback(_smear.hide)


func sample_count() -> int:
	return _age.size()


func _process(delta: float) -> void:
	for i: int in _age.size():
		_age[i] += delta
	while not _age.is_empty() and _age[0] > _rules.trail_time:
		_age.remove_at(0)
		_from.remove_at(0)
		_to.remove_at(0)
	if _top != null and _tip != null and _top.is_inside_tree() and _age.size() < MAX_SAMPLES:
		_from.append(_top.global_position)
		_to.append(_tip.global_position)
		_age.append(0.0)
	_mesh.clear_surfaces()
	if _age.size() >= 2:
		_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for i: int in _age.size():
			var fade: float = 1.0 - _age[i] / _rules.trail_time
			var color: Color = _rules.trail_color
			color.a *= fade * fade
			_mesh.surface_set_color(color)
			_mesh.surface_add_vertex(_from[i])
			_mesh.surface_set_color(Color(color.r, color.g, color.b, color.a * 0.2))
			_mesh.surface_add_vertex(_to[i])
		_mesh.surface_end()
	elif _age.is_empty() and _top == null:
		set_process(false)
