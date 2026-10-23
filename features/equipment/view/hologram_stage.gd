class_name HologramStage
extends SubViewportContainer
## purpose: 800x760 SubViewportContainer with 3D hologram hero, camera, disc and leader lines.

const ROTATE_SPEED_DEG: float = 20.0

var _sub_viewport: SubViewport
var _camera: Camera3D
var _light: DirectionalLight3D
var _disc: MeshInstance3D
var _visual: CharacterVisual
var _lines: Dictionary[StringName, Line2D] = {}
var _box_anchors: Dictionary[StringName, Dictionary] = {}


func _init() -> void:
	custom_minimum_size = Vector2(800.0, 760.0)
	size = Vector2(800.0, 760.0)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_build_stage()


func _process(delta: float) -> void:
	if _visual != null:
		_visual.rotation.y += deg_to_rad(ROTATE_SPEED_DEG) * delta
	_update_leader_lines()


func set_hero(hero: StringName) -> void:
	if _sub_viewport == null:
		return
	if _visual != null:
		_sub_viewport.remove_child(_visual)
		_visual.queue_free()
		_visual = null
	_visual = CharacterVisual.new()
	_visual.process_mode = Node.PROCESS_MODE_ALWAYS
	_visual.set_sprite(hero)
	_visual.play(&"idle")
	_sub_viewport.add_child(_visual)
	_apply_hologram()


func register_box(part_name: StringName, box: Control, anchor_name: StringName) -> void:
	var style: UiStyleDef = Ui.style()
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = style.colour(&"c_cyan")
	line.top_level = true
	add_child(line)
	_lines[part_name] = line
	_box_anchors[part_name] = {"box": box, "anchor": anchor_name}


func visual() -> CharacterVisual:
	return _visual


func sub_viewport() -> SubViewport:
	return _sub_viewport


func _build_stage() -> void:
	_sub_viewport = SubViewport.new()
	_sub_viewport.size = Vector2i(800, 760)
	_sub_viewport.own_world_3d = true
	_sub_viewport.transparent_bg = true
	_sub_viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sub_viewport)

	_camera = Camera3D.new()
	_camera.transform = Transform3D(Basis(), Vector3(0.0, 0.95, 2.7))
	_camera.fov = 40.0
	_camera.current = true
	_sub_viewport.add_child(_camera)

	_light = DirectionalLight3D.new()
	_light.rotation_degrees = Vector3(-15.0, 0.0, 0.0)
	_light.light_energy = 1.0
	_sub_viewport.add_child(_light)

	_build_grid_disc()


func _build_grid_disc() -> void:
	var style: UiStyleDef = Ui.style()
	var cyan: Color = style.colour(&"c_cyan")
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = 0.45
	disc_mesh.bottom_radius = 0.45
	disc_mesh.height = 0.01

	var disc_mat := StandardMaterial3D.new()
	disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.albedo_color = Color(cyan.r, cyan.g, cyan.b, 0.3)

	_disc = MeshInstance3D.new()
	_disc.mesh = disc_mesh
	_disc.material_override = disc_mat
	_disc.position = Vector3(0.0, 0.005, 0.0)
	_sub_viewport.add_child(_disc)


func _apply_hologram() -> void:
	if _visual == null or not (_visual.source is ModelSource):
		return
	var holo_shader: Shader = load("res://features/equipment/view/hologram.gdshader") as Shader
	if holo_shader == null:
		return
	var holo_mat := ShaderMaterial.new()
	holo_mat.shader = holo_shader
	var mats: Array[ShaderMaterial] = (_visual.source as ModelSource).materials()
	for mat: ShaderMaterial in mats:
		if mat == null:
			continue
		if mat.next_pass != null:
			mat.next_pass.next_pass = holo_mat
		else:
			mat.next_pass = holo_mat


func _update_leader_lines() -> void:
	if _camera == null or _visual == null:
		return
	for part_name: StringName in _box_anchors:
		var entry: Dictionary = _box_anchors[part_name]
		var box: Control = entry["box"] as Control
		var line: Line2D = _lines.get(part_name)
		if line == null:
			continue
		if box == null or not box.is_visible_in_tree():
			line.visible = false
			continue
		line.visible = true
		var box_x: float = box.global_position.x + (box.size.x if box.global_position.x < 800.0 else 0.0)
		var box_edge := Vector2(box_x, box.global_position.y + box.size.y * 0.5)
		var body_3d: Vector3 = _get_anchor_pos(entry["anchor"] as StringName)
		var proj: Vector2 = _camera.unproject_position(body_3d)
		var body_screen: Vector2 = global_position + proj
		line.points = PackedVector2Array([box_edge, body_screen])


func _get_anchor_pos(anchor_name: StringName) -> Vector3:
	if _visual == null:
		return Vector3.ZERO
	var pos: Vector3 = _visual.anchor_position(anchor_name)
	if pos == _visual.global_position + _visual.root.position:
		var h: float = _visual.height()
		if h <= 0.0:
			h = 1.8
		match anchor_name:
			&"chest":
				pos.y += h * 0.7
			&"belt":
				pos.y += h * 0.5
			&"arm":
				pos.y += h * 0.6
				pos.x -= 0.25
			&"hand":
				pos.y += h * 0.45
				pos.x += 0.3
	return pos
