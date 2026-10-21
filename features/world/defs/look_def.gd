class_name LookDef
extends Def
## The HD-2D look as data: camera offset and field of view, tilt-shift depth of field, key light, ambient light,
## background and bloom. Look v1 is the accepted daytime look-test picture; look "night" adds a sky (sky_id),
## tonemapping, depth and height fog, an optional volumetric fog (quality flag) and a cool fill light.
## Every key after glow_bloom is optional: its default keeps the v1 behaviour.

const TONEMAPS: Array[StringName] = [&"linear", &"reinhard", &"filmic", &"aces", &"agx"]

var camera_offset: Vector3 = Vector3(0.0, 6.0, 8.5)
var look_height: float = 0.8
var fov: float = 30.0
var dof_near: float = 5.0
var dof_far: float = 12.0
var dof_amount: float = 0.1
var sun_rotation: Vector3 = Vector3(-50.0, -35.0, 0.0)
var sun_color: Color = Color.WHITE
var ambient_color: Color = Color.WHITE
var ambient_energy: float = 0.5
var background_color: Color = Color.BLACK
var glow_bloom: float = 0.0
## Sky: "" = flat background colour. ambient_sky_mix: 1 = ambient light is the sky only, 0 = ambient_color only.
var sky_id: StringName = &""
var ambient_sky_mix: float = 1.0
var tonemap: StringName = &"filmic"
var exposure: float = 1.0
var white_point: float = 1.0
var glow_threshold: float = 1.0
var glow_intensity: float = 0.8
var glow_strength: float = 1.0
var sun_energy: float = 1.0
var sun_shadow_blur: float = 1.0
## Fill light (cool, no shadows, from the camera side); energy 0 = none.
var fill_rotation: Vector3 = Vector3(-30.0, 150.0, 0.0)
var fill_color: Color = Color.WHITE
var fill_energy: float = 0.0
## Depth fog (fog_density 0 = none), tinted by the sky; height fog pools below fog_height (fog_height_density 0 = none).
var fog_density: float = 0.0
var fog_color: Color = Color.WHITE
var fog_sky_affect: float = 0.0
var fog_aerial: float = 0.0
var fog_height: float = 0.0
var fog_height_density: float = 0.0
## Volumetric fog quality flag: off by default, costly on the Iris Xe.
var volumetric_fog: bool = false
var volumetric_density: float = 0.01
var volumetric_albedo: Color = Color.WHITE
var volumetric_length: float = 40.0


func read(r: DefReader) -> void:
	id = r.id()
	camera_offset = Vector3(r.number("camera_offset_x", -50.0, 50.0), r.number("camera_offset_y", 0.0, 50.0),
		r.number("camera_offset_z", -50.0, 50.0))
	look_height = r.number("look_height", 0.0, 5.0)
	fov = r.number("fov", 5.0, 120.0)
	dof_near = r.number("dof_near", 0.0, 100.0)
	dof_far = r.number("dof_far", 0.0, 200.0)
	dof_amount = r.number("dof_amount", 0.0, 1.0)
	sun_rotation = Vector3(r.number("sun_pitch", -90.0, 90.0), r.number("sun_yaw", -180.0, 180.0), 0.0)
	sun_color = r.color("sun_color")
	ambient_color = r.color("ambient_color")
	ambient_energy = r.number("ambient_energy", 0.0, 4.0)
	background_color = r.color("background_color")
	glow_bloom = r.number("glow_bloom", 0.0, 1.0)
	_read_night(r)
	_read_fog(r)


func references() -> Array[Array]:
	return [["sky", sky_id]] if sky_id != &"" else []


func _read_night(r: DefReader) -> void:
	sky_id = StringName(r.text("sky_id", "", false))
	ambient_sky_mix = r.number("ambient_sky_mix", 0.0, 1.0, ambient_sky_mix, false)
	tonemap = StringName(r.text("tonemap", String(tonemap), false))
	if not TONEMAPS.has(tonemap):
		r.problem("tonemap", "'%s' is not one of %s" % [tonemap, TONEMAPS])
	exposure = r.number("exposure", 0.1, 8.0, exposure, false)
	white_point = r.number("white_point", 0.5, 32.0, white_point, false)
	glow_threshold = r.number("glow_threshold", 0.0, 8.0, glow_threshold, false)
	glow_intensity = r.number("glow_intensity", 0.0, 4.0, glow_intensity, false)
	glow_strength = r.number("glow_strength", 0.0, 4.0, glow_strength, false)
	sun_energy = r.number("sun_energy", 0.0, 8.0, sun_energy, false)
	sun_shadow_blur = r.number("sun_shadow_blur", 0.0, 8.0, sun_shadow_blur, false)
	fill_energy = r.number("fill_energy", 0.0, 4.0, fill_energy, false)
	fill_rotation = Vector3(r.number("fill_pitch", -90.0, 90.0, fill_rotation.x, false),
		r.number("fill_yaw", -180.0, 180.0, fill_rotation.y, false), 0.0)
	fill_color = r.color("fill_color", fill_color, false)


func _read_fog(r: DefReader) -> void:
	fog_density = r.number("fog_density", 0.0, 1.0, fog_density, false)
	fog_color = r.color("fog_color", fog_color, false)
	fog_sky_affect = r.number("fog_sky_affect", 0.0, 1.0, fog_sky_affect, false)
	fog_aerial = r.number("fog_aerial", 0.0, 1.0, fog_aerial, false)
	fog_height = r.number("fog_height", -50.0, 50.0, fog_height, false)
	fog_height_density = r.number("fog_height_density", 0.0, 8.0, fog_height_density, false)
	volumetric_fog = r.flag("volumetric_fog", volumetric_fog)
	volumetric_density = r.number("volumetric_density", 0.0, 1.0, volumetric_density, false)
	volumetric_albedo = r.color("volumetric_albedo", volumetric_albedo, false)
	volumetric_length = r.number("volumetric_length", 1.0, 500.0, volumetric_length, false)
