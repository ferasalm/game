class_name VfxSprite
extends MeshInstance3D
## One pooled effect quad. The effect player starts it with `launch` and calls `tick` every frame (no tweens, no
## allocations): it waits out its delay, then grows, moves, spins and fades along its life.

const SHADER: Shader = preload("res://features/combat/view/vfx_sprite.gdshader")
static var _mesh: QuadMesh = null
static var _materials: Dictionary[StringName, ShaderMaterial] = {}

var _age: float = 0.0
var _delay: float = 0.0
var _life: float = 1.0
var _hold: float = 0.3
var _from: Vector3 = Vector3.ZERO
var _to: Vector3 = Vector3.ZERO
var _size_a: Vector2 = Vector2.ONE
var _size_b: Vector2 = Vector2.ONE
var _roll_a: float = 0.0
var _roll_b: float = 0.0
var _color: Color = Color.WHITE
var _flip: float = 1.0
var _linear: bool = false
## True from launch until the life is over.
var running: bool = false


func _init() -> void:
	if _mesh == null:
		_mesh = QuadMesh.new()
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false


## Starts this sprite. `flip` -1 mirrors it; `linear` moves it at constant speed (projectiles).
func launch(tex: StringName, layer: VfxLayer, delay: float, from: Vector3, to: Vector3, flip: float) -> void:
	material_override = _material(tex)
	_age = 0.0
	_delay = delay
	_life = layer.time
	_hold = layer.hold
	_from = from
	_to = to
	_size_a = layer.size
	_size_b = layer.size_end
	_color = Color(layer.color.r * layer.energy, layer.color.g * layer.energy, layer.color.b * layer.energy, 1.0)
	_flip = flip
	_linear = layer.to != &"" and not layer.span
	running = true
	visible = false


func set_roll(start_radians: float, end_radians: float) -> void:
	_roll_a = start_radians
	_roll_b = end_radians


## Overrides the size (a span stretches from point to point).
func set_sizes(start_size: Vector2, end_size: Vector2) -> void:
	_size_a = start_size
	_size_b = end_size


## Advances by delta; false once the life is over.
func tick(delta: float) -> bool:
	_age += delta
	if _age < _delay:
		return true
	var t: float = (_age - _delay) / _life
	if t >= 1.0:
		running = false
		visible = false
		return false
	visible = true
	var eased: float = t if _linear else 1.0 - (1.0 - t) * (1.0 - t)
	position = _from.lerp(_to, eased)
	var size: Vector2 = _size_a.lerp(_size_b, eased)
	scale = Vector3(size.x * _flip, size.y, 1.0)
	rotation.z = lerpf(_roll_a, _roll_b, eased)
	var fade: float = 1.0 if t < _hold else 1.0 - pow((t - _hold) / (1.0 - _hold), 2.0)
	set_instance_shader_parameter(&"tint", Color(_color.r, _color.g, _color.b, fade))
	return true


static func _material(tex: StringName) -> ShaderMaterial:
	if not _materials.has(tex):
		var mat := ShaderMaterial.new()
		mat.shader = SHADER
		var image: ImageTexture = VfxTextures.texture(tex)
		mat.set_shader_parameter(&"tex_pixel", image)
		mat.set_shader_parameter(&"tex_soft", image)
		mat.set_shader_parameter(&"soft", 1.0 if VfxTextures.is_soft(tex) else 0.0)
		_materials[tex] = mat
	return _materials[tex]
