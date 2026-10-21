extends SceneTree
## FPS probe: plays a scene with vsync off and prints the average and worst frames per second after a warm-up.
## Run on the target laptop (not headless): "$(tools/godot.sh)" --path . -s res://tools/fps_probe.gd -- <scene or Node script> [seconds]

const WARMUP_FRAMES: int = 60
var _times: PackedFloat64Array = []
var _seconds: float = 6.0
var _last_usec: int = 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path: String = args[0] if args.size() > 0 else "res://features/prototype/prototype_main.tscn"
	if args.size() > 1:
		_seconds = float(args[1])
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var inst: Node
	if scene_path.ends_with(".gd"):
		inst = (load(scene_path) as GDScript).new() as Node
	else:
		inst = (load(scene_path) as PackedScene).instantiate()
	if &"auto_play" in inst:
		inst.set(&"auto_play", true)  # a battle demo plays itself so the probe sees the effects
	root.add_child(inst)


func _process(_delta: float) -> bool:
	var now := Time.get_ticks_usec()
	if _last_usec > 0:
		_times.append(float(now - _last_usec) / 1000000.0)
	_last_usec = now
	var counted := _times.size() - WARMUP_FRAMES
	var total := 0.0
	var worst := 0.0
	for i: int in range(WARMUP_FRAMES, _times.size()):
		total += _times[i]
		worst = maxf(worst, _times[i])
	if counted > 0 and total >= _seconds:
		print("FPS avg %.1f, worst frame %.1f ms, %d frames" % [counted / total, worst * 1000.0, counted])
		return true
	return false
