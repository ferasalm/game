extends TestCase
## purpose: Tests for storm puddles: wall margins, repeatability, shader fade uniforms, and ALPHA blend.


func test_puddles_stay_on_floor_and_clear_of_walls() -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var storm1 := StormBuilder.build(area) as StormHost
	var storm2 := StormBuilder.build(area) as StormHost
	var puddles1: Array[Node] = storm1.puddles_root.get_children()
	var puddles2: Array[Node] = storm2.puddles_root.get_children()
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


func test_puddle_shader_fade_reaches_alpha() -> void:
	var shader := PuddleBuilder.PUDDLE_SHADER
	check(shader != null, "puddle shader loaded")
	var code: String = shader.code
	check(code.contains("ALPHA = edge_alpha * ring_fade;"), "puddle shader writes ripple fade into ALPHA")
	var area := ContentDB.get_def("area", &"souq_rooftops_v4") as AreaDef
	var storm_def := ContentDB.get_def("storm", &"night_storm") as StormDef
	var root := PuddleBuilder.build(area, storm_def, 0.0)
	check(root.get_child_count() > 0, "puddles built")
	var p := root.get_child(0) as MeshInstance3D
	var mat := p.material_override as ShaderMaterial
	check(mat != null, "puddle has shader material")
	check(is_equal_approx(mat.get_shader_parameter(&"ripple_fade_in"), storm_def.puddle_ripple_fade_in),
		"fade in uniform reaches material")
	check(is_equal_approx(mat.get_shader_parameter(&"ripple_normal_weight"), storm_def.puddle_ripple_normal_weight),
		"normal weight uniform reaches material")
	root.free()
