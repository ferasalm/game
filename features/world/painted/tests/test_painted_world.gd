extends TestCase
## The painted world rules: the game look (painted_b) uses the hades camera and a brighter night, the cut-away
## globals exist, painted glow replaces the plain glow only while a painted look is in use, neon text is never
## alpha-cut, the sabil and the herb stall are painted (water, five qamariya panes, lights, splash, stall awning
## and herbs), the arena look is usable, and switching looks clears every cached material.


func _look(look_id: StringName) -> LookDef:
	return ContentDB.get_def("look", look_id) as LookDef


func _prop(prop_id: StringName) -> PropDef:
	return ContentDB.get_def("prop", prop_id) as PropDef


func test_painted_b_is_the_game_look() -> void:
	var look: LookDef = _look(&"painted_b")
	check_eq(look.camera_preset, &"hades", "the hades camera")
	check(look.paint.shadow_lift >= 0.5 and look.paint.min_light >= 0.15, "shadows lifted and a light floor so the night reads")
	check(look.paint.mist_bands > 0.0, "the mist falls in painted steps")
	check(not look.paint.figure, "no static figure: the live character models are the party")
	check(look.paint.occlude_radius > 0.0, "the cut-away is on")


func test_cut_away_globals_are_registered() -> void:
	var names: Array[StringName] = RenderingServer.global_shader_parameter_get_list()
	for global_name: StringName in [&"occ_cam", &"occ_target", &"occ_shape"]:
		check(names.has(global_name), "%s is a project shader global" % global_name)


func test_glow_is_painted_only_while_painted() -> void:
	PaintedMaterials.use(_look(&"painted_b").paint)
	check(SurfaceMaterials.glow() is ShaderMaterial, "a painted look: the cut-away glow shader")
	PaintedMaterials.use(null)
	check(SurfaceMaterials.glow() is StandardMaterial3D, "unpainted: the old glow")


func test_neon_labels_are_never_alpha_cut() -> void:
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	check(not area.signs.is_empty(), "the area has signs")
	for spec: SignSpec in area.signs:
		var sign_node := NeonSign.new(spec, palette)
		check_eq(sign_node.label.alpha_cut, Label3D.ALPHA_CUT_DISABLED, "sign %s text is never alpha-cut" % spec.key)
		sign_node.free()


func test_sabil_is_painted_water_and_qamariya_glass() -> void:
	var sabil: PropDef = _prop(&"sabil")
	var water: int = 0
	var panes: Dictionary = {}
	for part: PropPart in sabil.parts:
		water += 1 if part.water else 0
		if part.glow:
			panes[part.color] = true
	check(water >= 2, "a basin surface and a stream")
	for hue: String in ["R", "Y", "G", "B", "V"]:
		check(panes.has(hue), "a qamariya pane in %s" % hue)
	check(sabil.light != null and sabil.light.color.b > sabil.light.color.r, "a cool lamp light")
	check(sabil.splash != null and sabil.splash.count > 0, "drops where the stream lands")
	check(sabil.collide.x >= 1.5 and sabil.collide.y > 1.0, "it blocks walking")
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var mesh: ArrayMesh = PropMesh.mesh(sabil, palette)
	var last: Material = mesh.surface_get_material(mesh.get_surface_count() - 1)
	check(last is ShaderMaterial and (last as ShaderMaterial).shader == SurfaceMaterials.WATER_SHADER, "the water surface is drawn last")


func test_herb_stall_has_awning_herbs_and_a_warm_light() -> void:
	var stall: PropDef = _prop(&"herb_stall")
	var awning: int = 0
	var herbs: Dictionary = {}
	for part: PropPart in stall.parts:
		awning += 1 if part.color == "i" and part.size.x >= 0.5 else 0
		if part.shape == &"frustum" and ["M", "Y", "w", "G"].has(part.color):
			herbs[part.color] = true
	check(awning >= 2, "a striped awning")
	check_eq(herbs.size(), 4, "pink, yellow, white and green herb bundles")
	check(stall.light != null and stall.light.color.r > stall.light.color.b, "a warm light")
	check(stall.collide.x >= 2.0, "the counter blocks walking")


func test_prop_builder_places_the_splash_with_the_prop() -> void:
	var area := AreaDef.new()
	var placement := Placement.new()
	placement.ref = &"sabil"
	placement.pos = Vector3(5.0, 0.0, 6.0)
	area.props.append(placement)
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var root: Node3D = PropBuilder.build(area, palette, 0.4)
	var splash: CPUParticles3D = root.find_child("Splash", true, false) as CPUParticles3D
	check(splash != null, "a sabil placement brings its splash")
	if splash != null:
		check(absf(splash.position.x - 5.0) < 0.01 and absf(splash.position.y - 1.04) < 0.01, "at the prop, up at the stream's end")
	root.free()


func test_arena_look_painted_b_is_usable() -> void:
	var look: LookDef = _look(&"painted_b")
	check(look != null and look.paint != null and ContentDB.get_def("sky", look.sky_id) != null, "a painted look with its sky")
	check(ContentDB.get_def("camera_rig", &"explore") != null and (ContentDB.get_def("camera_rig", &"explore") as CameraRigDef).presets.has(look.camera_preset),
		"its camera preset exists")


func test_look_switch_clears_the_material_caches() -> void:
	PaintedMaterials.use(_look(&"painted_b").paint)
	var first: Material = SurfaceMaterials.glow()
	PaintedMaterials.use(_look(&"painted_b").paint)
	check(SurfaceMaterials.glow() != first, "a fresh use() builds fresh materials")
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var mesh_a: ArrayMesh = PropMesh.mesh(_prop(&"herb_stall"), palette)
	PaintedMaterials.use(null)
	var mesh_b: ArrayMesh = PropMesh.mesh(_prop(&"herb_stall"), palette)
	check(mesh_a != mesh_b, "the cached prop meshes are rebuilt for the new look")
