class_name StormBuilder
extends RefCounted
## Builds the storm weather layer (rain, splashes, puddles, drips, steam, lightning) from an AreaDef and StormDef.

const RAIN_SHADER: Shader = preload("res://features/world/weather/view/shaders/rain.gdshader")
const SPLASH_SHADER: Shader = preload("res://features/world/weather/view/shaders/splash.gdshader")


static func build(area: AreaDef, storm_id: StringName = &"night_storm") -> Node3D:
	if area == null or area.weather != "storm":
		return null
	var def := ContentDB.get_def("storm", storm_id) as StormDef
	if def == null:
		return null
	var host := StormHost.new()
	host.name = "Storm"
	host.def = def
	host.floor_y = AreaWalk.floor_height(area)
	host.rain_particles = _build_rain(def, host.floor_y)
	host.add_child(host.rain_particles)
	host.splash_particles = _build_splashes(def)
	host.add_child(host.splash_particles)
	host.puddles_root = PuddleBuilder.build(area, def, host.floor_y)
	host.add_child(host.puddles_root)
	return host


static func add_drips(host: Node3D, points: Array[Vector3], storm_id: StringName = &"night_storm") -> void:
	if points.is_empty():
		return
	var def := ContentDB.get_def("storm", storm_id) as StormDef
	for pt: Vector3 in points:
		var emitter := GPUParticles3D.new()
		emitter.amount = 2
		emitter.lifetime = 0.8
		emitter.position = pt
		var mat := ParticleProcessMaterial.new()
		mat.direction = Vector3.DOWN
		mat.spread = 0.0
		mat.initial_velocity_min = def.drip_speed if def != null else 9.8
		mat.initial_velocity_max = def.drip_speed if def != null else 9.8
		mat.gravity = Vector3(0.0, -9.8, 0.0)
		emitter.process_material = mat
		var quad := QuadMesh.new()
		var dsize: float = def.drip_size if def != null else 0.025
		quad.size = Vector2(dsize, dsize * 2.0)
		emitter.draw_pass_1 = quad
		host.add_child(emitter)


static func add_steam(host: Node3D, points: Array[Vector3], storm_id: StringName = &"night_storm") -> void:
	if points.is_empty():
		return
	var def := ContentDB.get_def("storm", storm_id) as StormDef
	var cap: int = def.steam_count_max if def != null else 40
	var lifetime: float = def.steam_lifetime if def != null else 2.5
	for pt: Vector3 in points:
		var emitter := GPUParticles3D.new()
		emitter.amount = cap
		emitter.lifetime = lifetime
		emitter.position = pt
		var mat := ParticleProcessMaterial.new()
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		mat.emission_sphere_radius = 0.2
		mat.direction = Vector3.UP
		mat.spread = 20.0
		mat.initial_velocity_min = def.steam_speed * 0.5 if def != null else 0.6
		mat.initial_velocity_max = def.steam_speed if def != null else 1.2
		mat.gravity = Vector3(0.0, 0.2, 0.0)
		emitter.process_material = mat
		var quad := QuadMesh.new()
		var ssize: float = def.steam_size if def != null else 0.75
		quad.size = Vector2(ssize, ssize)
		var smat := StandardMaterial3D.new()
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		smat.albedo_color = Color(def.steam_color.r, def.steam_color.g, def.steam_color.b, def.steam_alpha) if def != null else Color(0.9, 0.9, 0.9, 0.1)
		quad.material = smat
		emitter.draw_pass_1 = quad
		host.add_child(emitter)


static func _build_rain(def: StormDef, floor_y: float) -> GPUParticles3D:
	var emitter := GPUParticles3D.new()
	emitter.name = "RainStreaks"
	emitter.amount = def.rain_count
	emitter.lifetime = def.rain_box.y / def.rain_speed
	emitter.preprocess = emitter.lifetime
	emitter.local_coords = false
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = def.rain_box * 0.5
	mat.direction = Vector3(def.rain_wind.x, -def.rain_speed, def.rain_wind.z).normalized()
	mat.spread = 0.0
	mat.initial_velocity_min = def.rain_speed
	mat.initial_velocity_max = def.rain_speed
	mat.gravity = Vector3.ZERO
	mat.particle_flag_align_y = true
	emitter.process_material = mat
	var quad := QuadMesh.new()
	quad.size = Vector2(def.rain_streak_width, def.rain_streak_length)
	var smat := ShaderMaterial.new()
	smat.shader = RAIN_SHADER
	smat.set_shader_parameter(&"rain_color", Color(def.rain_color.r, def.rain_color.g, def.rain_color.b, def.rain_alpha))
	smat.set_shader_parameter(&"floor_death_y", floor_y - def.rain_floor_margin)
	quad.material = smat
	emitter.draw_pass_1 = quad
	return emitter


static func _build_splashes(def: StormDef) -> GPUParticles3D:
	var emitter := GPUParticles3D.new()
	emitter.name = "Splashes"
	emitter.amount = def.splash_count
	emitter.lifetime = def.splash_lifetime
	emitter.local_coords = false
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(def.splash_box.x * 0.5, 0.05, def.splash_box.y * 0.5)
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.3
	mat.scale_max = 1.0
	emitter.process_material = mat
	var plane := PlaneMesh.new()
	plane.size = Vector2(def.splash_size, def.splash_size)
	var smat := ShaderMaterial.new()
	smat.shader = SPLASH_SHADER
	smat.set_shader_parameter(&"splash_color", Color(def.splash_color.r, def.splash_color.g, def.splash_color.b, def.splash_alpha))
	plane.material = smat
	emitter.draw_pass_1 = plane
	return emitter
