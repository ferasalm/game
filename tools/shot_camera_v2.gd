extends Node3D
## Renders rooftop and camera_room scenes in follow and framed camera modes to C:/dev/game/inbox/camera_v2_*.png.

var _frame: int = 0
var _rooftop: Rooftop = null
var _room: CameraRoom = null


func _ready() -> void:
	_rooftop = (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	add_child(_rooftop)
	_rooftop.player.position = Vector3(8.0, 0.5, 18.0)
	_rooftop.follower.position = _rooftop.player.position + Vector3(-1.0, 0.0, 0.5)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 20:
		_save_image("C:/dev/game/inbox/camera_v2_rooftop_1.png")
		_rooftop.player.position = Vector3(10.0, 0.5, 2.5)
		_rooftop.follower.position = _rooftop.player.position + Vector3(-1.0, 0.0, 0.5)
	elif _frame == 40:
		_save_image("C:/dev/game/inbox/camera_v2_rooftop_2.png")
		_rooftop.queue_free()
		_room = (load("res://features/world/interior/camera_room.tscn") as PackedScene).instantiate() as CameraRoom
		add_child(_room)
		_room.set_player_pos(Vector3(2.0, 0.0, 3.5))
	elif _frame == 60:
		_save_image("C:/dev/game/inbox/camera_v2_room_door.png")
		_room.set_player_pos(Vector3(6.0, 0.0, 2.5))
	elif _frame == 80:
		_save_image("C:/dev/game/inbox/camera_v2_room_window.png")
		get_tree().quit()


func _save_image(path: String) -> void:
	var vp: Viewport = get_viewport()
	var img: Image = vp.get_texture().get_image()
	if img.get_width() != 960 or img.get_height() != 540:
		img.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	var err: Error = img.save_png(path)
	print("Saved render: ", path, " (960x540) err=", err)
