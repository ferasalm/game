class_name StormDef
extends Def
## Weather preset for rain, splashes, puddles, drips, steam and lightning (content/world/storm.json).

const MAX_RAIN_COUNT: int = 3000
const MAX_SPLASH_COUNT: int = 120
const MAX_STEAM_COUNT: int = 40

var rain_box: Vector3 = Vector3(24.0, 14.0, 24.0)
var rain_count: int = 2400
var rain_speed: float = 14.0
var rain_wind: Vector3 = Vector3(-1.8, 0.0, 0.6)
var rain_color: Color = Color(0.72, 0.82, 0.94)
var rain_alpha: float = 0.32
var rain_streak_width: float = 0.015
var rain_streak_length: float = 0.45
var rain_floor_margin: float = 2.0

var splash_box: Vector2 = Vector2(10.0, 10.0)
var splash_count: int = 100
var splash_lifetime: float = 0.3
var splash_size: float = 0.2
var splash_color: Color = Color(0.77, 0.86, 1.0)
var splash_alpha: float = 0.4
var splash_height_offset: float = 0.035
var splash_fade_in: float = 0.2
var splash_fade_out: float = 0.7
var splash_scale_start: float = 0.25

var puddle_count_min: int = 6
var puddle_count_max: int = 10
var puddle_wall_margin: float = 0.6
var puddle_height_offset: float = 0.02
var puddle_roughness: float = 0.08
var puddle_darken: float = 0.65
var puddle_sky_ambient: Color = Color(0.08, 0.11, 0.18)
var puddle_neon_magenta: Color = Color(1.0, 0.11, 0.47)
var puddle_neon_cyan: Color = Color(0.0, 0.83, 1.0)
var puddle_ripple_speed: float = 2.4
var puddle_ripple_frequency: float = 14.0
var puddle_ripple_fade_in: float = 0.2
var puddle_ripple_wave_speed: float = 0.7
var puddle_ripple_decay: float = 16.0
var puddle_ripple_normal_weight: float = 0.22
var puddle_ripple_antialias: float = 0.025
var puddle_size_min: float = 1.2
var puddle_size_max: float = 2.2
var puddle_seed: int = 42

var drip_interval_min: float = 0.4
var drip_interval_max: float = 0.9
var drip_speed: float = 9.8
var drip_color: Color = Color(0.75, 0.83, 0.94)
var drip_size: float = 0.025
var drip_splash_lifetime: float = 0.15

var steam_count_max: int = 40
var steam_lifetime: float = 2.5
var steam_speed: float = 1.2
var steam_color: Color = Color(0.85, 0.89, 0.94)
var steam_alpha: float = 0.12
var steam_size: float = 0.75

var lightning_enabled: bool = true
var lightning_interval_min: float = 25.0
var lightning_interval_max: float = 60.0
var lightning_duration: float = 0.15
var lightning_energy_boost: float = 2.5
var lightning_color: Color = Color(0.8, 0.88, 1.0)
## Peak alpha of the screen-wide flash (the painted shaders draw their own light, so a light alone barely shows).
var lightning_screen_alpha: float = 0.0


func read(r: DefReader) -> void:
	id = r.id()
	_read_rain(r)
	_read_splashes(r)
	_read_puddles(r)
	_read_drips(r)
	_read_steam(r)
	_read_lightning(r)


func _read_rain(r: DefReader) -> void:
	var box: Array[float] = r.float_list("rain_box", 1.0, 100.0)
	if box.size() == 3:
		rain_box = Vector3(box[0], box[1], box[2])
	else:
		r.problem("rain_box", "needs 3 numbers: x, y, z")
	rain_count = r.integer("rain_count", 1, MAX_RAIN_COUNT)
	rain_speed = r.number("rain_speed", 0.1, 100.0)
	var wind: Array[float] = r.float_list("rain_wind", -50.0, 50.0)
	if wind.size() == 3:
		rain_wind = Vector3(wind[0], wind[1], wind[2])
	else:
		r.problem("rain_wind", "needs 3 numbers: x, y, z")
	rain_color = r.color("rain_color")
	rain_alpha = r.number("rain_alpha", 0.05, 1.0)
	rain_streak_width = r.number("rain_streak_width", 0.001, 1.0)
	rain_streak_length = r.number("rain_streak_length", 0.01, 5.0)
	rain_floor_margin = r.number("rain_floor_margin", 0.0, 20.0)


