extends TestCase
## Rooftop dressing as data: props and building placements are valid and stand on solid cells, prop parts use
## palette letters, the light maths (nearest few, fades, flicker), the real-light budget and the fake pools,
## the canyon and the nested DefReader reads.


func _area() -> AreaDef:
	return ContentDB.get_def("area", &"souq_rooftops") as AreaDef


func _solid(area: AreaDef, x: int, z: int) -> bool:
	var tile := ContentDB.get_def("tile", area.tile_id_at(x, z)) as TileDef
	return tile != null and tile.solid


func test_every_placement_references_real_content() -> void:
	var area: AreaDef = _area()
	check(area.props.size() >= 30 and area.buildings.size() >= 3, "the roof is dressed: %d props" % area.props.size())
	for p: Placement in area.props:
		check(ContentDB.get_def("prop", p.ref) != null, "prop '%s' exists" % p.ref)
	for b: Placement in area.buildings:
		check(ContentDB.get_def("building", b.ref) != null, "building '%s' exists" % b.ref)


func test_buildings_stand_on_solid_cells() -> void:
	var area: AreaDef = _area()
	for b: Placement in area.buildings:
		var def := ContentDB.get_def("building", b.ref) as BuildingDef
		var x0: int = roundi(b.pos.x - def.footprint_w / 2.0)
		var z0: int = roundi(b.pos.z - def.footprint_d / 2.0)
		for z: int in def.footprint_d:
			for x: int in def.footprint_w:
				check(_solid(area, x0 + x, z0 + z), "%s cell (%d, %d) is solid" % [b.ref, x0 + x, z0 + z])


func test_the_mafraj_stands_behind_the_workshop_bench() -> void:
	var area: AreaDef = _area()
	var mafraj: Placement = null
	for p: Placement in area.props:
		if p.ref == &"mafraj":
			mafraj = p
	check(mafraj != null, "a mafraj stands on the roof")
	var bench: Vector2i = area.find_marker(AreaDef.WORKSHOP)
	check(absf(mafraj.pos.x - (bench.x + 0.5)) < 2.0 and bench.y + 0.5 - mafraj.pos.z < 6.0, "the bench is at its doorway")
	var def := ContentDB.get_def("prop", &"mafraj") as PropDef
	check(def.light != null and def.light.pool_radius > 0.0, "the doorway carries a warm light and a floor pool")


func test_prop_parts_use_palette_letters() -> void:
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	for id: StringName in ContentDB.ids("prop"):
		var def := ContentDB.get_def("prop", id) as PropDef
		check(not def.parts.is_empty(), "prop %s has parts" % id)
		for part: PropPart in def.parts:
			check(palette.colors.has(part.color), "prop %s part colour '%s' is a palette letter" % [id, part.color])


func test_prop_mesh_surfaces() -> void:
	var palette := ContentDB.get_def("palette", &"main") as PaletteDef
	var antenna := ContentDB.get_def("prop", &"antenna_red") as PropDef
	var mesh: ArrayMesh = PropMesh.mesh(antenna, palette)
	check_eq(mesh.get_surface_count(), 2, "antenna: lit trim and a blinking beacon")
	check(mesh.surface_get_material(1) is ShaderMaterial, "the beacon uses the blink shader")
	check(PropMesh.mesh(antenna, palette) == mesh, "meshes are cached per prop")
	var chest := ContentDB.get_def("prop", &"chest") as PropDef
	check(chest.chest and chest.has_group(&"lid"), "the chest has a lid group")
	check(PropMesh.mesh(chest, palette, &"lid").get_surface_count() >= 1, "the lid has its own mesh")


