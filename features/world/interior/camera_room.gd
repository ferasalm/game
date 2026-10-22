class_name CameraRoom
extends Node3D
## Grey-box interior test room demonstrating FramedShots and FollowCameraRig in framed indoor mode.

var camera: Camera3D
var player: Player
var camera_rig: FollowCameraRig
var framed_shots: FramedShots
var spec: CameraRoomDef

var _mat_floor: StandardMaterial3D
var _mat_wall: StandardMaterial3D
var _mat_bench: StandardMaterial3D


func _ready() -> void:
	var rig_def := ContentDB.get_def("camera_rig", &"explore") as CameraRigDef
	var rules := ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef
	if rig_def == null or rig_def.test_room == null or rules == null:
		push_error("CameraRoom: missing camera_rig or explore_rules")
		return
	spec = rig_def.test_room
	_create_materials()
	_build_room()
	_setup_lighting()
	_setup_player(rules)
	_setup_camera(rig_def)


func set_player_pos(pos: Vector3) -> void:
	if player != null:
		player.position = pos
		if camera_rig != null:
			camera_rig.update(0.0, pos)


func active_shot_id() -> StringName:
	if framed_shots != null and framed_shots.active_shot != null:
		return framed_shots.active_shot.id
	return &""


func _process(delta: float) -> void:
	if camera_rig != null and player != null:
		camera_rig.update(delta, player.position)


func _create_materials() -> void:
	_mat_floor = StandardMaterial3D.new()
	_mat_floor.albedo_color = Color(0.42, 0.42, 0.45)
	_mat_wall = StandardMaterial3D.new()
	_mat_wall.albedo_color = Color(0.72, 0.70, 0.65)
	_mat_bench = StandardMaterial3D.new()
	_mat_bench.albedo_color = Color(0.32, 0.22, 0.15)


func _build_room() -> void:
	_add_box(Vector3(spec.floor_w, 0.1, spec.floor_d),
		Vector3(spec.floor_w * 0.5, -0.05, spec.floor_d * 0.5), _mat_floor)
	_add_box(Vector3(spec.bench_w, spec.bench_h, spec.bench_d),
		Vector3(spec.bench_x, spec.bench_h * 0.5, spec.bench_z), _mat_bench)
	var t: float = spec.wall_t
	var h: float = spec.wall_h
	_add_box(Vector3(t, h, spec.floor_d + 2.0 * t), Vector3(-t * 0.5, h * 0.5, spec.floor_d * 0.5), _mat_wall)
	_add_box(Vector3(t, h, spec.floor_d + 2.0 * t),
		Vector3(spec.floor_w + t * 0.5, h * 0.5, spec.floor_d * 0.5), _mat_wall)
	_add_box(Vector3(spec.floor_w, h, t), Vector3(spec.floor_w * 0.5, h * 0.5, spec.floor_d + t * 0.5), _mat_wall)
	_build_window_wall()


func _build_window_wall() -> void:
	var t: float = spec.wall_t
	var h: float = spec.wall_h
	var z: float = -t * 0.5
	var gw: float = spec.window_gap_w
	var gy: float = spec.window_gap_y
	var gh: float = spec.window_gap_h
	_add_box(Vector3(1.2, h, t), Vector3(0.6, h * 0.5, z), _mat_wall)
	_add_box(Vector3(gw, gy, t), Vector3(1.2 + gw * 0.5, gy * 0.5, z), _mat_wall)
	_add_box(Vector3(gw, h - (gy + gh), t), Vector3(1.2 + gw * 0.5, gy + gh + (h - (gy + gh)) * 0.5, z), _mat_wall)
	var mid_start: float = 1.2 + gw
	var mid_w: float = spec.floor_w - (1.2 * 2.0 + gw * 2.0)
	_add_box(Vector3(mid_w, h, t), Vector3(mid_start + mid_w * 0.5, h * 0.5, z), _mat_wall)
	var win2_start: float = mid_start + mid_w
	_add_box(Vector3(gw, gy, t), Vector3(win2_start + gw * 0.5, gy * 0.5, z), _mat_wall)
	_add_box(Vector3(gw, h - (gy + gh), t), Vector3(win2_start + gw * 0.5, gy + gh + (h - (gy + gh)) * 0.5, z), _mat_wall)
	_add_box(Vector3(1.2, h, t), Vector3(spec.floor_w - 0.6, h * 0.5, z), _mat_wall)


func _add_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = mat
	mi.mesh = box
	mi.position = pos
	add_child(mi)
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _setup_lighting() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.14, 0.20)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.60)
	env.ambient_light_energy = 0.8
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, 30.0, 0.0)
	sun.light_energy = 0.9
	sun.light_color = Color(1.0, 0.95, 0.88)
	sun.shadow_enabled = true
	add_child(sun)


func _setup_player(rules: ExploreRulesDef) -> void:
	player = Player.new(rules)
	player.position = Vector3(2.0, 0.0, 3.5)
	add_child(player)


func _setup_camera(rig_def: CameraRigDef) -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.make_current()
	framed_shots = FramedShots.new(rig_def.framed_hysteresis, rig_def.framed_clamp_deg,
		rig_def.stick_retention_deg)
	for s: CameraRoomDef.Shot in spec.shots:
		framed_shots.add_shot(s.id, s.cam_pos, s.look_target, s.rect, s.fov)
	camera_rig = FollowCameraRig.new()
	add_child(camera_rig)
	camera_rig.setup_framed(camera, framed_shots, player)
