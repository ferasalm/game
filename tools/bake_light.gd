extends RefCounted
## purpose: The sprite baker's own world environment and key light, copied from the painted_b look so a bake needs
## no 3D world, LookDef or ContentDB look.

const TONEMAP: Environment.ToneMapper = Environment.TONE_MAPPER_AGX
const EXPOSURE: float = 1.05
const WHITE_POINT: float = 1.0
const AMBIENT_COLOR: Color = Color("#2b3380")
const AMBIENT_ENERGY: float = 0.5
const SUN_ROTATION: Vector3 = Vector3(-42.0, 125.0, 0.0)
const SUN_COLOR: Color = Color("#7f9bff")
const SUN_ENERGY: float = 0.7
const SUN_SHADOW_BLUR: float = 1.5
const FILL_ROTATION: Vector3 = Vector3(-25.0, -24.0, 0.0)
const FILL_COLOR: Color = Color("#5b78c8")
const FILL_ENERGY: float = 0.3
const FOG_COLOR: Color = Color("#2c3470")
const FOG_DENSITY: float = 0.01
const FOG_SKY_AFFECT: float = 0.0
const FOG_AERIAL: float = 0.0
const FOG_HEIGHT: float = 0.45
const FOG_HEIGHT_DENSITY: float = 1.0


static func make_environment() -> WorldEnvironment:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT_COLOR
	env.ambient_light_energy = AMBIENT_ENERGY
	env.tonemap_mode = TONEMAP
	env.tonemap_exposure = EXPOSURE
	env.tonemap_white = WHITE_POINT
	env.glow_enabled = false
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = FOG_COLOR
	env.fog_density = FOG_DENSITY
	env.fog_sky_affect = FOG_SKY_AFFECT
	env.fog_aerial_perspective = FOG_AERIAL
	env.fog_height = FOG_HEIGHT
	env.fog_height_density = FOG_HEIGHT_DENSITY
	var world := WorldEnvironment.new()
	world.environment = env
	return world


static func make_sun() -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = SUN_ROTATION
	sun.light_color = SUN_COLOR
	sun.light_energy = SUN_ENERGY
	sun.shadow_enabled = true
	sun.shadow_blur = SUN_SHADOW_BLUR
	var fill := DirectionalLight3D.new()
	fill.top_level = true
	fill.rotation_degrees = FILL_ROTATION
	fill.light_color = FILL_COLOR
	fill.light_energy = FILL_ENERGY
	sun.add_child(fill)
	return sun
