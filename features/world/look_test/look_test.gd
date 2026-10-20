extends Node3D
## HD-2D look test (the M1 rendering spike): a block diorama, a pixel-art billboard hero (CharacterVisual), tilt-shift
## depth of field, bloom and a low sun with shadows, all built in code. Open the project and press F5.
## Tune the constants below on your own laptop; the chosen values move to content data in M1.

const GROUND: int = 12
const PIXELS_PER_UNIT: float = 16.0
const CAMERA_POS: Vector3 = Vector3(0.0, 6.0, 8.5)
const CAMERA_FOV: float = 30.0
const DOF_NEAR: float = 5.0
const DOF_FAR: float = 12.0
const DOF_AMOUNT: float = 0.1

var _fps_label: Label


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_add_environment()
	_add_sun()
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


func _add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.66, 0.78)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.78, 0.7)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_bloom = 0.15
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)


func _add_sun() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.light_color = Color(1.0, 0.9, 0.75)
	sun.shadow_enabled = true
	add_child(sun)


func _add_ground() -> void:
	var stone := _material(Color(0.78, 0.7, 0.55))
	var grass := _material(Color(0.45, 0.55, 0.3))
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
	var camera := Camera3D.new()
	camera.fov = CAMERA_FOV
	camera.position = CAMERA_POS
	var attributes := CameraAttributesPractical.new()
	attributes.dof_blur_near_enabled = true
	attributes.dof_blur_near_distance = DOF_NEAR
	attributes.dof_blur_far_enabled = true
	attributes.dof_blur_far_distance = DOF_FAR
	attributes.dof_blur_amount = DOF_AMOUNT
	camera.attributes = attributes
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.8, 0.0))
	camera.current = true


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material
