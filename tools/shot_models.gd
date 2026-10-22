extends Node3D
## Model gallery for renders (docs/design/characters-3d.md): the cast in a row on a floor under the painted look, each
## doing a state, close enough to judge the stand-ins. Run (not headless) through the movie writer:
## "$(tools/godot.sh)" --path . --write-movie DIR/f.png --fixed-fps 60 --quit-after N -s res://tools/shot_scene.gd
## -- res://tools/shot_models.gd [state] [cam_y] [cam_z] [yaw_deg] [ids, comma separated]

const LOOK_ID: StringName = &"painted_b"
const CAST: String = "zayd,bilqis,abu_nabil,concession_enforcer,survey_drone"

var _visuals: Array[CharacterVisual] = []
var _state: StringName = &"idle"


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_state = StringName(args[1]) if args.size() > 1 else &"idle"
	var cam_y: float = float(args[2]) if args.size() > 2 else 1.3
	var cam_z: float = float(args[3]) if args.size() > 3 else 6.0
	var yaw: float = deg_to_rad(float(args[4])) if args.size() > 4 else 0.0
	var ids: PackedStringArray = (args[5] if args.size() > 5 else CAST).split(",")
	var look := ContentDB.get_def("look", LOOK_ID) as LookDef
	PaintedLook.begin(look)
	var env: WorldEnvironment = Diorama.make_environment(look)
	add_child(env)
	add_child(Diorama.make_sun(look))
	_floor()
	var camera := Camera3D.new()
	camera.fov = 30.0
	add_child(camera)
	camera.position = Vector3(0.0, cam_y, cam_z)
	camera.look_at(Vector3(0.0, 0.9, 0.0))
	camera.current = true
	for i: int in ids.size():
		var visual := CharacterVisual.new()
		visual.set_sprite(StringName(ids[i]))
		add_child(visual)
		visual.position = Vector3((float(i) - (ids.size() - 1) * 0.5) * 1.5, 0.0, 0.0)
		visual.face_dir(Vector3(sin(yaw), 0.0, cos(yaw)))
		_visuals.append(visual)
	PaintedLook.finish(self, look, env.environment, camera, null)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color("#ffb060")
	lamp.light_energy = 2.0
	lamp.omni_range = 9.0
	lamp.position = Vector3(1.5, 2.6, 2.0)
	add_child(lamp)
	for visual: CharacterVisual in _visuals:
		visual.play(_state, Vector2.ZERO)
		if _state == &"attack":
			visual.hit_stop(0.0)


func _floor() -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20.0, 20.0)
	mesh.mesh = plane
	mesh.material_override = Diorama.material(Color(0.62, 0.52, 0.4))
	add_child(mesh)
