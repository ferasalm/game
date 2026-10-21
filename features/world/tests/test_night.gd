extends TestCase
## Night look: the sky def feeds every shader uniform, look "night" builds a sky environment with fog and a fill
## light while "v1" stays the flat daytime look, bad look keys are caught, the vista zone and mist layers load.


func _env(look_id: StringName) -> Environment:
	var look := ContentDB.get_def("look", look_id) as LookDef
	var world: WorldEnvironment = Diorama.make_environment(look)
	var env: Environment = world.environment
	world.free()
	return env


func test_sky_def_and_shader_uniforms_match() -> void:
	var def := ContentDB.get_def("sky", &"sanaa_night") as SkyDef
	check(def != null, "sky sanaa_night exists")
	var uniforms: Array[StringName] = []
	for entry: Dictionary in SkyBuilder.SHADER.get_shader_uniform_list():
		uniforms.append(StringName(entry["name"] as String))
	for key: StringName in def.floats:
		check(uniforms.has(key), "def number '%s' is not a shader uniform" % key)
	for key: StringName in def.colors:
		check(uniforms.has(key), "def colour '%s' is not a shader uniform" % key)
	for name: StringName in uniforms:
		check(def.floats.has(name) or def.colors.has(name) or SkyBuilder.DERIVED.has(name),
			"shader uniform '%s' has no value in the sky def" % name)


func test_sky_directions() -> void:
	var moon: Vector3 = SkyBuilder.direction(-28.0, 30.0)
	check(is_equal_approx(moon.length(), 1.0), "unit vector")
	check(is_equal_approx(moon.y, 0.5), "elevation 30 degrees is y = 0.5")
	check(moon.x > 0.0 and moon.z < 0.0, "yaw -28 is north and a little east (+X)")
	check(SkyBuilder.direction(0.0, 0.0).is_equal_approx(Vector3(0.0, 0.0, -1.0)), "yaw 0 elevation 0 is north")
	var def := ContentDB.get_def("sky", &"sanaa_night") as SkyDef
	check(is_equal_approx(SkyBuilder.band_normal(def).length(), 1.0), "the milky way normal is a unit vector")


func test_night_environment() -> void:
	var env: Environment = _env(&"night")
	check_eq(env.background_mode, Environment.BG_SKY, "the sky is the background")
	check(env.sky != null and env.sky.sky_material is ShaderMaterial, "the sky shader is set")
	check_eq(env.ambient_light_source, Environment.AMBIENT_SOURCE_SKY, "ambient comes from the sky")
	check_eq(env.tonemap_mode, Environment.TONE_MAPPER_AGX, "AgX tonemap")
	check(env.fog_enabled and env.fog_density > 0.0 and env.fog_height_density > 0.0, "depth and height fog are on")
	check(not env.volumetric_fog_enabled, "volumetric fog is off behind its quality flag")


func test_flat_look_is_unchanged() -> void:
	var env: Environment = _env(&"v1")
	check_eq(env.background_mode, Environment.BG_COLOR, "v1 keeps the flat background")
	check(not env.fog_enabled and not env.volumetric_fog_enabled, "v1 has no fog")
	check_eq(env.tonemap_mode, Environment.TONE_MAPPER_FILMIC, "v1 keeps filmic")


func test_sun_and_fill_light() -> void:
	var night := ContentDB.get_def("look", &"night") as LookDef
	var sun: DirectionalLight3D = Diorama.make_sun(night)
	check_eq(sun.get_child_count(), 1, "night has a fill light under the moon light")
	var fill := sun.get_child(0) as DirectionalLight3D
	check(fill != null and fill.top_level and not fill.shadow_enabled, "the fill is a global, shadowless directional light")
	check(sun.light_energy < 1.0 and sun.shadow_enabled, "the moonlight is dim and casts shadows")
	sun.free()
	var day: DirectionalLight3D = Diorama.make_sun(ContentDB.get_def("look", &"v1") as LookDef)
	check_eq(day.get_child_count(), 0, "v1 has no fill light")
	day.free()


func test_look_reports_bad_night_keys() -> void:
	var errors := PackedStringArray()
	var look := LookDef.new()
	var data: Dictionary = {"id": "bad", "camera_offset_x": 0, "camera_offset_y": 5, "camera_offset_z": 8, "look_height": 1,
		"fov": 30, "dof_near": 5, "dof_far": 12, "dof_amount": 0.1, "sun_pitch": -40, "sun_yaw": 0, "sun_color": "#ffffff",
		"ambient_color": "#ffffff", "ambient_energy": 1, "background_color": "#000000", "glow_bloom": 0,
		"tonemap": "sepia", "fog_color": "nope", "exposure": 99}
	look.read(DefReader.new(data, "t", errors))
	check_eq(errors.size(), 3, "bad tonemap, fog colour and exposure are each reported once")
	data.erase("tonemap")
	data.erase("fog_color")
	data.erase("exposure")
	errors.clear()
	look = LookDef.new()
	look.read(DefReader.new(data, "t", errors))
	check(errors.is_empty(), "a look without the night keys still reads (defaults): " + "; ".join(errors))
	check_eq(look.sky_id, &"", "no sky by default")


func test_vista_zone_and_mist_content() -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	check(area.vista.has_area(), "the rooftop has a vista zone")
	check(area.problems().is_empty(), "layout and vista are fine: " + "; ".join(area.problems()))
	check(area.vista_world().position.y < 4.0, "the vista zone is at the north edge")
	var broken := AreaDef.new()
	broken.legend = area.legend
	broken.rows = area.rows
	broken.vista = Rect2i(20, 15, 10, 10)
	check(not broken.problems().is_empty(), "a vista zone outside the area is caught")
	var mist: Node3D = MistBuilder.build_area(area)
	var planes: int = 0
	for mist_id: StringName in area.mist:
		planes += (ContentDB.get_def("mist", mist_id) as MistDef).stack
	check_eq(mist.get_child_count(), planes, "one plane per sheet of each listed mist layer")
	check(area.mist.size() >= 2, "street fog and edge wisps are listed")
	var street := mist.get_child(0) as MeshInstance3D
	check(street.material_override is ShaderMaterial and street.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		"the mist plane is a shaderd, shadowless mesh")
	mist.free()


func test_camera_rig_checks_key_times() -> void:
	var errors := PackedStringArray()
	var def := CameraRigDef.new()
	var key: Dictionary = {"at": 9.0, "px": 0, "py": 1, "pz": 5, "tx": 0, "ty": 1, "tz": -9, "fov": 40, "dof": 1}
	def.read(DefReader.new({"id": "t", "intro_duration": 6.0, "intro_skip_blend": 0.3, "keys": [key],
		"vista_offset_y": 1, "vista_offset_z": 9, "vista_look_height": 3, "vista_fov": 30, "vista_dof": 1,
		"vista_ease": 2}, "t", errors))
	check_eq(errors.size(), 1, "a key at or after the intro's end is reported")
