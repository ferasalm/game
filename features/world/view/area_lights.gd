class_name AreaLights
extends Node3D
## The area's practical lights. Every LightSpec with a pool radius gets a fake light pool (one additive quad,
## all of them in one MultiMesh, always on). Only a few real OmniLight3Ds exist (the budget): each follows one of
## the nearest specs to the focus node and fades in or out when the set changes. No light casts shadows.

const POOL_SHADER: Shader = preload("res://features/world/view/shaders/light_pool.gdshader")

var specs: Array[LightSpec] = []
## Real lights alive right now (public for tests): slot lights, their spec index (-1 = free) and fade 0..1.
var slots: Array[OmniLight3D] = []
var slot_spec: Array[int] = []
var slot_fade: Array[float] = []

var _focus: Node3D
var _fade_speed: float = 3.0
var _positions: Array[Vector3] = []
var _real: Array[bool] = []
var _time: float = 0.0


func _init(light_specs: Array[LightSpec], focus: Node3D, budget: int, fade_speed: float) -> void:
	name = "Lights"
	specs = light_specs
	_focus = focus
	_fade_speed = fade_speed
	for spec: LightSpec in specs:
		_positions.append(spec.pos)
		_real.append(spec.real)
	add_child(_pools())
	for i: int in mini(budget, specs.size()):
		var light := OmniLight3D.new()
		light.shadow_enabled = false
		light.light_energy = 0.0
		light.omni_attenuation = 1.4
		light.light_specular = 0.0
		slots.append(light)
		slot_spec.append(-1)
		slot_fade.append(0.0)
		add_child(light)


func _process(delta: float) -> void:
	_time += delta
	var wanted: Array[int] = LightPick.nearest(_positions, _real, _focus.position, slots.size())
	_assign(wanted)
	for i: int in slots.size():
		_update_slot(i, wanted, delta)


## Slots whose light is no longer wanted fade out and are then reused for a wanted light that has no slot.
func _assign(wanted: Array[int]) -> void:
	for spec_index: int in wanted:
		if slot_spec.has(spec_index):
			continue
		for i: int in slots.size():
			if slot_spec[i] == -1 or (slot_fade[i] <= 0.0 and not wanted.has(slot_spec[i])):
				slot_spec[i] = spec_index
				_aim(i)
				break


func _aim(slot: int) -> void:
	var spec: LightSpec = specs[slot_spec[slot]]
	slots[slot].position = spec.pos
	slots[slot].light_color = spec.color
	slots[slot].omni_range = spec.range_m


func _update_slot(slot: int, wanted: Array[int], delta: float) -> void:
	var spec_index: int = slot_spec[slot]
	if spec_index < 0:
		return
	slot_fade[slot] = LightPick.fade(slot_fade[slot], wanted.has(spec_index), delta, _fade_speed)
	var spec: LightSpec = specs[spec_index]
	var wobble: float = LightPick.flicker(spec.flicker, spec.flicker_speed, LightPick.phase_of(spec.pos), _time)
	slots[slot].light_energy = spec.energy * slot_fade[slot] * wobble


func _pools() -> MultiMeshInstance3D:
	var pooled: Array[LightSpec] = []
	for spec: LightSpec in specs:
		if spec.pool_radius > 0.0:
			pooled.append(spec)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.use_custom_data = true
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE
	var mat := ShaderMaterial.new()
	mat.shader = POOL_SHADER
	quad.material = mat
	multi.mesh = quad
	multi.instance_count = pooled.size()
	for i: int in pooled.size():
		var spec: LightSpec = pooled[i]
		multi.set_instance_transform(i, _pool_transform(spec))
		multi.set_instance_color(i, spec.color)
		multi.set_instance_custom_data(i, Color(spec.flicker, spec.flicker_speed, LightPick.phase_of(spec.pos) / TAU, spec.pool_energy))
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


func _pool_transform(spec: LightSpec) -> Transform3D:
	var basis := Basis(Vector3.UP, deg_to_rad(spec.yaw))
	if spec.upright:
		basis = basis * Basis(Vector3.RIGHT, PI / 2.0)
	basis = basis.scaled_local(Vector3(spec.pool_radius * 2.0, 1.0, spec.pool_radius * 2.0))
	var at := Vector3(spec.pos.x, spec.pool_y, spec.pos.z)
	if spec.upright:
		at = spec.pos
	return Transform3D(basis, at)
