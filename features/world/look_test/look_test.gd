extends Node3D
## HD-2D look test (the M1 rendering spike): a block diorama, a pixel-art billboard hero (CharacterVisual), tilt-shift
## depth of field, bloom and a low sun with shadows. The look numbers come from content/world/look.json (look v1).
## Open the project and press F5 on this scene.

const GROUND: int = 12
const LOOK_ID: StringName = &"v1"

var _look: LookDef
var _fps_label: Label


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_look = ContentDB.get_def("look", LOOK_ID) as LookDef
	if _look == null:
		_look = LookDef.new()
	add_child(Diorama.make_environment(_look))
	add_child(Diorama.make_sun(_look))
	_add_ground()
	_add_hero()
	_add_camera()
	_add_fps_label()


func _process(_delta: float) -> void:
	_fps_label.text = "%d FPS" % Engine.get_frames_per_second()


func _add_fps_label() -> void:
	var layer := CanvasLayer.new()
	_fps_label = Label.new()
	_fps_label.position = Vector2(16.0, 16.0)
	_fps_label.add_theme_font_size_override("font_size", 28)
	layer.add_child(_fps_label)
	add_child(layer)


func _add_ground() -> void:
	var stone := Diorama.material(Color(0.78, 0.7, 0.55))
	var grass := Diorama.material(Color(0.45, 0.55, 0.3))
	for x: int in GROUND:
		for z: int in GROUND:
			var height: float = 1.0 if x >= GROUND - 3 else 0.5
			var block := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(1.0, height, 1.0)
			block.mesh = mesh
			block.material_override = stone if (x + z) % 2 == 0 else grass
			block.position = Vector3(x - GROUND / 2.0, height / 2.0 - 0.5, z - GROUND / 2.0)
			add_child(block)


func _add_hero() -> void:
	var hero := CharacterVisual.new()
	hero.set_sprite(&"zayd")
	add_child(hero)


func _add_camera() -> void:
	var camera := Diorama.make_camera(_look)
	add_child(camera)
	Diorama.aim(camera, Vector3.ZERO, _look)
	camera.current = true
