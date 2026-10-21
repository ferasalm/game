class_name PropFx
extends RefCounted
## Live effects a prop carries on top of its mesh: the splash of a stream (PropSplash) as a CPUParticles3D of
## additive billboard quads, placed with the prop's transform.


static func splash(spec: PropSplash, at: Transform3D) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "Splash"
	particles.transform = at * Transform3D(Basis.IDENTITY, spec.at)
	particles.amount = spec.count
	particles.lifetime = spec.lifetime
	particles.local_coords = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = spec.radius
	particles.direction = Vector3.UP
	particles.spread = 55.0
	particles.initial_velocity_min = spec.speed * 0.5
	particles.initial_velocity_max = spec.speed
	particles.gravity = Vector3(0.0, -spec.gravity, 0.0)
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * spec.size
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(spec.color.r * spec.energy, spec.color.g * spec.energy, spec.color.b * spec.energy)
	mat.disable_receive_shadows = true
	quad.material = mat
	particles.mesh = quad
	return particles
