class_name PixelSource
extends VisualSource
## The pixel-art source of a CharacterVisual (today's look, unchanged): a lit, billboarded quad with the sprite's
## texture (nearest filtering), idle breathing, the walk bob with squash and stretch, the lean into the move and
## dust at the feet. Its body-shape motions are PixelMotion's. One-shot clips (attack, cast, item, hurt, victory)
## only announce their clip events on a schedule from the rules; the moves themselves are the visual's lunge,
## dash and cast_pose, which the battle view still calls. The art faces right.

const SHADER: Shader = preload("res://features/art/view/character.gdshader")
const STEP_DUST_BACK: float = 0.3
const DOWN_TINT: Color = Color(0.72, 0.72, 0.85)
const HAND_HEIGHT: float = 0.55  ## the hand anchor's height as a share of the sprite height
const HAND_REACH: float = 0.5  ## and its reach forward as a share of the sprite width
const CHEST_HEIGHT: float = 0.72  ## chest, belt, hip and arm as shares of the sprite's own pixel bounds
const BELT_HEIGHT: float = 0.55
const ARM_HEIGHT: float = 0.62

var material: ShaderMaterial
var _motion: PixelMotion
var _quad: MeshInstance3D
var _clock: float = 0.0
var _bob_time: float = 0.0
var _lean: float = 0.0
var _steps: int = 0
var _facing: float = 1.0
var _height_px: int = 0
var _width_px: int = 0
var _ppm: float = 1.0


func attach(owner_visual: CharacterVisual, owner_rules: VisualRulesDef) -> void:
	super(owner_visual, owner_rules)
	_ppm = rules.pixels_per_metre
	_quad = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.center_offset = Vector3(0.0, 0.5, 0.0)
	_quad.mesh = mesh
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"min_light", rules.min_light)
	material.set_shader_parameter(&"rim_color", rules.rim_color)
	material.set_shader_parameter(&"rim_amount", rules.rim_amount)
	material.set_shader_parameter(&"glow_color", rules.revive_color)
	_quad.material_override = material
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	visual.body.add_child(_quad)
	_motion = PixelMotion.new()
	_motion.setup(visual, rules, material)


func materials() -> Array[ShaderMaterial]:
	return [material]


func detach() -> void:
	_quad.queue_free()


## Shows the sprite with this id (a magenta placeholder when the id or its palette is missing).
func set_sprite(sprite_id: StringName) -> void:
	var def := ContentDB.get_def("sprite", sprite_id) as SpriteDef
	_ppm = def.pixels_per_metre if def != null and def.pixels_per_metre > 0.0 else rules.pixels_per_metre
	var palette: PaletteDef = null
	if def != null:
		palette = ContentDB.get_def("palette", def.palette) as PaletteDef
	if def == null or palette == null:
		_apply(ImageTexture.create_from_image(PixelArt.placeholder(rules.placeholder_width, rules.placeholder_height)))
		return
	_apply(PixelArt.texture(def, palette))


func set_flip(facing: float) -> void:
	_facing = facing
	material.set_shader_parameter(&"flip", facing)


func update(delta: float, moving: bool, prop: bool, down: bool, facing: float) -> void:
	_clock += delta
	_facing = facing
	var walk: Vector2 = Vector2.ONE
	var bob: float = 0.0
	if moving:
		_bob_time += delta * rules.bob_speed
		var s: float = absf(sin(_bob_time))
		bob = s * rules.bob_height
		var squash: float = rules.walk_squash * (1.0 - s)
		walk = Vector2(1.0 + squash * 0.5, 1.0 - squash)
		_step_dust()
	else:
		_steps = 0
		if not prop and not down:
			var breath: float = sin(_clock * rules.breath_speed) * rules.breath_amount
			walk = Vector2(1.0 - breath * 0.5, 1.0 + breath)
	var lean_goal: float = -facing * rules.lean_degrees if moving else 0.0
	_lean = lerpf(_lean, lean_goal, 1.0 - exp(-rules.lean_speed * delta))
	var body: Node3D = visual.body
	body.position.y = bob + visual.lift
	body.rotation_degrees.z = _lean
	body.scale = Vector3(walk.x * visual.pulse.x * visual.down_scale.x, walk.y * visual.pulse.y * visual.down_scale.y, 1.0)
	visual.fx.sync(visual.root.position, bob + visual.lift)


func cue(kind: StringName) -> void:
	if visual.is_inside_tree():
		_motion.cue(kind)


func cast_pose(hold: float) -> void:
	await _motion.cast_pose(hold)


func hop() -> void:
	await _motion.hop()


func set_down(down: bool, animate: bool) -> void:
	_motion.set_down(down, animate)


func tint_down(share: float) -> void:
	material.set_shader_parameter(&"tint", Color.WHITE.lerp(DOWN_TINT, share))
	material.set_shader_parameter(&"desat", rules.ko_desat * share)


## Announces the clip's events on the rules' timing: impact when the hit lands, end when the clip is over.
func play_clip(state: StringName, _facing_x: float) -> void:
	var times: Vector2 = clip_times(state, rules)
	if visual.is_inside_tree() and times.y >= 0.0:
		_announce(&"impact", times.x)
		_announce(&"end", times.y)


## When a one-shot clip hits (x) and ends (y), in seconds; (-1, -1) for a state that is not a clip.
static func clip_times(state: StringName, r: VisualRulesDef) -> Vector2:
	match state:
		&"attack":
			var hit: float = r.anticipate_time + r.lunge_time
			return Vector2(hit, hit + r.recoil_time)
		&"cast", &"item":
			return Vector2(r.anticipate_time, r.anticipate_time + r.recoil_time)
		&"victory":
			return Vector2(r.hop_time, r.hop_time * r.hop_count)
		&"hurt":
			return Vector2(0.0, r.hurt_time)
	return Vector2(-1.0, -1.0)


func height() -> float:
	return float(_height_px) / _ppm


func width() -> float:
	return float(_width_px) / _ppm


func anchor(which: StringName) -> Vector3:
	match which:
		&"head":
			return Vector3(0.0, height(), 0.0)
		&"chest":
			return Vector3(0.0, height() * CHEST_HEIGHT, 0.0)
		&"belt":
			return Vector3(_facing * width() * 0.35, height() * BELT_HEIGHT, 0.0)
		&"hip":
			return Vector3(0.0, height() * BELT_HEIGHT, 0.0)
		&"arm", &"arm_left":
			return Vector3(_facing * width() * 0.45, height() * ARM_HEIGHT, 0.0)
		&"hand", &"hand_left":
			return Vector3(_facing * width() * HAND_REACH, height() * HAND_HEIGHT, 0.0)
	return Vector3.ZERO


func _announce(event: StringName, after: float) -> void:
	if after <= 0.0:
		clip_event.emit.call_deferred(event)
	else:
		visual.get_tree().create_timer(after, false).timeout.connect(clip_event.emit.bind(event))


func _step_dust() -> void:
	var step: int = int(floorf(_bob_time / PI))
	if step != _steps:
		_steps = step
		visual.fx.puff(visual.root.position, -_facing * STEP_DUST_BACK)


func _apply(texture: ImageTexture) -> void:
	material.set_shader_parameter(&"albedo_tex", texture)
	_height_px = texture.get_height()
	_width_px = texture.get_width()
	_quad.scale = Vector3(width(), height(), 1.0)
	visual.fx.set_picture(texture, Vector2(width(), height()))
