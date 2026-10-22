extends TestCase
## The jambiyah smith's workbench: built from the prop 'workbench' (content/world/props/workbench.json), within the
## triangle and material budgets, carrying its lamp's light, with the prompt and footprint of the old box.

const MAX_TRIANGLES: int = 6000
const MAX_MATERIALS: int = 4
const DT: float = 1.0 / 60.0


func _def() -> PropDef:
	return ContentDB.get_def("prop", WorkshopSpot.PROP_ID) as PropDef


func _rules() -> ExploreRulesDef:
	return ContentDB.get_def("explore_rules", &"default") as ExploreRulesDef


func _spot() -> WorkshopSpot:
	var player := Player.new(_rules())
	var spot := WorkshopSpot.new(_rules(), player)
	spot.add_child(player)  # freed together with the spot
	tree.root.add_child(spot)
	return spot


## The prop mesh and the world materials are cached statics: drop them so the headless run leaks nothing.
func _clean() -> void:
	PropMesh.clear()
	SurfaceMaterials.clear()


func _bench_mesh(spot: WorkshopSpot) -> ArrayMesh:
	for child: Node in spot.get_children():
		if child is MeshInstance3D:
			return (child as MeshInstance3D).mesh as ArrayMesh
	return null


func _triangles(mesh: ArrayMesh) -> int:
	var total: int = 0
	for s: int in mesh.get_surface_count():
		total += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return total


## What PropMesh makes of one part: a box has 5 faces (no bottom), a prism 2 triangles a side plus 1 more for a cap.
func _expected(def: PropDef) -> int:
	var total: int = 0
	for part: PropPart in def.parts:
		if part.shape == &"frustum":
			total += part.sides * (3 if part.size.y > 0.0 else 2)
		else:
			total += 10
	return total


func test_the_bench_is_data_with_a_detailed_set_of_parts() -> void:
	var def: PropDef = _def()
	check(def != null, "the prop 'workbench' is in content")
	check(def.parts.size() >= 150, "a detailed bench: %d parts" % def.parts.size())
	var palette := ContentDB.get_def("palette", WorkshopSpot.PALETTE_ID) as PaletteDef
	for part: PropPart in def.parts:
		check(palette.colors.has(part.color), "palette letter '%s' exists" % part.color)


func test_the_mesh_is_built_from_the_parts_within_budget() -> void:
	var spot: WorkshopSpot = _spot()
	var mesh: ArrayMesh = _bench_mesh(spot)
	check(mesh != null, "the bench is a mesh")
	check_eq(_triangles(mesh), _expected(_def()), "every triangle comes from a data part")
	check(_triangles(mesh) <= MAX_TRIANGLES, "at most %d triangles (%d)" % [MAX_TRIANGLES, _triangles(mesh)])
	check(mesh.get_surface_count() <= MAX_MATERIALS, "at most %d draw materials (%d)" % [MAX_MATERIALS, mesh.get_surface_count()])
	for s: int in mesh.get_surface_count():
		check(mesh.surface_get_material(s) != null, "surface %d has a material" % s)
	spot.free()
	_clean()


func test_the_bench_stays_inside_its_footprint_and_under_the_prompt() -> void:
	var rules: ExploreRulesDef = _rules()
	var reach := Vector3(rules.bench_size.x / 2.0 + 0.4, rules.bench_size.y, rules.bench_size.z / 2.0 + 0.4)
	for part: PropPart in _def().parts:
		var top: float = part.at.y + (part.size.y if part.shape == &"frustum" else part.size.y / 2.0)
		check(absf(part.at.x) <= reach.x and absf(part.at.z) <= reach.z and top <= reach.y,
			"part at %s stays near the footprint and under the prompt" % part.at)


func test_the_brass_lamp_gives_one_warm_light_without_shadows() -> void:
	var def: PropDef = _def()
	check(def.light != null and def.light.color.r > def.light.color.b, "a warm lamp light in the data")
	var spot: WorkshopSpot = _spot()
	var lamps: Array[AreaLights] = []
	for child: Node in spot.get_children():
		if child is AreaLights:
			lamps.append(child as AreaLights)
	check_eq(lamps.size(), 1, "one light node")
	check_eq(lamps[0].slots.size(), 1, "with one real light")
	check(not lamps[0].slots[0].shadow_enabled, "that casts no shadow")
	spot.free()
	_clean()


func test_no_text_is_written_on_the_bench() -> void:
	var spot: WorkshopSpot = _spot()
	var labels: int = 0
	for child: Node in spot.get_children():
		labels += 1 if child is Label3D else 0
	check_eq(labels, 1, "only the interact prompt is a text")
	spot.free()
	_clean()


func test_the_prompt_floats_above_the_rack_and_still_works() -> void:
	var rules: ExploreRulesDef = _rules()
	var player := Player.new(rules)
	var spot := WorkshopSpot.new(rules, player)
	tree.root.add_child(spot)
	spot.position = Vector3(10.0, 0.0, 10.0)
	var opened: Array = []
	spot.opened.connect(func() -> void: opened.append(true))
	check(spot.prompt.position.y > 1.7, "the prompt is above the rack")
	spot._physics_process(DT)
	check(not spot.prompt.visible, "no prompt far away")
	player.position = spot.position + Vector3(0.5, 0.0, 0.0)
	spot._physics_process(DT)
	check(spot.prompt.visible, "the prompt shows near the bench")
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	spot._unhandled_input(press)
	check_eq(opened.size(), 1, "interact near the bench opens the workshop")
	spot.free()
	player.free()
	_clean()
