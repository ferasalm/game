extends Node
## Renders one dialogue line over the rooftop to an inbox PNG, to judge the portrait and box layout by eye.
## Run: "$(tools/godot.sh)" --path . --resolution 1920x1080 res://tools/shot_dialogue.tscn -- <dialogue_id> [line]

const OUT_DIR: String = "C:/dev/game/inbox"
const SETTLE_FRAMES: int = 40

var _dialogue_id: StringName = &"abu_nabil_first"
var _frame: int = 0
var _rooftop: Rooftop = null
var _box: DialogueBox = null


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_dialogue_id = StringName(args[0])
	var skip: int = int(args[1]) if args.size() > 1 else 0
	var rooftop_scene: PackedScene = load("res://features/world/rooftop/rooftop.tscn") as PackedScene
	_rooftop = rooftop_scene.instantiate() as Rooftop
	add_child(_rooftop)
	_rooftop.camera_rig.hold_intro(false)
	_rooftop.camera_rig.intro_finished.emit()
	_box = DialogueBox.new()
	add_child(_box)
	_box.play(_dialogue_id)
	for i: int in skip:
		_box.advance()
		_box.advance()


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == SETTLE_FRAMES / 2 and _box.is_typing():
		_box.advance()
	if _frame >= SETTLE_FRAMES:
		var img: Image = get_viewport().get_texture().get_image()
		var out_path: String = OUT_DIR.path_join("dialogue_%s.png" % _dialogue_id)
		img.save_png(out_path)
		print("Saved render to %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
		get_tree().quit()
