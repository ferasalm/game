extends Node
## purpose: Renders interact-focus framed shots for herb stall, sabil and workbench to C:/dev/game/inbox/.
## Run: "$(tools/godot.sh)" --path . --resolution 960x540 res://tools/shot_focus.tscn

const STALL_PATH: String = "C:/dev/game/inbox/focus_stall.png"
const SABIL_PATH: String = "C:/dev/game/inbox/focus_sabil.png"
const BENCH_PATH: String = "C:/dev/game/inbox/focus_bench.png"
const EASE_FRAMES: int = 45

var _frame: int = 0
var _rooftop: Rooftop = null
var _room: TayramanaRoom = null
var _focus: InteractFocus = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if GameState.party.is_empty():
		GameState.start_new()
	var rooftop_scene: PackedScene = load("res://features/world/rooftop/rooftop.tscn") as PackedScene
	_rooftop = rooftop_scene.instantiate() as Rooftop
	add_child(_rooftop)
	_rooftop.camera_rig.hold_intro(false)
	_rooftop.camera_rig.intro_finished.emit()
	_start_stall()


func _start_stall() -> void:
	_rooftop.teleport_party(_rooftop.stall.position + Vector3(0.0, 0.0, 1.2), false)
	_rooftop.stall._interact()


func _start_sabil() -> void:
	_rooftop.teleport_party(_rooftop.sabil.position + Vector3(0.0, 0.0, 1.2), false)
	_rooftop.sabil.open_screen()


func _start_bench() -> void:
	if _rooftop != null:
		_rooftop.queue_free()
		_rooftop = null
	var spec := ContentDB.get_def("room", &"tayramana") as RoomDef
	var rules := ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var rig := ContentDB.get_def("camera_rig", &"explore") as CameraRigDef
	_room = TayramanaRoom.new(rules, spec, palette, rig)
	add_child(_room)
	_focus = InteractFocus.new()
	add_child(_focus)
	_room.player.position = _room.workshop.position + Vector3(0.0, 0.0, 1.2)
	_room.workshop.opened.emit()


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == EASE_FRAMES:
		_save_image(STALL_PATH)
		Screens.pop()
	elif _frame == EASE_FRAMES * 2:
		_start_sabil()
	elif _frame == EASE_FRAMES * 3:
		_save_image(SABIL_PATH)
		Screens.pop()
	elif _frame == EASE_FRAMES * 4:
		_start_bench()
	elif _frame == EASE_FRAMES * 5:
		_save_image(BENCH_PATH)
		Screens.pop()
	elif _frame >= EASE_FRAMES * 5 + 5:
		get_tree().quit()


func _save_image(path: String) -> void:
	var vp: Viewport = get_viewport()
	var img: Image = vp.get_texture().get_image()
	if img.get_width() != 960 or img.get_height() != 540:
		img.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute("C:/dev/game/inbox")
	var err: Error = img.save_png(path)
	print("Saved render: ", path, " (960x540) err=", err)
