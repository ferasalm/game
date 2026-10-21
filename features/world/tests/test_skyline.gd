extends TestCase
## Night Sana'a city: building and skyline content, the layout rules (outside the area, out of the al-Saila
## corridor, inside the band, deterministic), the tower-house mesh, the landmarks and the draw-call budget.

const DRAW_BUDGET: int = 70


func _skyline() -> SkylineDef:
	return ContentDB.get_def("skyline", &"old_city") as SkylineDef


func _area() -> AreaDef:
	return ContentDB.get_def("area", &"souq_rooftops") as AreaDef


func _footprints() -> Dictionary[StringName, Vector2]:
	var out: Dictionary[StringName, Vector2] = {}
	for id: StringName in ContentDB.ids("building"):
		var b := ContentDB.get_def("building", id) as BuildingDef
		out[id] = Vector2(b.footprint_w, b.footprint_d)
	return out


func _rect() -> Rect2:
	return Rect2(0.0, 0.0, _area().width(), _area().depth())


func _read(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var def := BuildingDef.new()
	def.read(DefReader.new(data, "t", errors))
	return errors


func _good() -> Dictionary:
	return {"id": "t", "footprint_w": 5, "footprint_d": 5, "floors": 5, "stone_floors": 1, "columns_front": 2,
		"columns_side": 2, "frieze": "zigzag", "qamariya": ["R"], "lit_ratio": 0.3, "parapet": "stepped", "seed": 1}


func test_buildings_and_skyline_content() -> void:
	check(ContentDB.ids("building").size() >= 6, "several building types")
	check(_skyline() != null and _skyline().bands.size() == 3, "three depth bands")
	var kinds: Array[StringName] = []
	for mark: SkylineLandmark in _skyline().landmarks:
		kinds.append(mark.kind)
	for kind: StringName in SkylineLandmark.KINDS:
		check(kinds.has(kind), "landmark kind %s is placed" % kind)
	check_eq(kinds.count(&"minaret"), 2, "two minarets")


func test_broken_buildings_are_caught() -> void:
	check(_read(_good()).is_empty(), "a good building passes")
	var cases: Array[Dictionary] = [{"columns_front": 5}, {"stone_floors": 5}, {"frieze": "stripes"},
		{"qamariya": []}, {"parapet": "domed"}, {"roof_extras": ["jacuzzi"]}, {"footprint_w": 1}]
	for change: Dictionary in cases:
		var data: Dictionary = _good()
		data.merge(change, true)
		check(not _read(data).is_empty(), "caught: %s" % str(change))


func test_layout_is_deterministic_and_outside() -> void:
	var a: Array[SkylineLayout.Block] = SkylineLayout.place(_skyline(), _rect(), _footprints())
	var b: Array[SkylineLayout.Block] = SkylineLayout.place(_skyline(), _rect(), _footprints())
	check(a.size() > 150, "a dense city: %d blocks" % a.size())
	check_eq(a.size(), b.size(), "same count twice")
	for i: int in mini(a.size(), 40):
		check(a[i].position == b[i].position and a[i].building == b[i].building, "same block %d" % i)
	for block: SkylineLayout.Block in a:
		var p := Vector2(block.position.x, block.position.z)
		check(SkylineLayout.distance_to(p, _rect()) > 4.0, "%s block %s stays off the area" % [block.band, p])
		check(absf(p.x - _skyline().saila_x) > _skyline().saila_half, "block %s stays out of al-Saila" % p)


func test_layout_respects_band_distances_and_clearings() -> void:
	var blocks: Array[SkylineLayout.Block] = SkylineLayout.place(_skyline(), _rect(), _footprints())
	var counts: Dictionary[StringName, int] = {}
	for block: SkylineLayout.Block in blocks:
		counts[block.band] = counts.get(block.band, 0) + 1
		for mark: SkylineLandmark in _skyline().landmarks:
			var gap: float = Vector2(mark.x, mark.z).distance_to(Vector2(block.position.x, block.position.z))
			check(gap >= mark.clear_radius, "block is outside the clearing of %s" % mark.kind)
	for band: SkylineBand in _skyline().bands:
		check(counts.get(band.id, 0) > 10, "band %s has blocks" % band.id)
	for block: SkylineLayout.Block in blocks:
		if block.band == &"far":
			check(block.building == &"" and block.size.y > 1.0, "far blocks are plain boxes")
		else:
			check(block.building != &"", "detailed blocks name a building")


func test_tower_house_mesh_is_cached_with_facades_and_trim() -> void:
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var def := ContentDB.get_def("building", &"tower_b") as BuildingDef
	var mesh: ArrayMesh = TowerHouse.mesh(def, palette)
	check(mesh.get_surface_count() >= 3, "facades, trim and glow surfaces (antenna beacon): %d" % mesh.get_surface_count())
	check(mesh == TowerHouse.mesh(def, palette), "one cached mesh per building")
	check_eq(mesh.surface_get_material(0), SurfaceMaterials.facade(def, palette), "facade material is shared")
	var box: AABB = mesh.get_aabb()
	check(absf(box.size.y - def.total_height()) < 6.0, "about as tall as its floors (horns, antenna)")
	check(box.size.x >= def.footprint_w and box.size.z >= def.footprint_d, "covers the footprint")


func test_skyline_builds_within_the_draw_budget() -> void:
	var root: Node3D = SkylineBuilder.build(_area())
	var calls: int = 0
	var multis: int = 0
	for child: Node in root.get_children():
		var geometry := child as GeometryInstance3D
		check(geometry.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s casts no shadow" % child.name)
		var mesh: Mesh = (child as MeshInstance3D).mesh if child is MeshInstance3D else (child as MultiMeshInstance3D).multimesh.mesh
		if child is MultiMeshInstance3D:
			multis += 1
		calls += mesh.get_surface_count()
	root.free()
	check(multis >= 8, "batched blocks: %d multimeshes" % multis)
	check(calls <= 3 * DRAW_BUDGET, "surfaces %d within %d" % [calls, 3 * DRAW_BUDGET])


func test_landmarks_are_built_in_two_surfaces() -> void:
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var mesh: ArrayMesh = LandmarkBuilder.build(_skyline(), palette)
	check_eq(mesh.get_surface_count(), 2, "lit and glow surfaces")
	var box: AABB = mesh.get_aabb()
	check(box.size.y > 150.0, "the megacity towers reach high: %f" % box.size.y)
	check(box.size.x > 400.0, "landmarks are spread over the horizon: %f" % box.size.x)


func test_rooftop_builds_the_skyline() -> void:
	var rooftop: Node = (load("res://features/world/rooftop/rooftop.tscn") as PackedScene).instantiate()
	tree.root.add_child(rooftop)
	var found: bool = false
	for child: Node in rooftop.get_children():
		found = found or child.name == &"Skyline"
	rooftop.queue_free()
	check(found, "the rooftop scene has a Skyline node")
