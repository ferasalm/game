class_name Diorama
extends RefCounted
## Static helpers that build the HD-2D look from a LookDef: WorldEnvironment, low sun, tilt-shift camera, and
## the nearest-filtered block material. Used by the look test and the rooftop scene.


const TONEMAPS: Dictionary = {
	&"linear": Environment.TONE_MAPPER_LINEAR, &"reinhard": Environment.TONE_MAPPER_REINHARDT,
	&"filmic": Environment.TONE_MAPPER_FILMIC, &"aces": Environment.TONE_MAPPER_ACES,
	&"agx": Environment.TONE_MAPPER_AGX,
}


static func make_environment(look: LookDef) -> WorldEnvironment:
	var env := Environment.new()
	_apply_background(env, look)
	env.tonemap_mode = TONEMAPS.get(look.tonemap, Environment.TONE_MAPPER_FILMIC) as Environment.ToneMapper
	env.tonemap_exposure = look.exposure
	env.tonemap_white = look.white_point
	env.glow_enabled = true
	env.glow_bloom = look.glow_bloom
	env.glow_hdr_threshold = look.glow_threshold
	env.glow_intensity = look.glow_intensity
	env.glow_strength = look.glow_strength
	_apply_fog(env, look)
	var world := WorldEnvironment.new()
	world.environment = env
	return world


## The key light (the sun by day, the moon at night). A look with a fill light gets it as a child of this node.
static func make_sun(look: LookDef) -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = look.sun_rotation
	sun.light_color = look.sun_color
	sun.light_energy = look.sun_energy
	sun.shadow_enabled = true
	sun.shadow_blur = look.sun_shadow_blur
	if look.fill_energy > 0.0:
		var fill := DirectionalLight3D.new()
		fill.top_level = true
		fill.rotation_degrees = look.fill_rotation
		fill.light_color = look.fill_color
		fill.light_energy = look.fill_energy
		sun.add_child(fill)
	return sun


static func _apply_background(env: Environment, look: LookDef) -> void:
	var sky_def := ContentDB.get_def("sky", look.sky_id) as SkyDef if look.sky_id != &"" else null
	if sky_def == null:
		env.background_mode = Environment.BG_COLOR
		env.background_color = look.background_color
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	else:
		env.background_mode = Environment.BG_SKY
		env.sky = SkyBuilder.make_sky(sky_def)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_sky_contribution = look.ambient_sky_mix
	env.ambient_light_color = look.ambient_color
	env.ambient_light_energy = look.ambient_energy


static func _apply_fog(env: Environment, look: LookDef) -> void:
	if look.fog_density > 0.0 or look.fog_height_density > 0.0:
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		env.fog_light_color = look.fog_color
		env.fog_density = look.fog_density
		env.fog_sky_affect = look.fog_sky_affect
		env.fog_aerial_perspective = look.fog_aerial
		env.fog_height = look.fog_height
		env.fog_height_density = look.fog_height_density
	if look.volumetric_fog:
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = look.volumetric_density
		env.volumetric_fog_albedo = look.volumetric_albedo
		env.volumetric_fog_length = look.volumetric_length


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
