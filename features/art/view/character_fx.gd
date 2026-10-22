class_name CharacterFx
extends Node3D
## The small effects around one CharacterVisual: a soft blob shadow on the floor, dust puffs at the feet and the
## fading afterimages of a lunge. Everything is pooled and built once; numbers come from the VisualRulesDef.

const GHOST_SHADER: Shader = preload("res://features/art/view/character_ghost.gdshader")
const SHADOW_LIFT: float = 0.03
const DUST_STRETCH: float = 2.2

var _rules: VisualRulesDef
var _shadow: Sprite3D
var _dust: Array[VfxSprite] = []
var _dust_layer := VfxLayer.new()
var _dust_next: int = 0
var _ghosts: Array[MeshInstance3D] = []
var _ghost_mat: ShaderMaterial
var _size: Vector2 = Vector2.ONE
var _has_picture: bool = false  ## afterimages copy a sprite; a live 3D model has none, so it leaves no ghosts
var _ghost_age: PackedFloat32Array = PackedFloat32Array()
var _ghost_delay: PackedFloat32Array = PackedFloat32Array()


func setup(rules: VisualRulesDef) -> void:
	_rules = rules
	_shadow = Sprite3D.new()
	_shadow.texture = VfxTextures.texture(&"glow")
	_shadow.axis = Vector3.AXIS_Y
	_shadow.shaded = false
	_shadow.pixel_size = rules.shadow_size / VfxTextures.pixels(&"glow").x
	_shadow.modulate = Color(0.0, 0.0, 0.03, rules.shadow_alpha)
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shadow.position.y = SHADOW_LIFT
	add_child(_shadow)
	_dust_layer.size = Vector2(rules.dust_size, rules.dust_size * 0.8)
	_dust_layer.size_end = _dust_layer.size * DUST_STRETCH
	_dust_layer.color = rules.dust_color
	_dust_layer.energy = rules.dust_energy
	_dust_layer.time = rules.dust_time
	_dust_layer.hold = 0.0
	_ghost_mat = ShaderMaterial.new()
	_ghost_mat.shader = GHOST_SHADER
	_ghost_mat.set_shader_parameter(&"ghost_color", rules.ghost_color)
	set_process(false)


## The sprite's picture and size (metres) for the afterimages.
func set_picture(texture: Texture2D, size: Vector2) -> void:
	_has_picture = true
	_ghost_mat.set_shader_parameter(&"albedo_tex", texture)
	_size = size
	for ghost: MeshInstance3D in _ghosts:
		ghost.scale = Vector3(size.x, size.y, 1.0)
	_shadow.pixel_size = _rules.shadow_size * maxf(size.x, 0.5) / VfxTextures.pixels(&"glow").x


## The blob shadow's size for a body of this width (a model has no picture to size it by).
func set_shadow_width(width: float) -> void:
	_shadow.pixel_size = _rules.shadow_size * maxf(width, 0.5) / VfxTextures.pixels(&"glow").x


func set_flip(flip: float) -> void:
	_ghost_mat.set_shader_parameter(&"flip", flip)


## Keeps the shadow under the feet: `offset` is how far the body slid, `lift` how high it hopped (it shrinks).
func sync(offset: Vector3, lift: float) -> void:
	_shadow.position = Vector3(offset.x, SHADOW_LIFT, offset.z)
	var shrink: float = clampf(1.0 - lift * 0.8, 0.4, 1.0)
	_shadow.scale = Vector3(shrink, shrink, shrink)
	_shadow.modulate.a = _rules.shadow_alpha * shrink


func set_shadow_visible(on: bool) -> void:
	_shadow.visible = on


## A small cloud of dust that drifts back and up from this spot.
func puff(at: Vector3, back: float) -> void:
	if _dust.size() < 4:
		var made := VfxSprite.new()
		add_child(made)
		_dust.append(made)
	var sprite: VfxSprite = _dust[_dust_next % _dust.size()]
	_dust_next += 1
	var from: Vector3 = at + Vector3(0.0, 0.05, 0.0)
	sprite.launch(&"glow", _dust_layer, 0.0, from, from + Vector3(back, _rules.dust_rise, 0.0), 1.0)
	set_process(true)


## Afterimages along a dash from one body offset to another, each appearing a little after the last.
func trail(from: Vector3, to: Vector3, dash_time: float) -> void:
	if not _has_picture:
		return
	while _ghosts.size() < _rules.ghost_count:
		var ghost := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.center_offset = Vector3(0.0, 0.5, 0.0)
		ghost.mesh = quad
		ghost.material_override = _ghost_mat
		ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ghost.visible = false
		ghost.scale = Vector3(_size.x, _size.y, 1.0)
		add_child(ghost)
		_ghosts.append(ghost)
		_ghost_age.append(0.0)
		_ghost_delay.append(0.0)
	for i: int in _ghosts.size():
		var share: float = float(i) / float(maxi(_ghosts.size(), 1))
		_ghosts[i].position = from.lerp(to, share)
		_ghost_age[i] = 0.0
		_ghost_delay[i] = share * dash_time
	set_process(true)


func _process(delta: float) -> void:
	var busy: bool = false
	for i: int in _dust.size():
		if _dust[i].running:
			busy = _dust[i].tick(delta) or busy
	for i: int in _ghosts.size():
		_ghost_age[i] += delta
		var life: float = _ghost_age[i] - _ghost_delay[i]
		var fade: float = 0.0
		if life >= 0.0 and life < _rules.ghost_time:
			var left: float = 1.0 - life / _rules.ghost_time
			fade = _rules.ghost_alpha * left * left
			busy = true
		elif life < 0.0:
			busy = true
		_ghosts[i].visible = fade > 0.0
		_ghosts[i].set_instance_shader_parameter(&"fade", fade)
	set_process(busy)