func _read_splashes(r: DefReader) -> void:
	var sbox: Array[float] = r.float_list("splash_box", 1.0, 100.0)
	if sbox.size() == 2:
		splash_box = Vector2(sbox[0], sbox[1])
	else:
		r.problem("splash_box", "needs 2 numbers: x, z")
	splash_count = r.integer("splash_count", 1, MAX_SPLASH_COUNT)
	splash_lifetime = r.number("splash_lifetime", 0.05, 5.0)
	splash_size = r.number("splash_size", 0.01, 2.0)
	splash_color = r.color("splash_color")
	splash_alpha = r.number("splash_alpha", 0.05, 1.0)
	splash_height_offset = r.number("splash_height_offset", 0.0, 1.0, 0.035, false)
	splash_fade_in = r.number("splash_fade_in", 0.01, 1.0, 0.2, false)
	splash_fade_out = r.number("splash_fade_out", 0.01, 1.0, 0.7, false)
	splash_scale_start = r.number("splash_scale_start", 0.01, 1.0, 0.25, false)


func _read_puddles(r: DefReader) -> void:
	puddle_count_min = r.integer("puddle_count_min", 1, 50)
	puddle_count_max = r.integer("puddle_count_max", 1, 50)
	if puddle_count_max < puddle_count_min:
		r.problem("puddle_count_max", "must be >= puddle_count_min")
	puddle_wall_margin = r.number("puddle_wall_margin", 0.1, 10.0)
	puddle_height_offset = r.number("puddle_height_offset", 0.0, 1.0)
	puddle_roughness = r.number("puddle_roughness", 0.0, 1.0)
	puddle_darken = r.number("puddle_darken", 0.0, 1.0)
	puddle_sky_ambient = r.color("puddle_sky_ambient")
	puddle_neon_magenta = r.color("puddle_neon_magenta")
	puddle_neon_cyan = r.color("puddle_neon_cyan")
	puddle_ripple_speed = r.number("puddle_ripple_speed", 0.1, 20.0)
	puddle_ripple_frequency = r.number("puddle_ripple_frequency", 0.1, 50.0)
	puddle_ripple_fade_in = r.number("puddle_ripple_fade_in", 0.01, 1.0, 0.2, false)
	puddle_ripple_wave_speed = r.number("puddle_ripple_wave_speed", 0.1, 5.0, 0.7, false)
	puddle_ripple_decay = r.number("puddle_ripple_decay", 1.0, 50.0, 16.0, false)
	puddle_ripple_normal_weight = r.number("puddle_ripple_normal_weight", 0.01, 1.0, 0.22, false)
	puddle_ripple_antialias = r.number("puddle_ripple_antialias", 0.001, 1.0, 0.025, false)
	puddle_size_min = r.number("puddle_size_min", 0.1, 10.0)
	puddle_size_max = r.number("puddle_size_max", 0.1, 10.0)
	if puddle_size_max < puddle_size_min:
		r.problem("puddle_size_max", "must be >= puddle_size_min")
	puddle_seed = r.integer("puddle_seed", 0, 1000000)


func _read_drips(r: DefReader) -> void:
	drip_interval_min = r.number("drip_interval_min", 0.05, 10.0)
	drip_interval_max = r.number("drip_interval_max", 0.05, 10.0)
	if drip_interval_max < drip_interval_min:
		r.problem("drip_interval_max", "must be >= drip_interval_min")
	drip_speed = r.number("drip_speed", 0.1, 50.0)
	drip_color = r.color("drip_color")
	drip_size = r.number("drip_size", 0.005, 1.0)
	drip_splash_lifetime = r.number("drip_splash_lifetime", 0.02, 2.0)


func _read_steam(r: DefReader) -> void:
	steam_count_max = r.integer("steam_count_max", 1, MAX_STEAM_COUNT)
	steam_lifetime = r.number("steam_lifetime", 0.1, 20.0)
	steam_speed = r.number("steam_speed", 0.1, 20.0)
	steam_color = r.color("steam_color")
	steam_alpha = r.number("steam_alpha", 0.01, 1.0)
	steam_size = r.number("steam_size", 0.05, 5.0)


func _read_lightning(r: DefReader) -> void:
	lightning_enabled = r.flag("lightning_enabled")
	lightning_interval_min = r.number("lightning_interval_min", 1.0, 300.0)
	lightning_interval_max = r.number("lightning_interval_max", 1.0, 300.0)
	if lightning_interval_max < lightning_interval_min:
		r.problem("lightning_interval_max", "must be >= lightning_interval_min")
	lightning_duration = r.number("lightning_duration", 0.02, 5.0)
	lightning_energy_boost = r.number("lightning_energy_boost", 0.0, 50.0)
	lightning_color = r.color("lightning_color")
	lightning_screen_alpha = r.number("lightning_screen_alpha", 0.0, 1.0)
