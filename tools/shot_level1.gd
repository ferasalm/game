extends Node3D
## Renders level 1 blockout roofs R1-R5 and crossing X3 from play camera to C:/dev/game/inbox/level1_*.png.

var _frame: int = 0
var _rooftop: Rooftop = null


func _ready() -> void:
	_rooftop = (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	_rooftop.area_id = &"souq_rooftops_v4"
	_rooftop.look_id = &"painted_b"
	add_child(_rooftop)
	_set_party(Vector3(25.5, -0.8, 30.5))


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 40:
		_save_image("C:/dev/game/inbox/render_clean_r1.png")
		_save_image("C:/dev/game/inbox/level1_r1.png")
		_rooftop.teleport_party(Vector3(25.8, -0.8, 30.7), false)
	elif _frame == 55:
		_save_image("C:/dev/game/inbox/render_clean_r1_b.png")
		_set_party(Vector3(30.0, 0.0, 18.0))
	elif _frame == 95:
		_save_image("C:/dev/game/inbox/level1_r2.png")
		_set_party(Vector3(30.5, 1.6, 6.0))
	elif _frame == 135:
		_save_image("C:/dev/game/inbox/render_clean_r3.png")
		_save_image("C:/dev/game/inbox/level1_r3.png")
		_set_party(Vector3(28.5, 1.6, 5.5))
	elif _frame == 175:
		_save_image("C:/dev/game/inbox/level1_x3.png")
		_set_party(Vector3(7.0, -3.2, 17.5))
	elif _frame == 215:
		_save_image("C:/dev/game/inbox/level1_r4.png")
		_set_party(Vector3(7.0, -3.2, 7.5))
	elif _frame == 255:
		_save_image("C:/dev/game/inbox/level1_r5.png")
		get_tree().quit()


func _set_party(pos: Vector3) -> void:
	_rooftop.teleport_party(pos, false)
	_rooftop.follower.position = pos + Vector3(-1.0, 0.0, 0.5)


func _save_image(path: String) -> void:
	var vp: Viewport = get_viewport()
	var img: Image = vp.get_texture().get_image()
	if img.get_width() != 960 or img.get_height() != 540:
		img.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	var err: Error = img.save_png(path)
	print("Saved render: ", path, " err=", err)
	var local_path := path.replace("C:/dev/game/inbox/", "inbox/")
	if DirAccess.dir_exists_absolute("inbox") and local_path != path:
		img.save_png(local_path)
