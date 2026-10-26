extends Node
## Sprite baker (Neon Glitch iso sprites): renders one model's states from the iso camera in 8 screen directions into
## transparent PNG frames, for tools/art/sprite_sheet.py. Run (not headless) through the scene wrapper:
## "$(tools/godot.sh)" --path . --fixed-fps 60 res://tools/bake_sprites.tscn -- <model id> <out dir> [states]
## [size px] [ortho m]. A state is name:frames:seconds (default idle:8:1.0,run:8:0.6,attack:10:0.9,hurt:5:0.4,ko:10:1.2).

const LOOK_ID: StringName = &"painted_b"
const ELEVATION_DEG: float = 30.0  ## 2:1 dimetric floor, as in Feras's iso plates
const DIRS: int = 8
const SETTLE_FRAMES: int = 20  ## lets the yaw turn finish before a state is captured
const DEFAULT_STATES: String = "idle:8:1.0,run:8:0.6,attack:10:0.9,hurt:5:0.4,ko:10:1.2"

var _view: SubViewport
var _visual: CharacterVisual


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("bake_sprites: <model id> <out dir> [states] [size] [ortho]")
		get_tree().quit(1)
		return
	var size_px: int = int(args[3]) if args.size() > 3 else 256
	var ortho: float = float(args[4]) if args.size() > 4 else 2.6
	_build(StringName(args[0]), size_px, ortho)
	await _bake(String(args[0]), args[1], args[2] if args.size() > 2 else DEFAULT_STATES)
	get_tree().quit()


func _build(model_id: StringName, size_px: int, ortho: float) -> void:
	_view = SubViewport.new()
	_view.size = Vector2i(size_px, size_px)
	_view.transparent_bg = true
	_view.own_world_3d = true
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)
	var look := ContentDB.get_def("look", LOOK_ID) as LookDef
	PaintedLook.begin(look)
	var env: WorldEnvironment = Diorama.make_environment(look)
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.glow_enabled = false
	_view.add_child(env)
	_view.add_child(Diorama.make_sun(look))
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = ortho
	_view.add_child(camera)
	var elev: float = deg_to_rad(ELEVATION_DEG)
	camera.position = Vector3(0.0, 0.9 + sin(elev) * 10.0, cos(elev) * 10.0)
	camera.look_at(Vector3(0.0, 0.9, 0.0))
	camera.current = true
	_visual = CharacterVisual.new()
	_visual.set_sprite(model_id)
	_view.add_child(_visual)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color("#ffb060")
	lamp.light_energy = 1.2
	lamp.omni_range = 8.0
	lamp.position = Vector3(1.6, 2.4, 2.2)
	_view.add_child(lamp)


## Swaps every painted material for the bake look: the albedo as drawn (Rodin's ink texture), one soft key light fixed
## to the screen (upper left, the same for all 8 directions, as in 2D art) and a thicker flat ink hull.
func _restyle(root: Node) -> void:
	var shader := Shader.new()
	shader.code = BAKE_SHADER
	var hull_shader := Shader.new()
	hull_shader.code = HULL_SHADER
	for node: Node in NodeScan.of_type(root, &"MeshInstance3D"):
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		for i: int in mesh_node.mesh.get_surface_count():
			var old := mesh_node.get_active_material(i) as ShaderMaterial
			if old == null:
				continue
			var mat := ShaderMaterial.new()
			mat.shader = shader
			mat.set_shader_parameter(&"albedo_tex", old.get_shader_parameter(&"albedo_tex"))
			var tint: Variant = old.get_shader_parameter(&"tint")
			mat.set_shader_parameter(&"tint", tint if tint != null else Color.WHITE)
			var hull := ShaderMaterial.new()
			hull.shader = hull_shader
			mat.next_pass = hull
			mesh_node.set_surface_override_material(i, mat)
		mesh_node.material_override = null


const BAKE_SHADER: String = """
shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform vec4 tint : source_color = vec4(1.0);
void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb * tint.rgb * COLOR.rgb;
	float key = clamp(dot(NORMAL, normalize(vec3(-0.5, 0.6, 0.65))), 0.0, 1.0);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = c * (0.72 + 0.45 * key) + vec3(0.10, 0.16, 0.22) * rim;
}
"""
const HULL_SHADER: String = """
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
void vertex() { VERTEX += NORMAL * 0.022; }
void fragment() { ALBEDO = vec3(0.05, 0.04, 0.05); }
"""


## World facing for screen direction k (0 = screen right, counter-clockwise in 45 degree steps, 6 = toward camera).
static func ground_dir(k: int) -> Vector3:
	var phi: float = TAU * float(k) / float(DIRS)
	var d := Vector2(cos(phi), sin(phi) / sin(deg_to_rad(ELEVATION_DEG)))
	d = d.normalized()
	return Vector3(d.x, 0.0, -d.y)


func _bake(model_id: String, out_dir: String, states_arg: String) -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _frames(2)
	_restyle(_visual)
	for spec: String in states_arg.split(","):
		var parts: PackedStringArray = spec.split(":")
		var state := StringName(parts[0])
		var frames: int = int(parts[1]) if parts.size() > 1 else 8
		var seconds: float = float(parts[2]) if parts.size() > 2 else 1.0
		for k: int in DIRS:
			_visual.face_dir(ground_dir(k))
			_visual.play(&"idle")
			await _frames(SETTLE_FRAMES)
			_visual.play(state)
			for f: int in frames:
				await RenderingServer.frame_post_draw
				var img: Image = _view.get_texture().get_image()
				img.save_png("%s/%s_%s_d%d_f%02d.png" % [out_dir, model_id, state, k, f])
				await _frames(maxi(1, roundi(seconds * 60.0 / float(frames))) - 1)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame
