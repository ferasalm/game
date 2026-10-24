extends Node3D
## purpose: Measures floor flicker across 60 frames of party walk in default look (painted_b).
## Run with: "$(tools/godot.sh)" --path . tools/flicker_probe.tscn

const WALK_FRAMES: int = 60
const WARMUP_FRAMES: int = 30
const WALK_DISTANCE: float = 3.0
const START_POS := Vector3(24.0, -0.8, 29.5)
const FRAMES_DIR: String = ".check/frames"

var _rooftop: Rooftop = null
var _storm: StormHost = null
var _frame: int = 0
var _pass: int = 0
var _frames_on: Array[PackedByteArray] = []
var _motion_crops: Array[Image] = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(FRAMES_DIR)
	_rooftop = (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	_rooftop.area_id = &"souq_rooftops_v4"
	_rooftop.look_id = &"painted_b"
	add_child(_rooftop)
	_find_storm()
	_reset_party()
	if _rooftop.camera_rig != null:
		_rooftop.camera_rig.set_actors(null, null)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame <= WARMUP_FRAMES:
		_reset_party()
		return

	var walk_idx: int = _frame - WARMUP_FRAMES - 1
	if walk_idx < WALK_FRAMES:
		_step_walk(walk_idx)
		_capture_frame(walk_idx)
	elif walk_idx == WALK_FRAMES:
		_finish()


func _find_storm() -> void:
	for child: Node in _rooftop.get_children():
		if child is StormHost:
			_storm = child as StormHost
			break


func _reset_party() -> void:
	_rooftop.teleport_party(START_POS, false)
	_rooftop.follower.position = START_POS + Vector3(-1.0, 0.0, 0.5)


func _step_walk(walk_idx: int) -> void:
	var progress: float = float(walk_idx) / float(WALK_FRAMES)
	var pos: Vector3 = START_POS + Vector3(progress * WALK_DISTANCE, 0.0, 0.0)
	_rooftop.player.position = pos
	_rooftop.follower.position = pos + Vector3(-1.0, 0.0, 0.5)


func _capture_frame(walk_idx: int) -> void:
	var vp: Viewport = get_viewport()
	var img: Image = vp.get_texture().get_image()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var path: String = FRAMES_DIR.path_join("frame_%03d.png" % walk_idx)
	img.save_png(path)
	if walk_idx == 0 or walk_idx == 20 or walk_idx == 40 or walk_idx == 59:
		_save_motion_crop(img)


func _save_motion_crop(img: Image) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var start_y: int = int(float(h) * 0.6)
	var crop_h: int = h - start_y
	var crop: Image = Image.create_empty(w, crop_h, false, Image.FORMAT_RGBA8)
	crop.blit_rect(img, Rect2i(0, start_y, w, crop_h), Vector2i.ZERO)
	if crop.get_width() != 960 or crop.get_height() != 216:
		crop.resize(960, 216, Image.INTERPOLATE_BILINEAR)
	_motion_crops.append(crop)


func _build_motion_grid() -> void:
	if _motion_crops.size() < 4:
		return
	var cw: int = _motion_crops[0].get_width()
	var ch: int = _motion_crops[0].get_height()
	var grid: Image = Image.create_empty(cw * 2, ch * 2, false, Image.FORMAT_RGBA8)
	grid.blit_rect(_motion_crops[0], Rect2i(0, 0, cw, ch), Vector2i(0, 0))
	grid.blit_rect(_motion_crops[1], Rect2i(0, 0, cw, ch), Vector2i(cw, 0))
	grid.blit_rect(_motion_crops[2], Rect2i(0, 0, cw, ch), Vector2i(0, ch))
	grid.blit_rect(_motion_crops[3], Rect2i(0, 0, cw, ch), Vector2i(cw, ch))
	grid.save_png("C:/dev/game/inbox/render_clean_motion.png")
	if DirAccess.dir_exists_absolute("inbox"):
		grid.save_png("inbox/render_clean_motion.png")


func _finish() -> void:
	_build_motion_grid()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var is_before: bool = false
	for a: String in args:
		if a == "--before":
			is_before = true
	var py_args := PackedStringArray(["tools/flicker_helper.py", FRAMES_DIR])
	if is_before:
		py_args.append("--before")
	var output: Array = []
	OS.execute("python", py_args, output, true)
	if not output.is_empty():
		print(output[0])
	get_tree().quit()
