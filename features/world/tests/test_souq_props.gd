extends TestCase
## Tests for souq props: the wall niche sabil with 7-colour qamariya and the herb stall within budgets.

const MAX_TRIANGLES: int = 3000
const MAX_MATERIALS: int = 6


func _prop(id: StringName) -> PropDef:
	return ContentDB.get_def("prop", id) as PropDef


func _palette() -> PaletteDef:
	return ContentDB.get_def("palette", &"main") as PaletteDef


func _triangles(mesh: ArrayMesh) -> int:
	var total: int = 0
	for s: int in mesh.get_surface_count():
		total += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return total


func test_sabil_has_wall_slab_frame_and_water() -> void:
	var def: PropDef = _prop(&"sabil")
	check(def != null, "sabil prop exists")
	check(def.collide.z <= 0.9 and def.collide.x >= 1.5, "collide depth <= 0.9 m")
	check(def.splash != null and def.splash.count > 0, "has falling stream splash")
	check(def.light != null and def.light.pos.z >= 0.5, "warm light in front of basin")
	var slab: PropPart = null
	var water_parts: int = 0
	for part: PropPart in def.parts:
		if part.pattern == &"plaster_worn" and part.size.x >= 2.0:
			slab = part
		if part.water:
			water_parts += 1
	check(slab != null, "has plaster_worn wall slab behind basin")
	if slab != null:
		check(absf(slab.at.z + slab.size.z / 2.0) <= 0.01, "slab front at z=0")
	check(water_parts >= 2, "has falling stream and basin water")


func test_sabil_has_glowing_qamariya_with_7_colours_above_2m() -> void:
	var def: PropDef = _prop(&"sabil")
	var ring: PropPart = null
	var glow_colors: Dictionary = {}
	for part: PropPart in def.parts:
		if part.shape == &"frustum" and part.sides == 16 and part.at.y >= 2.0:
			ring = part
		if part.glow and part.at.y >= 2.0:
			glow_colors[part.color] = true
	check(ring != null, "outer gypsum ring frustum with 16 sides")
	for hue: String in ["R", "O", "Y", "G", "C", "B", "V"]:
		check(glow_colors.has(hue), "qamariya pane in %s" % hue)


func test_sabil_budget() -> void:
	var def: PropDef = _prop(&"sabil")
	var mesh: ArrayMesh = PropMesh.mesh(def, _palette())
	var tris: int = _triangles(mesh)
	check(tris <= MAX_TRIANGLES, "sabil has %d tris <= %d" % [tris, MAX_TRIANGLES])
	check(mesh.get_surface_count() <= MAX_MATERIALS, "sabil has %d mats <= %d" % [mesh.get_surface_count(), MAX_MATERIALS])
	PropMesh.clear()


func test_herb_stall_rebuilt_without_old_cones_and_bottles() -> void:
	var def: PropDef = _prop(&"herb_stall")
	check(def != null, "herb_stall prop exists")
	check_eq(def.collide, Vector3(2.2, 1.2, 1.0), "keeps counter collide size")
	for part: PropPart in def.parts:
		var is_old_bottle: bool = part.at.y > 1.5 and part.at.z < -0.2 and part.size.x >= 0.15
		check(not is_old_bottle, "no old shelf bottle at %s" % part.at)
		var is_old_cone: bool = part.shape == &"frustum" and part.at.y > 1.4 and part.size.z >= 0.35
		check(not is_old_cone, "no old crystal cone at %s" % part.at)


func test_herb_stall_herbs_baskets_and_lantern() -> void:
	var def: PropDef = _prop(&"herb_stall")
	check(def.light != null and def.light.pos.x < -0.5, "lantern at keeper's (-x) end")
	check_eq(def.light.energy, 0.85, "lantern energy 0.85")
	var hanging_blades: int = 0
	var hanging_frustums: int = 0
	var baskets: int = 0
	var pink_plumes: int = 0
	for part: PropPart in def.parts:
		if part.at.y >= 1.5 and part.at.z >= 0.45:
			if part.shape == &"box" and absf(part.size.y - 0.32) <= 0.01:
				hanging_blades += 1
			elif part.shape == &"frustum":
				hanging_frustums += 1
		if part.shape == &"frustum" and absf(part.at.y - 0.96) <= 0.05 and part.color == "q":
			baskets += 1
		if part.color == "M":
			pink_plumes += 1
	check(hanging_blades >= 56, ">= 56 hanging herb blades (%d)" % hanging_blades)
	check_eq(hanging_frustums, 0, "no frustums in hanging bundles")
	check(baskets >= 3, ">= 3 woven baskets on counter (%d)" % baskets)
	check(pink_plumes >= 3, "pink-magenta feather plumes present (%d)" % pink_plumes)


func test_herb_stall_budget() -> void:
	var def: PropDef = _prop(&"herb_stall")
	var mesh: ArrayMesh = PropMesh.mesh(def, _palette())
	var tris: int = _triangles(mesh)
	check(tris <= MAX_TRIANGLES, "herb_stall has %d tris <= %d" % [tris, MAX_TRIANGLES])
	check(mesh.get_surface_count() <= MAX_MATERIALS, "herb_stall has %d mats <= %d" % [mesh.get_surface_count(), MAX_MATERIALS])
	PropMesh.clear()
