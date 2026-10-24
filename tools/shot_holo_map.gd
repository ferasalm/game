extends Node
## purpose: Renders holographic map (area and city views) over the starting rooftop to inbox PNGs.

const OUT_DIR: String = "C:/dev/game/inbox"
const ROOFTOP_SCENE: PackedScene = preload("res://features/world/rooftop/rooftop.tscn")

var _frame: int = 0
var _rooftop: Rooftop
var _port: RooftopPort
var _map: HoloMap


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if GameState.party.is_empty():
		GameState.start_new()
	_rooftop = ROOFTOP_SCENE.instantiate() as Rooftop
	add_child(_rooftop)
	GameState.area_id = _rooftop.area_id
	_port = RooftopPort.new(_rooftop, self)
	Router.register_area(_port)
	_rooftop.camera_rig.hold_intro(false)
	_rooftop.camera_rig.intro_finished.emit()


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 15:
		_open_map()
	elif _frame == 35:
		_capture_and_save("map_area.png")
		if _map != null:
			_map.toggle_mode()
	elif _frame == 55:
		_capture_and_save("map_city.png")
		get_tree().quit()


func _open_map() -> void:
	Screens.open(&"map")
	_map = Screens.top() as HoloMap


func _capture_and_save(file_name: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	if img.get_size() != Vector2i(1920, 1080):
		img.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var out_path: String = OUT_DIR.path_join(file_name)
	img.save_png(out_path)
	print("Saved render to %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
