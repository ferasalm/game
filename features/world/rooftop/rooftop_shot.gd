extends Node3D
## Frame tool: the rooftop with Zayd put at chosen floor coordinates (and an optional free camera), for rendering
## pictures. Run with args after "--": <x> <z> [cam_x cam_y cam_z tgt_x tgt_y tgt_z fov] [route=a] [noactors].
## route=a lays the painterly screen filter over the picture; noactors hides every character (for route c mockups).

const FILTER: Shader = preload("res://features/world/view/shaders/painterly_filter.gdshader")


func _ready() -> void:
	_build()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("route=a"):
		var layer := CanvasLayer.new()
		layer.layer = 50
		var rect := ColorRect.new()
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		var material := ShaderMaterial.new()
		material.shader = FILTER
		rect.material = material
		layer.add_child(rect)
		add_child(layer)
	if args.has("noactors"):
		_hide_actors.call_deferred()


## Moves every character mesh to render layer 20 and takes that layer off the camera: the actors stay in the scene,
## so their shadows and the camera cut-away remain, only their bodies are left out of the picture.
func _hide_actors() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	camera.cull_mask &= ~(1 << 19)
	_hide_under(self, false)


func _hide_under(node: Node, inside_actor: bool) -> void:
	var actor: bool = inside_actor or node is Player or node is Follower or node is Bystander or node is Patrol
	if actor and node is VisualInstance3D:
		(node as VisualInstance3D).layers = 1 << 19
	for child: Node in node.get_children():
		_hide_under(child, actor)


func _build() -> void:
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
