class_name Diorama
extends RefCounted
## Static helpers that build the HD-2D look from a LookDef: WorldEnvironment, low sun, tilt-shift camera, and
## the nearest-filtered block material. Used by the look test and the rooftop scene.


static func make_environment(look: LookDef) -> WorldEnvironment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = look.background_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = look.ambient_color
	env.ambient_light_energy = look.ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_bloom = look.glow_bloom
	var world := WorldEnvironment.new()
	world.environment = env
	return world


static func make_sun(look: LookDef) -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = look.sun_rotation
	sun.light_color = look.sun_color
	sun.shadow_enabled = true
	return sun


static func make_attributes(look: LookDef) -> CameraAttributesPractical:
	var attributes := CameraAttributesPractical.new()
	attributes.dof_blur_near_enabled = true
	attributes.dof_blur_near_distance = look.dof_near
	attributes.dof_blur_far_enabled = true
	attributes.dof_blur_far_distance = look.dof_far
	attributes.dof_blur_amount = look.dof_amount
	return attributes


static func make_camera(look: LookDef) -> Camera3D:
	var camera := Camera3D.new()
	camera.fov = look.fov
	camera.attributes = make_attributes(look)
	return camera


## Puts the camera at its look offset from the focus point and aims it at the focus (the camera must be in the tree).
static func aim(camera: Camera3D, focus: Vector3, look: LookDef) -> void:
	camera.position = focus + look.camera_offset
	camera.look_at(focus + Vector3(0.0, look.look_height, 0.0))


static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	return mat
