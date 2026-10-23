extends Node
## Renders a prop close-up from play camera height to an inbox PNG (960x540).
## Run: "$(tools/godot.sh)" --path . --resolution 960x540 res://tools/shot_prop.tscn -- <prop_id>

const OUT_DIR: String = "C:/dev/game/inbox"
const LOOK_ID: StringName = &"painted_b"
const SETTLE_FRAMES: int = 20

var _prop_id: StringName = &"sabil"
var _frame: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0 and not args[0].begins_with("-"):
		_prop_id = StringName(args[0])
	_setup_scene()


func _setup_scene() -> void:
	var look := ContentDB.get_def("look", LOOK_ID) as LookDef
	PaintedLook.begin(look)
	var env: WorldEnvironment = Diorama.make_environment(look)
	add_child(env)
	add_child(Diorama.make_sun(look))
	_make_floor()
	var mesh_node: MeshInstance3D = _make_prop()
	var camera: Camera3D = _make_camera()
	PaintedLook.finish(self, look, env.environment, camera, null)


func _make_floor() -> void:
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(10.0, 0.2, 10.0)
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = floor_mesh
	floor_node.position = Vector3(0.0, -0.1, 0.0)
	add_child(floor_node)


func _make_prop() -> MeshInstance3D:
	var prop_def := ContentDB.get_def("prop", _prop_id) as PropDef
	if prop_def == null:
		push_error("unknown prop id '%s'" % _prop_id)
		return null
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var mesh: ArrayMesh = PropMesh.mesh(prop_def, palette)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	add_child(node)
	if prop_def.splash != null:
		add_child(PropFx.splash(prop_def.splash, Transform3D.IDENTITY))
	if prop_def.light != null:
		var area_lights := AreaLights.new([prop_def.light], node, 1, 3.0)
		add_child(area_lights)
	return node


func _make_camera() -> Camera3D:
	var camera := Camera3D.new()
	camera.fov = 42.0
	add_child(camera)
	if _prop_id == &"herb_stall":
		camera.position = Vector3(0.0, 1.85, 3.2)
		camera.look_at(Vector3(0.0, 1.1, 0.15))
	else:
		camera.position = Vector3(0.0, 2.1, 3.6)
		camera.look_at(Vector3(0.0, 1.35, 0.0))
	camera.current = true
	return camera


func _process(_delta: float) -> void:
	_frame += 1
	if _frame >= SETTLE_FRAMES:
		_save_and_quit()


func _save_and_quit() -> void:
	var img: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var out_path: String = OUT_DIR.path_join("prop_%s.png" % _prop_id)
	img.save_png(out_path)
	print("Saved render to %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
	get_tree().quit()
