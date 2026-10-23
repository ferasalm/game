extends Node3D
## Renders Tayramana framed shots with the party seated to C:/dev/game/inbox/tayramana_*.png (960x540).
## Run: "$(tools/godot.sh)" --path . --resolution 960x540 tools/shot_tayramana.tscn

const DOOR_SHOT_PATH: String = "C:/dev/game/inbox/tayramana_door.png"
const WINDOW_SHOT_PATH: String = "C:/dev/game/inbox/tayramana_window.png"

var _room: TayramanaRoom
var _frame: int = 0
var _door_shot: RoomDef.Shot
var _window_shot: RoomDef.Shot


func _ready() -> void:
	if GameState.party.is_empty():
		GameState.start_new()
	var spec := ContentDB.get_def("room", &"tayramana") as RoomDef
	var rules := ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var rig := ContentDB.get_def("camera_rig", &"explore") as CameraRigDef
	for s: RoomDef.Shot in spec.shots:
		if s.id == &"shot_door":
			_door_shot = s
		elif s.id == &"shot_window":
			_window_shot = s
	_room = TayramanaRoom.new(rules, spec, palette, rig)
	add_child(_room)
	_room.sit_party(true)
	_apply_shot(_door_shot)


func _apply_shot(shot: RoomDef.Shot) -> void:
	if shot == null or _room == null:
		return
	_room.manual_camera = true
	_room.camera.global_position = shot.cam_pos
	_room.camera.look_at(shot.look_target)
	_room.camera.fov = shot.fov
	_room.camera.make_current()


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 20:
		_save_image(DOOR_SHOT_PATH)
		_apply_shot(_window_shot)
	elif _frame == 40:
		_save_image(WINDOW_SHOT_PATH)
		get_tree().quit()


func _save_image(path: String) -> void:
	var vp: Viewport = get_viewport()
	var img: Image = vp.get_texture().get_image()
	if img.get_width() != 960 or img.get_height() != 540:
		img.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute("C:/dev/game/inbox")
	var err: Error = img.save_png(path)
	print("Saved render: ", path, " (960x540) err=", err)
