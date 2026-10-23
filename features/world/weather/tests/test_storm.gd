extends TestCase
## Storm weather tests: StormDef validation, particle caps, puddle placement, emitters per point, lightning flag,
## and area weather hook.


func test_storm_def_parses_every_field() -> void:
	var def := ContentDB.get_def("storm", &"night_storm") as StormDef
	check(def != null, "night_storm def exists")
	check(def.rain_count > 0 and def.rain_count <= 3000, "rain count within the 3000 cap")
	check(is_equal_approx(def.rain_speed, 14.0), "rain speed 14 m/s")
	check(def.rain_box.is_equal_approx(Vector3(24.0, 14.0, 24.0)), "rain box 24x14x24")
	check(def.splash_count == 100, "splash count 100")
	check(is_equal_approx(def.splash_lifetime, 0.3), "splash lifetime 0.3s")
	check(def.puddle_count_min == 6 and def.puddle_count_max == 10, "puddle range 6..10")
	check(is_equal_approx(def.puddle_wall_margin, 0.6), "puddle wall margin 0.6m")
	check(is_equal_approx(def.puddle_height_offset, 0.02), "puddle height offset 0.02m")
	check(is_equal_approx(def.splash_height_offset, 0.035), "splash height offset 0.035m")
	check(def.lightning_enabled, "lightning enabled by default")
	check(def.steam_count_max == 40, "steam cap 40")


func test_storm_def_rejects_bad_fields() -> void:
	var errors := PackedStringArray()
	var bad_dict: Dictionary = {
		"id": "bad_storm",
		"rain_box": [24.0, 14.0],
		"rain_count": 3500,
		"splash_count": 200,
		"steam_count_max": 50,
		"puddle_count_min": 10,
		"puddle_count_max": 5
	}
	var reader := DefReader.new(bad_dict, "test[0]", errors)
	var bad_def := StormDef.new()
	bad_def.read(reader)
	check(not errors.is_empty(), "bad fields generate reader errors")
	var error_text: String = " ".join(errors)
	check(error_text.contains("rain_count"), "catches rain count over cap")
	check(error_text.contains("splash_count"), "catches splash count over cap")
	check(error_text.contains("steam_count_max"), "catches steam count over cap")
	check(error_text.contains("puddle_count_max"), "catches max < min")


func test_particle_counts_never_exceed_caps() -> void:
	var def := ContentDB.get_def("storm", &"night_storm") as StormDef
	check(def.rain_count <= StormDef.MAX_RAIN_COUNT, "rain count within cap")
	check(def.splash_count <= StormDef.MAX_SPLASH_COUNT, "splash count within cap")
	check(def.steam_count_max <= StormDef.MAX_STEAM_COUNT, "steam count within cap")
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var storm := StormBuilder.build(area) as StormHost
	check(storm != null, "storm built for souq_rooftops")
	check(storm.rain_particles.amount <= StormDef.MAX_RAIN_COUNT, "rain emitter within cap")
	check(storm.splash_particles.amount <= StormDef.MAX_SPLASH_COUNT, "splash emitter within cap")
	storm.free()


func test_puddles_stay_on_floor_and_clear_of_walls() -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var storm1 := StormBuilder.build(area) as StormHost
	var storm2 := StormBuilder.build(area) as StormHost
	var puddles1 := storm1.puddles_root.get_children()
	var puddles2 := storm2.puddles_root.get_children()
	check(puddles1.size() >= 6 and puddles1.size() <= 10, "puddle count in 6..10")
	check(puddles1.size() == puddles2.size(), "same seed yields same count")
	for i: int in puddles1.size():
		var p1: MeshInstance3D = puddles1[i] as MeshInstance3D
		var p2: MeshInstance3D = puddles2[i] as MeshInstance3D
		check(p1.position.is_equal_approx(p2.position), "puddle %d position matches across runs" % i)
		var cx: int = floori(p1.position.x)
		var cz: int = floori(p1.position.z)
		check(area.is_walkable(cx, cz), "puddle %d is on walkable floor tile" % i)
		var dist: float = PuddleBuilder.min_wall_dist(area, Vector2(p1.position.x, p1.position.z))
		check(dist >= 0.6, "puddle %d is >= 0.6m from walls (actual %.2f)" % [i, dist])
	storm1.free()
	storm2.free()


func test_drips_and_steam_make_one_emitter_per_point() -> void:
	var drip_host := Node3D.new()
	var drip_pts: Array[Vector3] = [Vector3(1.0, 2.0, 3.0), Vector3(4.0, 5.0, 6.0)]
	StormBuilder.add_drips(drip_host, drip_pts)
	check(drip_host.get_child_count() == 2, "drips make one emitter per point")
	drip_host.free()
	var steam_host := Node3D.new()
	var steam_pts: Array[Vector3] = [Vector3(0.0, 0.0, 0.0), Vector3(1.0, 1.0, 1.0), Vector3(2.0, 2.0, 2.0)]
	StormBuilder.add_steam(steam_host, steam_pts)
	check(steam_host.get_child_count() == 3, "steam makes one emitter per point")
	for child: Node in steam_host.get_children():
		var emitter := child as GPUParticles3D
		check(emitter != null and emitter.amount <= StormDef.MAX_STEAM_COUNT, "steam emitter capped at 40")
	steam_host.free()


func test_lightning_off_when_flag_off() -> void:
	var host := StormHost.new()
	var def := StormDef.new()
	def.lightning_enabled = false
	host.def = def
	check(not host.is_lightning_active(), "lightning inactive when flag off")
	host.trigger_lightning()
	check(not host.is_flashing(), "trigger does not flash when disabled")
	host.free()


## Review 2026-10-23: a light alone barely showed through the painted shaders; the flash also washes the screen.
func test_lightning_washes_the_screen_and_clears() -> void:
	var def := ContentDB.get_def("storm", &"night_storm") as StormDef
	var host := StormHost.new()
	host.def = def
	tree.root.add_child(host)
	host.trigger_lightning()
	host._update_lightning(def.lightning_duration * 0.2)
	check(host.flash_rect.color.a > 0.0, "the flash washes the screen")
	host._update_lightning(def.lightning_duration)
	check(is_zero_approx(host.flash_rect.color.a) and not host.is_flashing(), "and clears when the flash ends")
	host.free()


func test_area_without_weather_builds_no_storm() -> void:
	var empty_area := AreaDef.new()
	empty_area.weather = ""
	var result := StormBuilder.build(empty_area)
	check(result == null, "area without weather builds no storm")


func test_splash_alpha_curve_and_fade() -> void:
	var def := ContentDB.get_def("storm", &"night_storm") as StormDef
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var storm := StormBuilder.build(area) as StormHost
	check(storm != null, "storm built")
	var mat := storm.splash_particles.process_material as ParticleProcessMaterial
	check(mat != null, "process material exists")
	check(mat.alpha_curve != null or mat.color_ramp != null, "splash particles have fade in/out curve")
	storm.free()
