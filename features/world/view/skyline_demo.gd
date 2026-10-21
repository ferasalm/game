extends Node3D
## Skyline demo: the rooftop area inside the old city, seen from a chosen camera. Run with a mode after "--":
## iso (the exploration camera), vista (low camera looking north), wide (high, looking north), south
## (looking at Bab al-Yaman and Bayt Baws), west, east, or close [building id] (one tower-house up close).

@export var mode: String = "vista"
@export var building_id: StringName = &"tower_d"


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = args[0]
	if args.size() > 1:
		building_id = StringName(args[1])
	var look := ContentDB.get_def("look", &"v1") as LookDef
	add_child(Diorama.make_environment(look))
	add_child(Diorama.make_sun(look))
	var camera := Diorama.make_camera(look)
	if mode != "iso":
		camera.attributes = null
	add_child(camera)
	if mode == "close" or mode == "roof":
		_close(camera)
	else:
		_city(camera, look)
	camera.make_current()


func _city(camera: Camera3D, look: LookDef) -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var rules := ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef
	add_child(AreaBuilder.build(area, rules))
	add_child(SkylineBuilder.build(area))
	match mode:
		"iso":
			Diorama.aim(camera, Vector3(13.0, 0.5, 3.0), look)
		"vista":
			_aim(camera, Vector3(13.0, 1.5, 1.0), Vector3(13.0, 14.0, -100.0), 60.0)
		"wide":
			_aim(camera, Vector3(13.0, 9.0, 12.0), Vector3(13.0, 6.0, -80.0), 70.0)
		"south":
			_aim(camera, Vector3(18.0, 6.0, 12.0), Vector3(18.0, 2.0, 120.0), 70.0)
		"west":
			_aim(camera, Vector3(8.0, 6.0, 9.0), Vector3(-100.0, 6.0, 150.0), 70.0)
		_:
			_aim(camera, Vector3(20.0, 6.0, 9.0), Vector3(300.0, 20.0, -100.0), 70.0)


func _aim(camera: Camera3D, from: Vector3, to: Vector3, fov: float) -> void:
	camera.fov = fov
	camera.position = from
	camera.look_at(to)


func _close(camera: Camera3D) -> void:
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var def := ContentDB.get_def("building", building_id) as BuildingDef
	var node := MeshInstance3D.new()
	node.mesh = TowerHouse.mesh(def, palette)
	add_child(node)
	var h: float = def.total_height()
	if mode == "roof":
		_aim(camera, Vector3(7.0, h + 5.0, 9.0), Vector3(0.0, h, 0.0), 50.0)
	else:
		_aim(camera, Vector3(h * 1.1, h * 1.1, h * 1.5), Vector3(0.0, h * 0.45, 0.0), 40.0)
