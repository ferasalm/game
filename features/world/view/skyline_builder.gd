class_name SkylineBuilder
extends RefCounted
## Builds the old city of Sana'a around a play area from the "skyline" content: tower-houses in depth bands
## (one MultiMeshInstance3D per building type, shared meshes and materials), far unshaded silhouettes (one
## MultiMesh), the landmarks (one mesh), the street-level ground and the al-Saila street. No node casts shadows.
## Public: build(area) -> Node3D. About 35 draw calls in all.

const SKYLINE_ID: StringName = &"old_city"
const GROUND_SIZE: float = 1400.0
const PALETTE_ID: StringName = &"main"


static func build(area: AreaDef, skyline_id: StringName = SKYLINE_ID) -> Node3D:
	var root := Node3D.new()
	root.name = "Skyline"
	var def := ContentDB.get_def("skyline", skyline_id) as SkylineDef
	var palette := ContentDB.get_def("palette", PALETTE_ID) as PaletteDef
	if def == null or palette == null:
		push_error("SkylineBuilder: missing skyline '%s' or palette" % skyline_id)
		return root
	var rect := Rect2(0.0, 0.0, area.width(), area.depth())
	var footprints: Dictionary[StringName, Vector2] = {}
	for building_id: StringName in ContentDB.ids("building"):
		var b := ContentDB.get_def("building", building_id) as BuildingDef
		footprints[building_id] = Vector2(b.footprint_w, b.footprint_d)
	var blocks: Array[SkylineLayout.Block] = SkylineLayout.place(def, rect, footprints)
	_houses(root, def, palette, blocks)
	_far(root, def, palette, blocks)
	_add(root, _mesh_node(LandmarkBuilder.build(def, palette)))
	_ground(root, def, palette, rect)
	return root


static func _houses(root: Node3D, def: SkylineDef, palette: PaletteDef, blocks: Array[SkylineLayout.Block]) -> void:
	var groups: Dictionary[String, Array] = {}
	for block: SkylineLayout.Block in blocks:
		if block.building != &"":
			var key: String = "%s|%d|%d" % [block.building, floori(block.position.x / def.chunk_m), floori(block.position.z / def.chunk_m)]
			if not groups.has(key):
				groups[key] = []
			groups[key].append(block)
	for key: String in groups:
		var list: Array = groups[key]
		var building := ContentDB.get_def("building", StringName(key.split("|")[0])) as BuildingDef
		var multi := _multi(TowerHouse.mesh(building, palette), list.size())
		var placed: Array[Transform3D] = []
		for i: int in list.size():
			var block := list[i] as SkylineLayout.Block
			var at := Vector3(block.position.x, def.ground_y, block.position.z)
			placed.append(Transform3D(Basis(Vector3.UP, block.yaw), at))
			multi.set_instance_transform(i, placed[i])
			var shade: float = 0.85 + 0.2 * float(hash(Vector2(block.position.x, block.position.z)) % 100) / 100.0
			multi.set_instance_color(i, Color(shade, shade, shade))
		var node: MultiMeshInstance3D = _multi_node(multi)
		node.set_meta(OcclusionFade.META, placed)
		_add(root, node)


static func _far(root: Node3D, def: SkylineDef, palette: PaletteDef, blocks: Array[SkylineLayout.Block]) -> void:
	var groups: Dictionary[String, Array] = {}
	for block: SkylineLayout.Block in blocks:
		if block.building == &"":
			var key: String = "%d|%d" % [floori(block.position.x / def.chunk_m), floori(block.position.z / def.chunk_m)]
			if not groups.has(key):
				groups[key] = []
			groups[key].append(block)
	var mesh := BoxMesh.new()
	mesh.material = SurfaceMaterials.far(palette, def.far_texture_m)
	for key: String in groups:
		var list: Array = groups[key]
		var multi := _multi(mesh, list.size())
		for i: int in list.size():
			var block := list[i] as SkylineLayout.Block
			var at := Vector3(block.position.x, def.ground_y + block.size.y / 2.0, block.position.z)
			multi.set_instance_transform(i, Transform3D(Basis.from_scale(block.size), at))
			multi.set_instance_color(i, Color(block.tint, block.tint, block.tint))
		_add(root, _multi_node(multi))


## The ground at street level and the al-Saila street (paved) running through the whole city along z.
static func _ground(root: Node3D, def: SkylineDef, palette: PaletteDef, rect: Rect2) -> void:
	var centre: Vector2 = rect.get_center()
	var ground := PlaneMesh.new()
	ground.size = Vector2(GROUND_SIZE, GROUND_SIZE)
	ground.material = _floor_material(palette.colors["n"])
	var ground_node := _mesh_node(ground)
	ground_node.position = Vector3(centre.x, def.ground_y - 0.05, centre.y)
	_add(root, ground_node)
	var street := PlaneMesh.new()
	street.size = Vector2(def.saila_half * 1.6, GROUND_SIZE)
	street.material = SurfaceMaterials.tile(&"paving", palette)
	var street_node := _mesh_node(street)
	street_node.position = Vector3(def.saila_x, def.ground_y, centre.y)
	_add(root, street_node)


static func _floor_material(color: Color) -> Material:
	if PaintedMaterials.paint != null:
		return PaintedMaterials.flat(color)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	return mat


static func _multi(mesh: Mesh, count: int) -> MultiMesh:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = count
	return multi


static func _multi_node(multi: MultiMesh) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	return node


static func _mesh_node(mesh: Mesh) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	return node


static func _add(root: Node3D, node: GeometryInstance3D) -> void:
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)