func test_nearest_lights_and_fades() -> void:
	var at: Array[Vector3] = [Vector3(10, 0, 0), Vector3(1, 0, 0), Vector3(5, 0, 0), Vector3(2, 0, 0)]
	var real: Array[bool] = [true, true, true, false]
	check_eq(LightPick.nearest(at, real, Vector3.ZERO, 2), [1, 2], "the two nearest real lights, nearest first")
	check_eq(LightPick.nearest(at, real, Vector3.ZERO, 9).size(), 3, "fewer lights than the budget: all real ones")
	check(is_equal_approx(LightPick.fade(0.5, true, 0.1, 2.0), 0.7), "fades in")
	check(is_equal_approx(LightPick.fade(0.1, false, 1.0, 2.0), 0.0), "fades out and stops at 0")
	check(is_equal_approx(LightPick.flicker(0.0, 5.0, 1.0, 3.0), 1.0), "no flicker: full strength")
	for i: int in 50:
		var f: float = LightPick.flicker(0.4, 6.0, 0.3, i * 0.13)
		check(f >= 0.6 - 0.001 and f <= 1.0 + 0.001, "flicker stays inside 1 - amount .. 1")


func test_real_lights_stay_within_the_budget() -> void:
	var area: AreaDef = _area()
	var player := Node3D.new()
	var specs: Array[LightSpec] = area.lights.duplicate()
	specs.append_array(PropBuilder.light_specs(area, 0.5))
	check(specs.size() > 12, "many practical lights exist (%d)" % specs.size())
	var lights := AreaLights.new(specs, player, area.light_budget, area.light_fade)
	tree.root.add_child(player)
	tree.root.add_child(lights)
	check(lights.slots.size() <= 8, "at most 8 real lights: %d" % lights.slots.size())
	player.position = Vector3(3.0, 0.5, 14.0)
	for i: int in 60:
		lights._process(0.05)
	var alive: int = 0
	var shadows: int = 0
	for slot: OmniLight3D in lights.slots:
		alive += 1 if slot.light_energy > 0.01 else 0
		shadows += 1 if slot.shadow_enabled else 0
	check(alive >= 4 and alive <= 8, "lights near the player are on: %d" % alive)
	check_eq(shadows, 0, "no practical light casts a shadow")
	var near: Vector3 = lights.slots[0].position
	check(near.distance_to(player.position) < 25.0, "slots follow the nearest lights")
	player.position = Vector3(23.0, 0.5, 8.0)
	for i: int in 120:
		lights._process(0.05)
	var moved: bool = false
	for i: int in lights.slots.size():
		moved = moved or lights.slots[i].position.x > 15.0
	check(moved, "when the player walks east the lights hand over to the east ones")
	player.free()
	lights.free()


func test_canyon_and_mist_rects() -> void:
	var area: AreaDef = _area()
	check(area.canyon != null and area.canyon.bottom_y < -10.0, "al-Saila is a deep sunken street")
	var canyon: Node3D = CanyonBuilder.build(area.canyon)
	check(canyon.get_child_count() >= 10, "walls and a channel: %d" % canyon.get_child_count())
	canyon.free()
	var fog := ContentDB.get_def("mist", &"saila_fog") as MistDef
	check(fog.rect.has_area() and fog.stack > 1 and fog.height < -5.0, "the street fog is stacked sheets inside the canyon")
	var layers: Array[MeshInstance3D] = MistBuilder.build_stack(fog, Vector2(26.0, 18.0))
	check_eq(layers.size(), fog.stack, "one plane per sheet")
	check(is_equal_approx(layers[1].position.y - layers[0].position.y, fog.step), "sheets step upward")
	check(absf(layers[0].position.x - fog.rect.get_center().x) < 0.01, "the fog sits over its rect, not the area")
	for layer: MeshInstance3D in layers:
		layer.free()
	var wisps := ContentDB.get_def("mist", &"wisps") as MistDef
	check(wisps.hole.has_area(), "the edge wisps keep a hole over the walkable roof")


func test_def_reader_nested_and_lists() -> void:
	var errors := PackedStringArray()
	var r := DefReader.new({"a": {"b": 1}, "list": [1, 2.5, "x"], "n": 3}, "t", errors)
	check_eq(r.child("a").integer("b", 0, 5), 1, "a nested object reads")
	check_eq(r.float_list("list", 0.0, 9.0).size(), 2, "numbers read, the text is a problem")
	check_eq(errors.size(), 1, "one problem for the bad list entry")
	r.child("n")
	check_eq(errors.size(), 2, "a non-object child is a problem")
	check(r.optional_objects("nothing").is_empty() and not r.has("nothing"), "absent lists are empty")
