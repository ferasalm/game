extends Node3D
## purpose: Measures floor flicker across 60 frames of party walk in default look (painted_b).
## Run with: "$(tools/godot.sh)" --path . tools/flicker_probe.tscn

const WALK_FRAMES: int = 60
const WARMUP_FRAMES: int = 30
const WALK_DISTANCE: float = 3.0
const START_POS := Vector3(24.0, -0.8, 29.5)

var _rooftop: Rooftop = null
var _storm: StormHost = null
var _frame: int = 0
var _pass: int = 0
var _frames_on: Array[PackedByteArray] = []
var _frames_off: Array[PackedByteArray] = []
var _diffs_on: PackedFloat64Array = []
var _diffs_off: PackedFloat64Array = []
var _motion_crops: Array[Image] = []


func _ready() -> void:
	_rooftop = (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	_rooftop.area_id = &"souq_rooftops_v4"
	_rooftop.look_id = &"painted_b"
	add_child(_rooftop)
	_find_storm()
	_reset_party()


func _process(_delta: float) -> void:
	_frame += 1
	if _frame <= WARMUP_FRAMES:
		_reset_party()
		return

	var walk_idx: int = _frame - WARMUP_FRAMES - 1
	if walk_idx <= WALK_FRAMES:
		_step_walk(walk_idx)
		_capture_frame(walk_idx)
	elif walk_idx == WALK_FRAMES + 1:
		if _pass == 0:
			_start_pass_off()
		else:
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
	if _pass == 0 and (walk_idx == 0 or walk_idx == 20 or walk_idx == 40 or walk_idx == 60):
		_save_motion_crop(img)
	var lums: PackedByteArray = _floor_luminance(img)
	if _pass == 0:
		_frames_on.append(lums)
		if _frames_on.size() > 1:
			_diffs_on.append(_frame_diff(_frames_on[_frames_on.size() - 2], lums))
	else:
		_frames_off.append(lums)
		if _frames_off.size() > 1:
			_diffs_off.append(_frame_diff(_frames_off[_frames_off.size() - 2], lums))


func _floor_luminance(img: Image) -> PackedByteArray:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var start_y: int = int(float(h) * 0.6)
	var crop_h: int = h - start_y
	var bytes: PackedByteArray = img.get_data()
	var lums := PackedByteArray()
	lums.resize(w * crop_h)
	var start_idx: int = start_y * w * 4
	var out_idx: int = 0
	for i: int in range(start_idx, bytes.size(), 4):
		var r: int = bytes[i]
		var g: int = bytes[i + 1]
		var b: int = bytes[i + 2]
		lums[out_idx] = (r * 54 + g * 183 + b * 19) >> 8
		out_idx += 1
	return lums


func _frame_diff(prev: PackedByteArray, curr: PackedByteArray) -> float:
	var total: int = 0
	for i: int in curr.size():
		total += absi(int(curr[i]) - int(prev[i]))
	return float(total) / (float(curr.size()) * 255.0)


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


func _start_pass_off() -> void:
	_pass = 1
	_frame = 0
	if _storm != null and _storm.puddles_root != null:
		_storm.puddles_root.visible = false
	_reset_party()


func _average(arr: PackedFloat64Array) -> float:
	if arr.is_empty():
		return 0.0
	var sum: float = 0.0
	for val: float in arr:
		sum += val
	return sum / float(arr.size())


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
	print("Saved motion grid to inbox/render_clean_motion.png (", grid.get_width(), "x", grid.get_height(), ")")


func _calc_flicker() -> float:
	var count_frames: int = mini(_frames_on.size(), _frames_off.size())
	var n_pixels: int = _frames_on[0].size() if not _frames_on.is_empty() else 0
	var n_diffs: float = float(count_frames - 1)
	var on_sum := PackedFloat64Array()
	var off_sum := PackedFloat64Array()
	on_sum.resize(n_pixels)
	off_sum.resize(n_pixels)
	for k: int in range(1, count_frames):
		var on_k: PackedByteArray = _frames_on[k]
		var on_prev: PackedByteArray = _frames_on[k - 1]
		var off_k: PackedByteArray = _frames_off[k]
		var off_prev: PackedByteArray = _frames_off[k - 1]
		for p: int in n_pixels:
			on_sum[p] += absf(float(int(on_k[p]) - int(on_prev[p]))) / (255.0 * n_diffs)
			off_sum[p] += absf(float(int(off_k[p]) - int(off_prev[p]))) / (255.0 * n_diffs)
	var total: float = 0.0
	for p: int in n_pixels:
		total += maxf(0.0, on_sum[p] - off_sum[p])
	return total / float(n_pixels) if n_pixels > 0 else 0.0


func _finish() -> void:
	var mean_on: float = _average(_diffs_on)
	var mean_off: float = _average(_diffs_off)
	var flicker: float = _calc_flicker()
	print("FLICKER %.6f" % flicker)
	print("FLICKER numbers: on=%.6f off=%.6f flicker=%.6f" % [mean_on, mean_off, flicker])
	_build_motion_grid()
	get_tree().quit()
