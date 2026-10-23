class_name TayramanaRoom
extends Node3D
## purpose: View and controller for the Tayramana rooftop majlis room: shell, props, framed shots, sit and workshop.

signal door_exited
signal workshop_opened
signal sit_interacted(spot_id: StringName)

var camera: Camera3D
var camera_rig: FollowCameraRig
var framed_shots: FramedShots
var player: Player
var follower: Follower
var door: DoorSpot
var workshop: WorkshopSpot
var sit_spots: Array[RoomSitSpot] = []
var spec: RoomDef
var room_node: Node3D
var manual_camera: bool = false

var _mat_env: WorldEnvironment
var _rules: ExploreRulesDef
var _rig_def: CameraRigDef


func _init(rules: ExploreRulesDef, room_spec: RoomDef, palette: PaletteDef, rig_def: CameraRigDef) -> void:
	spec = room_spec
	_rules = rules
	_rig_def = rig_def
	_setup_world(palette)
	_setup_actors(rules)
	_setup_interacts(rules)


func _ready() -> void:
	if _rig_def != null:
		_setup_camera(_rig_def)


func _setup_world(palette: PaletteDef) -> void:
	room_node = RoomBuilder.build(spec, palette)
	add_child(room_node)
	_setup_lighting()


func _setup_lighting() -> void:
	_mat_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.09, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.10, 0.16)
	env.ambient_light_energy = 0.2
	_mat_env.environment = env
	add_child(_mat_env)
	var lamp1 := OmniLight3D.new()
	lamp1.name = "LampMajlis"
	lamp1.position = Vector3(2.5, 2.2, 2.0)
	lamp1.light_color = Color("#ffb070")
	lamp1.light_energy = 1.3
	lamp1.omni_range = 6.5
	add_child(lamp1)
	var lamp2 := OmniLight3D.new()
	lamp2.name = "LampWorkshop"
	lamp2.position = Vector3(5.2, 2.2, 3.2)
	lamp2.light_color = Color("#ffb070")
	lamp2.light_energy = 1.2
	lamp2.omni_range = 6.0
	add_child(lamp2)


func _setup_actors(rules: ExploreRulesDef) -> void:
	player = Player.new(rules)
	player.position = spec.entry_pos
	player.rotation.y = deg_to_rad(spec.entry_yaw)
	add_child(player)
	follower = Follower.new(rules, player)
	add_child(follower)
	follower.stand_by_player()


func _setup_interacts(rules: ExploreRulesDef) -> void:
	var exit_place := PlaceDef.new()
	exit_place.id = &"door_exit"
	exit_place.prompt = &"WORLD_PROMPT_EXIT"
	exit_place.target = &"rooftop"
	door = DoorSpot.new(rules, player, exit_place, rules.prompt_height)
	door.position = Vector3(spec.entry_pos.x, 0.0, spec.size.z - 0.4)
	door.entered.connect(func(_t: StringName) -> void: door_exited.emit())
	add_child(door)
	var bench_place := PlaceDef.new()
	bench_place.id = &"workshop"
	bench_place.kind = &"workshop"
	bench_place.pos = Vector3(5.4, 0.0, 3.8)
	bench_place.yaw = 270.0
	bench_place.prop = &"workbench"
	workshop = WorkshopSpot.new(rules, player, bench_place, false)
	workshop.position = Vector3(5.4, 0.0, 3.8)
	workshop.opened.connect(workshop_opened.emit)
	add_child(workshop)
	for s: RoomDef.SitSpot in spec.sit_spots:
		var spot := RoomSitSpot.new(rules, player, s.id)
		spot.position = s.pos
		spot.sat.connect(func(sid: StringName) -> void: sit_interacted.emit(sid))
		sit_spots.append(spot)
		add_child(spot)


func _setup_camera(rig_def: CameraRigDef) -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.make_current()
	framed_shots = FramedShots.new(rig_def.framed_hysteresis, rig_def.framed_clamp_deg,
		rig_def.stick_retention_deg)
	for s: RoomDef.Shot in spec.shots:
		framed_shots.add_shot(s.id, s.cam_pos, s.look_target, s.rect, s.fov)
	camera_rig = FollowCameraRig.new()
	add_child(camera_rig)
	camera_rig.setup_framed(camera, framed_shots, player)


func _process(delta: float) -> void:
	if not manual_camera and camera_rig != null and player != null:
		camera_rig.update(delta, player.position)


func freeze_actors(freeze: bool) -> void:
	if player != null:
		player.set_active(not freeze)
	if follower != null:
		follower.set_active(not freeze)


func sit_party(kneel: bool) -> void:
	for spot: RoomSitSpot in sit_spots:
		spot.set_active(not kneel)
	if kneel:
		var zayd_pos: Vector3 = spec.sit_spots[0].pos if spec.sit_spots.size() > 0 else Vector3(2.3, 0.0, 2.0)
		var bilqis_pos: Vector3 = spec.sit_spots[1].pos if spec.sit_spots.size() > 1 else Vector3(3.9, 0.0, 2.0)
		player.position = zayd_pos
		player.visual().face(1.0)
		player.visual().root.scale = Vector3(1.15, 0.65, 1.15)
		player.visual().root.position.y = 0.13
		player.visual().set_moving(false)
		follower.position = bilqis_pos
		follower.visual().face(-1.0)
		follower.visual().root.scale = Vector3(1.15, 0.65, 1.15)
		follower.visual().root.position.y = 0.13
		follower.visual().set_moving(false)
	else:
		player.visual().root.scale = Vector3.ONE
		player.visual().root.position.y = 0.0
		follower.visual().root.scale = Vector3.ONE
		follower.visual().root.position.y = 0.0
		follower.stand_by_player()


func active_shot_id() -> StringName:
	if framed_shots != null and framed_shots.active_shot != null:
		return framed_shots.active_shot.id
	return &""


## The camera eases onto the workbench and the workshop menu opens (prototype_main, after the first-visit talk).
func focus_workbench() -> UiScreen:
	return await InteractFocus.open_spot(workshop, &"workbench", player, Screens.WORKSHOP_ID)
