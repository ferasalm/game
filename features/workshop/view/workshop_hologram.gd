class_name WorkshopHologram
extends SubViewportContainer
## purpose: 760x620 SubViewport displaying a turning 3D hologram jambiyah or 256px item icon.

const ROTATE_SPEED_DEG: float = 20.0

var _sub_viewport: SubViewport
var _camera: Camera3D
var _light: DirectionalLight3D
var _disc: MeshInstance3D
var _jambiyah_root: Node3D
var _icon_rect: TextureRect


func _init() -> void:
	custom_minimum_size = Vector2(760.0, 620.0)
	size = Vector2(760.0, 620.0)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_build_stage()
	_build_jambiyah()


func _process(delta: float) -> void:
	if _jambiyah_root != null and _jambiyah_root.visible:
		_jambiyah_root.rotation.y += deg_to_rad(ROTATE_SPEED_DEG) * delta


## Shows the turning 3D jambiyah hologram.
func show_jambiyah() -> void:
	if _jambiyah_root != null:
		_jambiyah_root.visible = true
	if _disc != null:
		_disc.visible = true
	if _icon_rect != null:
		_icon_rect.visible = false


## Shows a 256px 2D item icon instead of the 3D jambiyah.
func show_icon(tex: Texture2D) -> void:
	if _jambiyah_root != null:
		_jambiyah_root.visible = false
	if _disc != null:
		_disc.visible = false
	if _icon_rect == null:
		_icon_rect = TextureRect.new()
		_icon_rect.custom_minimum_size = Vector2(256.0, 256.0)
		_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon_rect.set_anchors_preset(Control.PRESET_CENTER)
		_icon_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_icon_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
		add_child(_icon_rect)
	_icon_rect.texture = tex
	_icon_rect.visible = (tex != null)


func _build_stage() -> void:
	_sub_viewport = SubViewport.new()
	_sub_viewport.size = Vector2i(760, 620)
	_sub_viewport.own_world_3d = true
	_sub_viewport.transparent_bg = true
	_sub_viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sub_viewport)

	_camera = Camera3D.new()
	_camera.transform = Transform3D(Basis(), Vector3(0.0, 0.45, 1.3))
	_camera.fov = 35.0
	_camera.current = true
	_sub_viewport.add_child(_camera)

	_light = DirectionalLight3D.new()
	_light.rotation_degrees = Vector3(-20.0, 30.0, 0.0)
	_light.light_energy = 1.0
	_sub_viewport.add_child(_light)

	var cyan: Color = Ui.style().colour(&"c_cyan")
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = 0.45
	disc_mesh.bottom_radius = 0.45
	disc_mesh.height = 0.01

	var disc_mat := StandardMaterial3D.new()
	disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.albedo_color = Color(cyan.r, cyan.g, cyan.b, 0.25)

	_disc = MeshInstance3D.new()
	_disc.mesh = disc_mesh
	_disc.material_override = disc_mat
	_disc.position = Vector3(0.0, 0.05, 0.0)
	_sub_viewport.add_child(_disc)


func _build_jambiyah() -> void:
	_jambiyah_root = Node3D.new()
	_jambiyah_root.position = Vector3(0.0, 0.48, 0.0)
	_jambiyah_root.scale = Vector3.ONE * 2.6
	_sub_viewport.add_child(_jambiyah_root)

	var part := ModelPartDef.new()
	part.metal = Color("#c9cdd3")
	part.accent = Color("#d9503f")
	part.sheath_color = Color("#3a2a20")
	var made: Dictionary = HiltMesh.build(part)

	var holo_shader: Shader = load("res://features/equipment/view/hologram.gdshader") as Shader
	var holo_mat := ShaderMaterial.new()
	holo_mat.shader = holo_shader

	var hilt_mesh: Mesh = made.get(&"hilt") as Mesh
	if hilt_mesh != null:
		var hilt_inst := MeshInstance3D.new()
		hilt_inst.mesh = hilt_mesh
		hilt_inst.material_override = holo_mat
		_jambiyah_root.add_child(hilt_inst)

	var blade_mesh: Mesh = made.get(&"blade") as Mesh
	if blade_mesh != null:
		var blade_inst := MeshInstance3D.new()
		blade_inst.mesh = blade_mesh
		blade_inst.material_override = holo_mat
		_jambiyah_root.add_child(blade_inst)
