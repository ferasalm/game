class_name SkyBuilder
extends RefCounted
## Builds the night Sky resource from a SkyDef: the sky shader with every uniform filled from the def, and the
## three direction vectors (moon, city glow, milky way normal) computed from its angles. Radiance stays small and
## is rendered once (quality mode), so the drifting clouds cost nothing per frame in the ambient light.

const SHADER: Shader = preload("res://features/world/view/shaders/night_sky.gdshader")
## Uniforms the shader needs that are not keys of the def.
const DERIVED: Array[StringName] = [&"moon_dir", &"glow_dir", &"milky_way_normal"]


static func make_sky(def: SkyDef) -> Sky:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	for key: StringName in def.floats:
		material.set_shader_parameter(key, def.floats[key])
	for key: StringName in def.colors:
		material.set_shader_parameter(key, def.colors[key])
	material.set_shader_parameter(&"moon_dir", direction(def.angles[&"moon_yaw"], def.angles[&"moon_elevation"]))
	material.set_shader_parameter(&"glow_dir", direction(def.angles[&"glow_yaw"], 0.0))
	material.set_shader_parameter(&"milky_way_normal", band_normal(def))
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	return sky


## Unit vector at this yaw (0 = north = -Z, positive turns toward -X) and elevation above the horizon.
static func direction(yaw_degrees: float, elevation_degrees: float) -> Vector3:
	var dir := Vector3(0.0, 0.0, -1.0).rotated(Vector3.RIGHT, deg_to_rad(elevation_degrees))
	return dir.rotated(Vector3.UP, deg_to_rad(yaw_degrees))


## Normal of the milky way's great circle: the band lies where a direction is perpendicular to it.
static func band_normal(def: SkyDef) -> Vector3:
	var normal := Vector3.UP.rotated(Vector3.FORWARD, deg_to_rad(def.angles[&"milky_way_tilt"]))
	return normal.rotated(Vector3.UP, deg_to_rad(def.angles[&"milky_way_yaw"])).normalized()
