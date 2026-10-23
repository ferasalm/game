extends Node3D
## Renders souq R2 sabil and herb stall from the play camera to C:/dev/game/inbox/souq_r2_*.png.

var _frame: int = 0
var _rooftop: Rooftop = null


func _ready() -> void:
	_rooftop = (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	_rooftop.area_id = &"souq_rooftops_v4"
	_rooftop.look_id = &"night"
	add_child(_rooftop)
	_set_party(Vector3(33.7, 0.0, 18.0))


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 45:
		_save_image("C:/dev/game/inbox/souq_r2_sabil.png")
		_set_party(Vector3(29.0, 0.0, 18.0))
	elif _frame == 90:
		_save_image("C:/dev/game/inbox/souq_r2_stall.png")
		get_tree().quit()


func _set_party(pos: Vector3) -> void:
	_rooftop.teleport_party(pos, false)
	_rooftop.follower.position = pos + Vector3(-0.8, 0.0, 0.6)


func _save_image(path: String) -> void:
	var vp: Viewport = get_viewport()
	var img: Image = vp.get_texture().get_image()
	if img.get_width() != 960 or img.get_height() != 540:
		img.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	var err: Error = img.save_png(path)
	print("Saved render: ", path, " err=", err)
