extends Node3D
## Frame tool: the rooftop with Zayd put at chosen floor coordinates (and an optional free camera), for rendering
## pictures. Run with args after "--": <x> <z> [cam_x cam_y cam_z tgt_x tgt_y tgt_z fov].


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	add_child(rooftop)
	if args.size() >= 2:
		rooftop.player.position = Vector3(float(args[0]), 0.5, float(args[1]))
		rooftop.follower.position = rooftop.player.position + Vector3(-1.0, 0.0, 0.5)
	if args.size() >= 9:
		rooftop.set_process(false)
		rooftop.camera.attributes = null
		rooftop.camera.fov = float(args[8])
		rooftop.camera.position = Vector3(float(args[2]), float(args[3]), float(args[4]))
		rooftop.camera.look_at(Vector3(float(args[5]), float(args[6]), float(args[7])))
