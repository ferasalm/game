extends TestCase
## Night Sana'a textures: the facade painter (size, determinism, lit windows and qamariya glass in the emission
## map, a door, every pixel painted), the surface patterns (tile 4 m, deterministic, tileable) and the tile content.


func _colors() -> Dictionary[String, Color]:
	return (ContentDB.get_def("palette", &"main") as PaletteDef).colors


func _spec(lit: float, seed_value: int = 5) -> FacadeSpec:
	var spec := FacadeSpec.new()
	spec.width_m = 5
	spec.floors = 4
	spec.stone_floors = 1
	spec.columns = 2
	spec.qamariya = ["R"]
	spec.lit_ratio = lit
	spec.shutter_ratio = 0.0
	spec.door = true
	spec.seed_value = seed_value
	return spec


func _has_color(img: Image, color: Color) -> bool:
	for y: int in img.get_height():
		for x: int in img.get_width():
			if img.get_pixel(x, y).is_equal_approx(color):
				return true
	return false


func test_facade_size_is_32_px_per_metre() -> void:
	var images: Array[Image] = FacadePainter.paint(_spec(0.5), _colors())
	check_eq(images[0].get_size(), Vector2i(5 * 32, 4 * 96), "albedo size")
	check_eq(images[1].get_size(), images[0].get_size(), "emission has the same size")


func test_facade_is_deterministic_per_seed() -> void:
	var a: Array[Image] = FacadePainter.paint(_spec(0.5, 5), _colors())
	var b: Array[Image] = FacadePainter.paint(_spec(0.5, 5), _colors())
	var c: Array[Image] = FacadePainter.paint(_spec(0.5, 6), _colors())
	check(a[0].get_data() == b[0].get_data(), "same seed, same picture")
	check(a[0].get_data() != c[0].get_data(), "another seed, another picture")


func test_every_facade_pixel_is_painted() -> void:
	for id: StringName in ContentDB.ids("building"):
		var def := ContentDB.get_def("building", id) as BuildingDef
		for side: bool in [false, true]:
			var img: Image = FacadePainter.paint(def.facade_spec(side), _colors())[0]
			check(not _has_color(img, Color.MAGENTA), "%s side=%s has an unpainted pixel" % [id, side])


func test_lit_windows_and_qamariya_glow() -> void:
	var lit: Array[Image] = FacadePainter.paint(_spec(1.0), _colors())
	var dark: Array[Image] = FacadePainter.paint(_spec(0.0), _colors())
	var amber: Color = _colors()["Y"]
	var red: Color = _colors()["R"]
	check(_has_color(lit[1], amber), "lit window glows amber")
	check(_has_color(lit[1], red), "lit qamariya glass glows in its colour")
	check(_has_color(lit[0], red), "qamariya glass is painted red when lit")
	check(not _has_color(dark[1], amber) and not _has_color(dark[1], red), "unlit windows do not glow")
	check(not _has_color(dark[0], red), "unlit qamariya is dark")


func test_door_only_when_asked() -> void:
	var with_door: FacadeSpec = _spec(0.0)
	var without: FacadeSpec = _spec(0.0)
	without.door = false
	var a: Image = FacadePainter.paint(with_door, _colors())[0]
	var b: Image = FacadePainter.paint(without, _colors())[0]
	check(a.get_data() != b.get_data(), "a door changes the ground floor")
	var studs: Color = _colors()["y"]
	check(_has_color(a, studs) and not _has_color(b, studs), "door studs only on the door facade")


func test_surface_patterns_are_painted_and_seeded() -> void:
	for pattern: StringName in SurfacePainter.PATTERNS:
		var a: Image = SurfacePainter.paint(pattern, _colors(), 3)[0]
		var b: Image = SurfacePainter.paint(pattern, _colors(), 3)[0]
		check_eq(a.get_size(), Vector2i(SurfacePainter.SIZE, SurfacePainter.SIZE), "%s size" % pattern)
		check(a.get_data() == b.get_data(), "%s is deterministic" % pattern)
		check(not _has_color(a, Color.MAGENTA), "%s has an unpainted pixel" % pattern)


func test_canvas_wraps_so_textures_tile() -> void:
	var canvas := PixelCanvas.new(8, 8, _colors())
	canvas.wrap = true
	canvas.rect(6, 6, 4, 4, "x")
	check(canvas.img.get_pixel(0, 0).is_equal_approx(_colors()["x"]), "the rectangle wraps to the far corner")
	check(canvas.img.get_pixel(7, 7).is_equal_approx(_colors()["x"]), "and stays at the near one")
	canvas.wrap = false
	canvas.clip = Rect2i(0, 0, 4, 4)
	canvas.px(5, 5, "k")
	check(not canvas.img.get_pixel(5, 5).is_equal_approx(_colors()["k"]), "pixels outside the clip are dropped")


func test_every_tile_pattern_is_known() -> void:
	var patterned: int = 0
	for id: StringName in ContentDB.ids("tile"):
		var tile := ContentDB.get_def("tile", id) as TileDef
		if tile.pattern != &"":
			patterned += 1
			check(SurfacePainter.PATTERNS.has(tile.pattern), "tile %s pattern %s exists" % [id, tile.pattern])
	check(patterned >= 6, "the walkable and wall tiles are patterned")


func test_area_builder_textures_patterned_tiles() -> void:
	var area := ContentDB.get_def("area", &"souq_rooftops") as AreaDef
	var rules := ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef
	var root: Node3D = AreaBuilder.build(area, rules)
	var textured: int = 0
	for child: Node in root.get_children():
		var multi := child as MultiMeshInstance3D
		var mat := multi.multimesh.mesh.material as StandardMaterial3D if multi != null else null
		if mat != null and mat.albedo_texture != null and mat.uv1_world_triplanar:
			textured += 1
	root.free()
	check(textured >= 5, "textured tile batches: %d" % textured)
