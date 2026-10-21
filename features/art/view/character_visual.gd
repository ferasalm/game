class_name CharacterVisual
extends Node3D
## A pixel-art character standing in the 3D world: a lit, billboarded quad (feet on the node's origin) with
## idle breathing, a walk bob with squash and stretch, a lean into the move, dust at the feet, a blob shadow, and
## the battle motions (see CharacterMotion). Built in code; numbers come from content/art/visual.json. The art faces
## right. Gameplay code only uses the public methods below. Pixel art stays crisp: nearest filtering, no resampling.

const RULES_ID: StringName = &"default"
const SHADER: Shader = preload("res://features/art/view/character.gdshader")
const DOWN_TINT: Color = Color(0.72, 0.72, 0.85)
const STEP_DUST_BACK: float = 0.3

## Squash multiplier, hop height and knocked-out squash, moved by the battle motions (tween targets).
var pulse: Vector2 = Vector2.ONE
var lift: float = 0.0
var down_scale: Vector2 = Vector2.ONE
## Everything that slides (lunge, knockback, shake) lives under `root`; `body` pivots at the feet.
var root: Node3D
var body: Node3D
var material: ShaderMaterial
var fx: CharacterFx
var rules: VisualRulesDef
var motion: CharacterMotion
var _quad: MeshInstance3D
var _moving: bool = false
var _down: bool = false
var _prop: bool = false
var _faced: bool = false
var _facing: float = 1.0
var _clock: float = 0.0
var _bob_time: float = 0.0
var _lean: float = 0.0
var _steps: int = 0
var _height_px: int = 0
var _ppm: float = 1.0
var _width_px: int = 0


func _init() -> void:
	rules = ContentDB.get_def("visual_rules", RULES_ID) as VisualRulesDef
	if rules == null:
		rules = VisualRulesDef.new()
	root = Node3D.new()
	body = Node3D.new()
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
	body.add_child(_quad)
	root.add_child(body)
	add_child(root)
	fx = CharacterFx.new()
	add_child(fx)
	fx.setup(rules)
	motion = CharacterMotion.new()
	motion.setup(self, rules)


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


## The art faces right: a negative x direction mirrors it (with a quick squash when it really turns).
func face(dir_x: float) -> void:
	if is_zero_approx(dir_x):
		return
	var facing: float = 1.0 if dir_x > 0.0 else -1.0
	if facing != _facing and _faced and is_inside_tree():
		motion.turn()
	_faced = true
	_facing = facing
	material.set_shader_parameter(&"flip", facing)
	fx.set_flip(facing)


func set_moving(on: bool) -> void:
	_moving = on
	if not on:
		_steps = 0


## Scenery drawn as a character (a bench): no breathing.
func set_prop(on: bool) -> void:
	_prop = on


## Dash at a world point and come back. Callers await it.
func lunge(toward: Vector3) -> void:
	await motion.lunge(toward)


func anticipate(toward: Vector3) -> void:
	await motion.anticipate(toward)


## Dashes to the target (afterimages) and returns once in contact.
func dash(toward: Vector3) -> void:
	await motion.dash(toward)


func return_home() -> void:
	await motion.return_home()


## A ranged or support move: crouch, rise and hold. Callers await it.
func cast_pose(hold: float) -> void:
	await motion.cast_pose(hold)


## A brief bright hit flash.
func flash() -> void:
	motion.flash()


## Hit: flash, squash, shake and a slide away from the attacker (push_x < 0 = left).
func hurt(push_x: float) -> void:
	motion.hurt(push_x)


func victory_hop() -> void:
	await motion.hop()


## Knocked out (collapsed and drained of colour) or back on their feet. `animate` plays the fall or the rise.
func set_down(down: bool, animate: bool = false) -> void:
	_down = down
	motion.set_down(down, animate and is_inside_tree())


func is_down() -> bool:
	return _down


## Sprite height in metres, for placing labels above a head.
func height() -> float:
	return float(_height_px) / _ppm


func width() -> float:
	return float(_width_px) / _ppm


func tint_down(share: float) -> void:
	material.set_shader_parameter(&"tint", Color.WHITE.lerp(DOWN_TINT, share))
	material.set_shader_parameter(&"desat", rules.ko_desat * share)


func _process(delta: float) -> void:
	_clock += delta
	var walk: Vector2 = Vector2.ONE
	var bob: float = 0.0
	if _moving:
		_bob_time += delta * rules.bob_speed
		var s: float = absf(sin(_bob_time))
		bob = s * rules.bob_height
		var squash: float = rules.walk_squash * (1.0 - s)
		walk = Vector2(1.0 + squash * 0.5, 1.0 - squash)
		_step_dust()
	elif not _prop and not _down:
		var breath: float = sin(_clock * rules.breath_speed) * rules.breath_amount
		walk = Vector2(1.0 - breath * 0.5, 1.0 + breath)
	var lean_goal: float = -_facing * rules.lean_degrees if _moving else 0.0
	_lean = lerpf(_lean, lean_goal, 1.0 - exp(-rules.lean_speed * delta))
	body.position.y = bob + lift
	body.rotation_degrees.z = _lean
	body.scale = Vector3(walk.x * pulse.x * down_scale.x, walk.y * pulse.y * down_scale.y, 1.0)
	fx.sync(root.position, bob + lift)


func _step_dust() -> void:
	var step: int = int(floorf(_bob_time / PI))
	if step != _steps:
		_steps = step
		fx.puff(root.position, -_facing * STEP_DUST_BACK)


func _apply(texture: ImageTexture) -> void:
	material.set_shader_parameter(&"albedo_tex", texture)
	_height_px = texture.get_height()
	_width_px = texture.get_width()
	_quad.scale = Vector3(width(), height(), 1.0)
	fx.set_picture(texture, Vector2(width(), height()))
