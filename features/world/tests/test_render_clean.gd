extends TestCase
## purpose: Tests for render-clean: roof-floor overlay z-spacing, texture mipmaps, and anisotropic filtering.

const PALETTE_ID: StringName = &"main"
const MIN_SEPARATION: float = 0.005


func test_no_two_roof_floor_overlays_within_threshold() -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops_v4") as AreaDef
	var storm_def := ContentDB.get_def("storm", &"night_storm") as StormDef
	check(area != null and storm_def != null, "area and storm def exist")

	var rooftop := (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate() as Rooftop
	rooftop.area_id = &"souq_rooftops_v4"
	rooftop.look_id = &"night"
	tree.root.add_child(rooftop)

	var storm: StormHost = null
	for child: Node in rooftop.get_children():
		if child is StormHost:
			storm = child as StormHost
			break
	check(storm != null, "storm node exists in souq_rooftops_v4")
	var puddles: Array[Node] = storm.puddles_root.get_children() if storm != null and storm.puddles_root != null else []
	check(not puddles.is_empty(), "puddles exist")

	for i: int in puddles.size():
		var p1 := puddles[i] as MeshInstance3D
		var cx: int = floori(p1.position.x)
		var cz: int = floori(p1.position.z)
		var tile := ContentDB.get_def("tile", area.tile_id_at(cx, cz)) as TileDef
		var floor_y: float = tile.height if tile != null else 0.0
		var floor_diff: float = absf(p1.position.y - floor_y)
		check(floor_diff >= MIN_SEPARATION, "puddle %d lifted from floor by >= 0.005m (actual %.3fm)" % [i, floor_diff])

	check(absf(storm.splash_particles.position.y - (puddles[0] as MeshInstance3D).position.y) >= MIN_SEPARATION,
		"splash particles and puddle separated by >= 0.005m")
	rooftop.queue_free()


func test_puddles_reject_xz_overlap_on_one_roof() -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops_v4") as AreaDef
	var storm_def := ContentDB.get_def("storm", &"night_storm") as StormDef
	check(area != null and storm_def != null, "area and storm def exist")
	var orig_seed: int = storm_def.puddle_seed
	for seed_val: int in [orig_seed, orig_seed + 107]:
		storm_def.puddle_seed = seed_val
		var root := PuddleBuilder.build(area, storm_def, 0.0)
		var p_list: Array[Node] = root.get_children()
		for i: int in p_list.size():
			var p1 := p_list[i] as MeshInstance3D
			var tile1 := ContentDB.get_def("tile", area.tile_id_at(floori(p1.position.x), floori(p1.position.z))) as TileDef
			var y1: float = tile1.height if tile1 != null else 0.0
			var sz1 := (p1.mesh as PlaneMesh).size
			var r1 := Rect2(p1.position.x - sz1.x * 0.5, p1.position.z - sz1.y * 0.5, sz1.x, sz1.y)
			for j: int in range(i + 1, p_list.size()):
				var p2 := p_list[j] as MeshInstance3D
				var tile2 := ContentDB.get_def("tile", area.tile_id_at(floori(p2.position.x), floori(p2.position.z))) as TileDef
				var y2: float = tile2.height if tile2 != null else 0.0
				if is_equal_approx(y1, y2):
					var sz2 := (p2.mesh as PlaneMesh).size
					var r2 := Rect2(p2.position.x - sz2.x * 0.5, p2.position.z - sz2.y * 0.5, sz2.x, sz2.y)
					check(not r1.intersects(r2),
						"puddles %d and %d on roof y=%.2f do not overlap in XZ (seed %d)" % [i, j, y1, seed_val])
		root.free()
	storm_def.puddle_seed = orig_seed


func test_painted_surface_textures_have_mipmaps_and_anisotropic_filter() -> void:
	var palette := ContentDB.get_def("palette", PALETTE_ID) as PaletteDef
	check(palette != null, "palette exists")
	for pattern: StringName in SurfacePainter.PATTERNS:
		var images: Array[Image] = SurfacePainter.paint(pattern, palette.colors)
		check(images[0].has_mipmaps(), "surface pattern %s has mipmaps" % pattern)

	var building := ContentDB.get_def("building", &"tower_r1") as BuildingDef
	check(building != null, "building tower_r1 exists")
	var f_images: Array[Image] = SurfaceMaterials.facade_images(building, palette)
	check(f_images[0].has_mipmaps(), "facade albedo image has mipmaps")
	check(f_images[1].has_mipmaps(), "facade emission image has mipmaps")

	SurfaceMaterials.clear()
	var t_mat := SurfaceMaterials.tile(&"roof_plaster", palette) as StandardMaterial3D
	check(t_mat != null, "tile material built")
	check(t_mat.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC, "tile uses linear anisotropic filter")

	var f_mat := SurfaceMaterials.facade(building, palette) as StandardMaterial3D
	check(f_mat != null, "facade material built")
	check(f_mat.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC, "facade uses linear anisotropic filter")


func test_painted_b_viewport_aa_is_msaa2() -> void:
	var look := ContentDB.get_def("look", &"painted_b") as LookDef
	check(look != null and look.paint != null, "painted_b look and paint recipe exist")
	check_eq(look.paint.aa, &"msaa2", "painted_b recipe specifies aa: msaa2")
	var root := Node3D.new()
	tree.root.add_child(root)
	var env := Environment.new()
	var cam := Camera3D.new()
	root.add_child(cam)
	PaintedLook.finish(root, look, env, cam, null)
	var vp := root.get_viewport()
	check_eq(vp.msaa_3d, Viewport.MSAA_2X, "viewport has MSAA 2x")
	check_eq(vp.screen_space_aa, Viewport.SCREEN_SPACE_AA_DISABLED, "viewport has screen-space AA off")
	root.free()
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	vp.msaa_3d = Viewport.MSAA_2X


func test_painted_materials_have_mipmaps_and_anisotropic_filter() -> void:
	var look := ContentDB.get_def("look", &"painted_b") as LookDef
	var palette := ContentDB.get_def("palette", PALETTE_ID) as PaletteDef
	var building := ContentDB.get_def("building", &"tower_r1") as BuildingDef
	PaintedMaterials.use(look.paint)
	var t_mat := SurfaceMaterials.tile(&"roof_plaster", palette)
	check(t_mat is ShaderMaterial, "painted tile material is ShaderMaterial")
	var smat := t_mat as ShaderMaterial
	var albedo_tex := smat.get_shader_parameter(&"albedo_tex") as Texture2D
	check(albedo_tex != null and albedo_tex.get_image().has_mipmaps(), "painted tile albedo texture has mipmaps")
	check(albedo_tex.get_image().get_mipmap_count() > 0, "floor/roof materials of painted_b sample with mipmaps")

	var f_mat := SurfaceMaterials.facade(building, palette)
	check(f_mat is ShaderMaterial, "painted facade material is ShaderMaterial")
	var fsmat := f_mat as ShaderMaterial
	var f_albedo := fsmat.get_shader_parameter(&"albedo_tex") as Texture2D
	var f_emit := fsmat.get_shader_parameter(&"emission_tex") as Texture2D
	check(f_albedo != null and f_albedo.get_image().has_mipmaps(), "painted facade albedo texture has mipmaps")
	check(f_emit != null and f_emit.get_image().has_mipmaps(), "painted facade emission texture has mipmaps")

	var shader_code: String = fsmat.shader.code
	check(shader_code.contains("albedo_tex : source_color, filter_linear_mipmap_anisotropic"),
		"albedo_tex sampler has filter_linear_mipmap_anisotropic")
	check(shader_code.contains("emission_tex : source_color, filter_linear_mipmap_anisotropic"),
		"emission_tex sampler has filter_linear_mipmap_anisotropic")
	PaintedMaterials.use(null)


func test_baked_floor_textures_have_mipmaps() -> void:
	var image: Image = PaintedMaterials.load_baked(&"oil", "tile_roof_plaster")
	check(image != null, "oil bake of tile_roof_plaster loads")
	check(image.has_mipmaps(), "baked tile_roof_plaster image has mipmaps immediately from load_baked")


func test_puddle_shader_ring_antialias_set_from_content() -> void:
	var def := ContentDB.get_def("storm", &"night_storm") as StormDef
	check(def != null and def.get(&"puddle_ripple_antialias") != null, "storm def specifies puddle_ripple_antialias")
	var area := ContentDB.get_def("area", &"souq_rooftops_v4") as AreaDef
	var storm := StormBuilder.build(area) as StormHost
	check(storm != null and storm.puddles_root != null, "storm host with puddles exists")
	var puddles: Array[Node] = storm.puddles_root.get_children()
	check(not puddles.is_empty(), "puddles built")
	var pmesh := puddles[0] as MeshInstance3D
	var smat := pmesh.material_override as ShaderMaterial
	check(smat != null, "puddle has ShaderMaterial")
	var aa_val: Variant = smat.get_shader_parameter(&"ripple_antialias")
	check(aa_val != null and is_equal_approx(float(aa_val), float(def.get(&"puddle_ripple_antialias"))),
		"puddle shader uniform ripple_antialias matches storm.json content value")
	check(smat.shader.code.contains("uniform float ripple_antialias"), "puddle.gdshader declares ripple_antialias uniform")
	storm.free()

