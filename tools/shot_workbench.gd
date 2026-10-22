extends Node
## Renders the workbench prop close up and in the rooftop from the play camera to inbox PNGs (960x540).
## Run: "$(tools/godot.sh)" --path . --resolution 960x540 -s res://tools/shot_workbench.gd -- [closeup|rooftop]

const CLOSEUP_PATH: String = "C:/dev/game/inbox/workbench_closeup.png"
const ROOFTOP_PATH: String = "C:/dev/game/inbox/workbench_rooftop.png"
const LOOK_ID: StringName = &"painted_b"

var _mode: String = "closeup"
var _frame: int = 0
var _rooftop: Rooftop = null


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_mode = "rooftop" if "rooftop" in args else "closeup"
	if _mode == "rooftop":
		_setup_rooftop()
	else:
		_setup_closeup()


func _setup_closeup() -> void:
	var look := ContentDB.get_def("look", LOOK_ID) as LookDef
	PaintedLook.begin(look)
	var env: WorldEnvironment = Diorama.make_environment(look)
	add_child(env)
	add_child(Diorama.make_sun(look))
	_make_floor()
	var rules := ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef
	var player := Player.new(rules)
	var spot := WorkshopSpot.new(rules, player)
	add_child(spot)
	spot.position = Vector3(0.0, 0.0, 0.0)
	var camera := Camera3D.new()
	camera.fov = 38.0
	camera.position = Vector3(0.0, 0.95, 1.85)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.42, 0.0))
	camera.current = true
	PaintedLook.finish(self, look, env.environment, camera, null)


func _make_floor() -> void:
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(8.0, 0.2, 8.0)
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = floor_mesh
	floor_node.position = Vector3(0.0, -0.1, 0.0)
	add_child(floor_node)


func _setup_rooftop() -> void:
	var rooftop_scene: PackedScene = load("res://features/world/rooftop/rooftop.tscn") as PackedScene
	_rooftop = rooftop_scene.instantiate() as Rooftop
	add_child(_rooftop)
	_rooftop.camera_rig.hold_intro(false)
	_rooftop.camera_rig.intro_finished.emit()
	var place: PlaceDef = _rooftop._area.place(&"workshop")
	if place != null:
		var target: Vector3 = _rooftop.workshop.interact_point()
		_rooftop.teleport_party(target, false)
	_rooftop._process(Rooftop.SNAP_SECONDS)


func _process(_delta: float) -> void:
	_frame += 1
	if _rooftop != null and _frame < 10:
		_rooftop._process(_delta)
	if _frame >= 10:
		_save_and_quit()


func _save_and_quit() -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var out_path: String = ROOFTOP_PATH if _mode == "rooftop" else CLOSEUP_PATH
	DirAccess.make_dir_recursive_absolute("C:/dev/game/inbox")
	img.save_png(out_path)
	print("Saved render to %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
	get_tree().quit()
