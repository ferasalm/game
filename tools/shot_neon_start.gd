extends Node
## Renders one Neon Glitch start flow state (TITLE, PICK, PANEL) to an inbox PNG.
## Run: "$(tools/godot.sh)" --path . --resolution 1920x1080 res://tools/shot_neon_start.tscn -- <STATE>

const OUT_DIR: String = "C:/dev/game/inbox"
const SETTLE_FRAMES: int = 30

var _state_arg: String = "TITLE"
var _frame: int = 0
var _start_flow: StartFlow = null


func _ready() -> void:
	get_viewport().size = Vector2i(1920, 1080)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_state_arg = args[0].to_upper()
	var flow_scene: PackedScene = load("res://features/neon/start/start_flow.tscn") as PackedScene
	_start_flow = flow_scene.instantiate() as StartFlow
	add_child(_start_flow)
	_start_flow.set_state_for_shot(_state_arg)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame >= SETTLE_FRAMES:
		var tex: ViewportTexture = get_viewport().get_texture()
		if tex != null:
			var img: Image = tex.get_image()
			if img != null:
				var out_path: String = OUT_DIR.path_join("neon_start_%s.png" % _state_arg)
				img.save_png(out_path)
				print("Saved render to %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
				get_tree().quit()
				return
		if _frame >= SETTLE_FRAMES + 20:
			get_tree().quit()
