extends Node3D
## Renders the grey-box valve-puzzle scene at 1920x1080 to C:/dev/game/inbox/puzzle_<arg>.png.
## Run: "$(tools/godot.sh)" --path . res://tools/shot_puzzles.tscn -- <start|light_solved|water_half|water_solved>

const OUT_DIR: String = "C:/dev/game/inbox"
const SETTLE_FRAMES: int = 20

var _arg: String = "start"
var _frame: int = 0
var _sub_vp: SubViewport
var _board: PuzzleBoard


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_arg = args[0]
	_sub_vp = SubViewport.new()
	_sub_vp.size = Vector2i(1920, 1080)
	_sub_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub_vp.own_world_3d = true
	add_child(_sub_vp)
	GameState.flags.erase(&"puzzle_valve_lock")
	GameState.flags.erase(&"puzzle_valve_water")
	if _arg == "light_solved" or _arg == "water_half" or _arg == "water_solved":
		GameState.flags[&"puzzle_valve_lock"] = true
	if _arg == "water_solved":
		GameState.flags[&"puzzle_valve_water"] = true
	_board = PuzzleBoard.new()
	_sub_vp.add_child(_board)
	_board.camera.current = true
	if _arg == "water_half":
		_set_water_half()


func _set_water_half() -> void:
	_board.water_state.freed[&"g3"] = true
	_board.water_state.open[&"g1"] = false
	_board.water_state.open[&"g3"] = false
	_board.water_state.open[&"g4"] = true
	_board.water_state.spout[&"s1"] = 0
	_board.water_state.spout[&"s2"] = 0
	_board.redraw()


func _process(_delta: float) -> void:
	_frame += 1
	if _frame < SETTLE_FRAMES:
		return
	var img: Image = _sub_vp.get_texture().get_image()
	var out_path: String = OUT_DIR.path_join("puzzle_%s.png" % _arg)
	img.save_png(out_path)
	print("Saved render to %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
	get_tree().quit()
