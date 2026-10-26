extends Node
## purpose: renders hero walking with a guard visible on the prison roof to inbox PNG for proof.

const OUT_DIR: String = "C:/dev/game/inbox"
const SETTLE_FRAMES: int = 30

var _frame: int = 0
var _roof: RoofScene


func _ready() -> void:
	var roof_scene: PackedScene = load("res://features/neon/roof/roof_scene.tscn") as PackedScene
	_roof = roof_scene.instantiate() as RoofScene
	add_child(_roof)
	# Position hero walking across the roof deck near where guard patrols
	_roof.hero().position = Vector2(1180.0, 1040.0)
	_roof.hero().face(Vector2.RIGHT)
	_roof.hero().play(&"run")


func _process(_delta: float) -> void:
	_frame += 1
	if _frame >= SETTLE_FRAMES:
		DirAccess.make_dir_recursive_absolute(OUT_DIR)
		var img: Image = get_viewport().get_texture().get_image()
		var out_path: String = OUT_DIR.path_join("neon_roof.png")
		img.save_png(out_path)
		print("Saved render to %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
		get_tree().quit()
