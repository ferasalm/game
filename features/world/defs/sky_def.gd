class_name SkyDef
extends Def
## The night sky as data (content/world/sky.json): gradient, stars, milky way, moon, two cloud layers and the
## megacity glow. Every number and colour key is the name of a uniform in view/shaders/night_sky.gdshader
## (SkyBuilder copies them); the angles (moon, city glow, milky way) become direction vectors in SkyBuilder.

## Number keys with their allowed range.
const FLOATS: Dictionary = {
	"gradient_power": [0.1, 4.0], "haze_falloff": [0.5, 30.0], "haze_strength": [0.0, 4.0],
	"star_scale": [10.0, 400.0], "star_density": [0.0, 1.0], "star_size": [0.01, 0.5],
	"star_brightness": [0.0, 20.0], "star_twinkle_speed": [0.0, 20.0], "star_twinkle_depth": [0.0, 1.0],
	"milky_way_strength": [0.0, 4.0], "milky_way_width": [0.01, 2.0], "milky_way_scale": [0.5, 20.0],
	"moon_size": [0.005, 0.5], "moon_energy": [0.0, 20.0], "moon_mare_strength": [0.0, 1.0],
	"moon_crater_strength": [0.0, 1.0], "moon_halo_size": [0.005, 2.0], "moon_halo_strength": [0.0, 8.0],
	"moon_wide_halo_strength": [0.0, 4.0],
	"cloud_light_strength": [0.0, 20.0], "cloud_rim_width": [0.01, 1.0],
	"cloud1_scale": [0.05, 10.0], "cloud1_speed_x": [-1.0, 1.0], "cloud1_speed_y": [-1.0, 1.0],
	"cloud1_coverage": [0.0, 1.0], "cloud1_softness": [0.01, 1.0], "cloud1_opacity": [0.0, 1.0],
	"cloud2_scale": [0.05, 10.0], "cloud2_speed_x": [-1.0, 1.0], "cloud2_speed_y": [-1.0, 1.0],
	"cloud2_coverage": [0.0, 1.0], "cloud2_softness": [0.01, 1.0], "cloud2_opacity": [0.0, 1.0],
	"glow_sharpness": [0.5, 40.0], "glow_height": [0.02, 2.0], "glow_strength": [0.0, 10.0],
	"glow_all_round": [0.0, 2.0],
}
## Colour keys ("#rrggbb").
const COLORS: Array[String] = ["zenith_color", "horizon_color", "haze_color", "ground_color", "moon_color",
	"moon_halo_color", "milky_way_color", "cloud_dark_color", "cloud_lit_color", "glow_low_color",
	"glow_high_color", "star_cool_color", "star_warm_color"]
## Angle keys in degrees (elevation above the horizon, yaw 0 = north / -Z, positive turns toward -X).
const ANGLES: Dictionary = {
	"moon_elevation": [0.0, 89.0], "moon_yaw": [-180.0, 180.0], "glow_yaw": [-180.0, 180.0],
	"milky_way_tilt": [-90.0, 90.0], "milky_way_yaw": [-180.0, 180.0],
}

var floats: Dictionary[StringName, float] = {}
var colors: Dictionary[StringName, Color] = {}
var angles: Dictionary[StringName, float] = {}


func read(r: DefReader) -> void:
	id = r.id()
	for key: String in FLOATS:
		var bounds: Array = FLOATS[key]
		floats[StringName(key)] = r.number(key, bounds[0], bounds[1])
	for key: String in COLORS:
		colors[StringName(key)] = r.color(key)
	for key: String in ANGLES:
		var bounds: Array = ANGLES[key]
		angles[StringName(key)] = r.number(key, bounds[0], bounds[1])
