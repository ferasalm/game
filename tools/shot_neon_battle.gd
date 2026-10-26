extends Node
## purpose: Renders the on-map Neon battle mid-fight (auto-play) to C:/dev/game/inbox/neon_battle.png with the HUD.
## Run: "$(tools/godot.sh)" --path . --resolution 1920x1080 res://tools/shot_neon_battle.tscn

const OUT_PATH: String = "C:/dev/game/inbox/neon_battle.png"
const SETTLE_FRAMES: int = 420

var _demo: BattleDemo
var _frame: int = 0


func _ready() -> void:
	var scene: PackedScene = load("res://features/neon/battle/battle_demo.tscn") as PackedScene
	_demo = scene.instantiate() as BattleDemo
	add_child(_demo)
	if _demo.battle != null:
		_demo.battle.auto_play = true


func _process(_delta: float) -> void:
	_frame += 1
	if _frame < SETTLE_FRAMES:
		return
	var image: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(OUT_PATH.get_base_dir())
	image.save_png(OUT_PATH)
	print("Saved render to %s (%dx%d)" % [OUT_PATH, image.get_width(), image.get_height()])
	get_tree().quit()
