class_name StormPreview
extends Node3D
## Preview scene for the storm layer on the rooftop: used for fps_probe profiling and inbox renders.

const ROOFTOP_SCENE: PackedScene = preload("res://features/world/rooftop/rooftop.tscn")
const INBOX_DIR: String = "C:/dev/game/inbox"

var rooftop: Rooftop
var storm_host: StormHost
var _frame: int = 0
var _shot_mode: bool = false


func _ready() -> void:
	rooftop = ROOFTOP_SCENE.instantiate() as Rooftop
	add_child(rooftop)
	storm_host = _find_storm_host(rooftop)
	var args := OS.get_cmdline_user_args()
	_shot_mode = args.has("--shot") or args.has("shot")
	if _shot_mode:
		rooftop.camera_rig.hold_intro(false)
		rooftop.camera_rig.intro_finished.emit()


func _process(_delta: float) -> void:
	if not _shot_mode:
		return
	_frame += 1
	if _frame == 14:
		_save_image("storm_rain.png")
		if storm_host != null:
			storm_host.trigger_lightning()
	elif _frame == 16:
		_save_image("storm_lightning.png")
		get_tree().quit()


func _save_image(filename: String) -> void:
	DirAccess.make_dir_recursive_absolute(INBOX_DIR)
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = INBOX_DIR + "/" + filename
	img.save_png(path)
	print("Saved storm preview render to %s (%dx%d)" % [path, img.get_width(), img.get_height()])


func _find_storm_host(node: Node) -> StormHost:
	if node is StormHost:
		return node as StormHost
	for child: Node in node.get_children():
		var found: StormHost = _find_storm_host(child)
		if found != null:
			return found
	return null
