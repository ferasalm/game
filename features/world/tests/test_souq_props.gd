extends TestCase
## purpose: Tests for souq props: the wall niche sabil and herb stall recipes and budgets.

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


func test_qamariya_base_equals_lintel_top_and_basin_not_orange() -> void:
	var def: PropDef = _prop(&"sabil")
	var lintel: PropPart = null
	var ring: PropPart = null
	for part: PropPart in def.parts:
		if part.pattern == &"gypsum" and part.size.x >= 1.4:
			lintel = part
		if part.shape == &"frustum" and part.sides == 16 and part.at.y >= 2.0:
			ring = part
		if part.shape == &"frustum" and part.at.y <= 0.6 and not part.water and part.size.z >= 0.1:
			check(part.color != "O", "basin part at y=%.2f is not orange" % part.at.y)
			check(part.color == "g", "basin part at y=%.2f is pale limestone" % part.at.y)
	check(lintel != null, "lintel found")
	check(ring != null, "qamariya ring found")
	if lintel != null and ring != null:
		var lintel_top: float = lintel.at.y + lintel.size.y / 2.0
		check(absf(ring.at.y - lintel_top) <= 0.01, "qamariya base %.3f equals lintel top %.3f" % [ring.at.y, lintel_top])


func test_sabil_budget() -> void:
	var def: PropDef = _prop(&"sabil")
	var mesh: ArrayMesh = PropMesh.mesh(def, _palette())
	var tris: int = _triangles(mesh)
	check(tris <= MAX_TRIANGLES, "sabil has %d tris <= %d" % [tris, MAX_TRIANGLES])
	check(mesh.get_surface_count() <= MAX_MATERIALS, "sabil has %d mats <= %d" % [mesh.get_surface_count(), MAX_MATERIALS])
	PropMesh.clear()


func test_herb_bundles_have_seven_blades_and_no_frustum() -> void:
	var def: PropDef = _prop(&"herb_stall")
	var bundles: Dictionary = {}
	for part: PropPart in def.parts:
		if part.at.y >= 1.5 and part.at.z >= 0.45:
			check(part.shape != &"frustum", "no frustum in hanging bundle at %s" % part.at)
			if part.shape == &"box" and absf(part.size.y - 0.32) <= 0.01:
				var key: float = roundf(part.at.x * 100.0)
				bundles[key] = bundles.get(key, 0) + 1
	check(bundles.size() >= 8, ">= 8 hanging bundles found (%d)" % bundles.size())
	for key: float in bundles:
		check(bundles[key] >= 7, "bundle at x=%.2f has >= 7 blades (%d)" % [key / 100.0, bundles[key]])


func test_basket_heaps_have_twelve_leaves() -> void:
	var def: PropDef = _prop(&"herb_stall")
	var centers: Array[float] = [-0.35, 0.08, 0.52]
	var leaf_counts: Array[int] = [0, 0, 0]
	for part: PropPart in def.parts:
		if part.shape == &"box" and absf(part.size.y - 0.012) <= 0.005 and part.at.y >= 1.05 and part.at.y <= 1.2:
			for i: int in 3:
				if absf(part.at.x - centers[i]) <= 0.18 and absf(part.at.z - 0.15) <= 0.18:
					leaf_counts[i] += 1
					break
	for i: int in 3:
		check(leaf_counts[i] >= 12, "basket %d has >= 12 leaves (%d)" % [i + 1, leaf_counts[i]])


func test_awning_stripes_alternate_colours() -> void:
	var def: PropDef = _prop(&"herb_stall")
	var stripes: Array[PropPart] = []
	for part: PropPart in def.parts:
		if part.shape == &"box" and absf(part.size.z - 1.1) <= 0.05 and absf(part.at.y - 2.20) <= 0.1:
			stripes.append(part)
	check_eq(stripes.size(), 8, "8 awning stripes")
	stripes.sort_custom(func(a: PropPart, b: PropPart) -> bool: return a.at.x < b.at.x)
	for i: int in range(1, stripes.size()):
		check(stripes[i].color != stripes[i - 1].color, "stripe %d alternates color from %d" % [i, i - 1])
		check((stripes[i].color == "u" and stripes[i - 1].color == "w") or (stripes[i].color == "w" and stripes[i - 1].color == "u"), "stripes alternate teal and cream")


func test_herb_stall_rebuilt_without_old_cones_and_bottles() -> void:
	var def: PropDef = _prop(&"herb_stall")
	check(def != null, "herb_stall prop exists")
	check_eq(def.collide, Vector3(2.2, 1.2, 1.0), "keeps counter collide size")
	for part: PropPart in def.parts:
		var is_old_bottle: bool = part.at.y > 1.5 and part.at.z < -0.2 and part.size.x >= 0.15
		check(not is_old_bottle, "no old shelf bottle at %s" % part.at)
		var is_old_cone: bool = part.shape == &"frustum" and part.at.y > 1.4 and part.size.z >= 0.35
		check(not is_old_cone, "no old crystal cone at %s" % part.at)


func test_herb_stall_budget() -> void:
	var def: PropDef = _prop(&"herb_stall")
	var mesh: ArrayMesh = PropMesh.mesh(def, _palette())
	var tris: int = _triangles(mesh)
	check(tris <= MAX_TRIANGLES, "herb_stall has %d tris <= %d" % [tris, MAX_TRIANGLES])
	check(mesh.get_surface_count() <= MAX_MATERIALS, "herb_stall has %d mats <= %d" % [mesh.get_surface_count(), MAX_MATERIALS])
	PropMesh.clear()
