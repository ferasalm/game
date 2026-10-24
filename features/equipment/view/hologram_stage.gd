class_name HologramStage
extends SubViewportContainer
## purpose: 800x760 SubViewportContainer with 3D hologram hero, camera, disc and leader lines.

const ROTATE_SPEED_DEG: float = 20.0

var _sub_viewport: SubViewport
var _camera: Camera3D
var _light: DirectionalLight3D
var _disc: MeshInstance3D
var _visual: CharacterVisual
var _holo_mat: ShaderMaterial
var _lines: Dictionary[StringName, Line2D] = {}
var _box_anchors: Dictionary[StringName, Dictionary] = {}
var _active_slot: StringName = &"blade"


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
	_visual = CharacterVisual.new()
	_visual.process_mode = Node.PROCESS_MODE_ALWAYS
	_visual.set_sprite(hero)
	_visual.play(&"idle")
	_sub_viewport.add_child(_visual)
	_apply_hologram()


func set_active_slot(slot_name: StringName) -> void:
	_active_slot = slot_name
	_update_line_styles()


func register_box(part_name: StringName, box: Control, anchor_name: StringName) -> void:
	var style: UiStyleDef = Ui.style()
	var line := Line2D.new()
	line.width = float(style.size(&"s_frame_line"))
	line.default_color = style.colour(&"c_cyan")
	line.top_level = true
	add_child(line)
	_lines[part_name] = line
	_box_anchors[part_name] = {"box": box, "anchor": anchor_name}


func visual() -> CharacterVisual:
	return _visual


func hologram_material() -> ShaderMaterial:
	return _holo_mat


func disc() -> MeshInstance3D:
	return _disc


func model_meshes() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if _visual != null:
		for mesh: Node in NodeScan.of_type(_visual, &"MeshInstance3D"):
			out.append(mesh as MeshInstance3D)
	return out


func sub_viewport() -> SubViewport:
	return _sub_viewport


func lines() -> Dictionary[StringName, Line2D]:
	return _lines


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
	var disc_mesh := PlaneMesh.new()
	disc_mesh.size = Vector2(2.2, 2.2)
	var grid_shader: Shader = load("res://features/equipment/view/grid_disc.gdshader") as Shader
	var disc_mat := ShaderMaterial.new()
	disc_mat.shader = grid_shader
	var cyan: Color = Ui.style().colour(&"c_cyan")
	disc_mat.set_shader_parameter(&"grid_color", Color(cyan.r, cyan.g, cyan.b, 0.85))
	disc_mat.set_shader_parameter(&"grid_spacing", 0.15)
	disc_mat.set_shader_parameter(&"disc_radius", 1.05)
	_disc = MeshInstance3D.new()
	_disc.mesh = disc_mesh
	_disc.material_override = disc_mat
	_disc.position = Vector3(0.0, 0.005, 0.0)
	_sub_viewport.add_child(_disc)


func _apply_hologram() -> void:
	if _visual == null:
		return
	var holo_shader: Shader = load("res://features/equipment/view/hologram.gdshader") as Shader
	if holo_shader == null:
		return
	_holo_mat = ShaderMaterial.new()
	_holo_mat.shader = holo_shader
	var cyan: Color = Ui.style().colour(&"c_cyan")
	_holo_mat.set_shader_parameter(&"rim_color", Color(cyan.r, cyan.g, cyan.b, 0.85))
	for mesh: Node in NodeScan.of_type(_visual, &"MeshInstance3D"):
		(mesh as MeshInstance3D).material_override = _holo_mat


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
		var is_left: bool = box.global_position.x < 800.0
		var box_x: float = box.global_position.x + (box.size.x if is_left else 0.0)
		var box_edge := Vector2(box_x, box.global_position.y + box.size.y * 0.5)
		var body_3d: Vector3 = _get_anchor_pos(entry["anchor"] as StringName)
		var proj: Vector2 = _camera.unproject_position(body_3d)
		var body_screen: Vector2 = global_position + proj
		line.points = PackedVector2Array([box_edge, body_screen])
	_update_line_styles()


func _get_anchor_pos(anchor_name: StringName) -> Vector3:
	if _visual == null:
		return Vector3.ZERO
	return _visual.anchor_position(anchor_name)


func _update_line_styles() -> void:
	var style: UiStyleDef = Ui.style()
	var w_active: float = float(style.size(&"s_sweep_h"))
	var w_norm: float = float(style.size(&"s_frame_line"))
	for part_name: StringName in _lines:
		var line: Line2D = _lines[part_name]
		var is_act: bool = (part_name == _active_slot)
		line.default_color = style.colour(&"c_brass" if is_act else &"c_cyan")
		line.width = w_active if is_act else w_norm
		line.z_index = 1 if is_act else 0
