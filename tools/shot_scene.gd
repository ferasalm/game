extends SceneTree
## Plays a scene (or a Node script) for the movie writer (frames to a folder): the battle demo with its heroes on
## auto_play, or any scene. Run (not headless): "$(tools/godot.sh)" --path . --resolution 960x540 --write-movie DIR/f.png --fixed-fps 30
## --quit-after N -s res://tools/shot_scene.gd -- <scene path>


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path: String = args[0] if args.size() > 0 else "res://features/combat/view/battle_demo.tscn"
	var inst: Node
	if scene_path.ends_with(".gd"):
		inst = (load(scene_path) as GDScript).new() as Node
	else:
		inst = (load(scene_path) as PackedScene).instantiate()
	if &"auto_play" in inst:
		inst.set(&"auto_play", true)
	root.add_child(inst)
