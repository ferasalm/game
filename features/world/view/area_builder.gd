class_name AreaBuilder
extends RefCounted
## Builds an area's blocks: one MultiMeshInstance3D per tile type (bodies, and caps drawn with the cap tile's
## material; tiles with a pattern get its painted triplanar texture), plus one StaticBody3D holding a box per run of solid tiles and walls that close the area's edges.
## Tile (x, z) is the unit square [x, x+1] by [z, z+1]; the walkable floor is a visual only (the player floats).

const PALETTE_ID: StringName = &"main"
const EDGE_THICKNESS: float = 1.0


static func build(area: AreaDef, rules: ExploreRulesDef) -> Node3D:
	var root := Node3D.new()
	var palette := ContentDB.get_def("palette", PALETTE_ID) as PaletteDef
	var groups: Dictionary[StringName, Array] = _groups(area)
	for tile_id: StringName in groups:
		var tile := ContentDB.get_def("tile", tile_id) as TileDef
		root.add_child(_multimesh(tile, palette, groups[tile_id]))
	root.add_child(_collision(area, rules))
	return root


## World position of a tile's centre on the walkable floor (y = 0; callers add the floor height).
static func cell_center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x + 0.5, 0.0, cell.y + 0.5)


static func _groups(area: AreaDef) -> Dictionary[StringName, Array]:
	var out: Dictionary[StringName, Array] = {}
	for z: int in area.depth():
		for x: int in area.width():
			var tile := ContentDB.get_def("tile", area.tile_id_at(x, z)) as TileDef
			if tile == null or tile.hidden:
				continue
			var top: float = tile.height
			var thickness: float = 0.5
			if tile.solid:
				thickness = tile.height if tile.height > 0.0 and tile.height <= 1.2 else 1.2
			var y0: float = top - thickness
			_add(out, tile.id, _box(x, z, y0, thickness))
			var cap := ContentDB.get_def("tile", tile.cap) as TileDef
			if cap != null:
				_add(out, cap.id, _box(x, z, top, cap.height))
	return out


static func _add(out: Dictionary[StringName, Array], tile_id: StringName, xform: Transform3D) -> void:
	if not out.has(tile_id):
		out[tile_id] = []
	out[tile_id].append(xform)


static func _box(x: int, z: int, y0: float, height: float) -> Transform3D:
	return Transform3D(Basis.from_scale(Vector3(1.0, height, 1.0)), Vector3(x + 0.5, y0 + height / 2.0, z + 0.5))


static func _multimesh(tile: TileDef, palette: PaletteDef, transforms: Array) -> MultiMeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	if tile.pattern != &"":
		mesh.material = SurfaceMaterials.tile(tile.pattern, palette, tile.tint)
	else:
		mesh.material = Diorama.material(tile.to_color(palette), tile.glow)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i: int in transforms.size():
		multi.set_instance_transform(i, transforms[i] as Transform3D)
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	node.set_meta(OcclusionFade.META, transforms)
	return node


static func _collision(area: AreaDef, rules: ExploreRulesDef) -> StaticBody3D:
	var body := StaticBody3D.new()
	var h: float = rules.wall_height
	for z: int in area.depth():
		var x: int = 0
		while x < area.width():
			if not _solid(area, x, z):
				x += 1
				continue
			var start: int = x
			while x < area.width() and _solid(area, x, z):
				x += 1
			var tile := ContentDB.get_def("tile", area.tile_id_at(start, z)) as TileDef
			var base_y: float = (tile.height - 1.2) if (tile != null and tile.solid and tile.height < 0.0) else 0.0
			_shape(body, Vector3(x - start, h, 1.0), Vector3((start + x) / 2.0, base_y + h / 2.0, z + 0.5))
	var w: float = area.width()
	var d: float = area.depth()
	var t: float = EDGE_THICKNESS
	_shape(body, Vector3(w + 2.0 * t, h, t), Vector3(w / 2.0, h / 2.0, -t / 2.0))
	_shape(body, Vector3(w + 2.0 * t, h, t), Vector3(w / 2.0, h / 2.0, d + t / 2.0))
	_shape(body, Vector3(t, h, d), Vector3(-t / 2.0, h / 2.0, d / 2.0))
	_shape(body, Vector3(t, h, d), Vector3(w + t / 2.0, h / 2.0, d / 2.0))
	return body


static func _solid(area: AreaDef, x: int, z: int) -> bool:
	var tile := ContentDB.get_def("tile", area.tile_id_at(x, z)) as TileDef
	return tile != null and tile.solid


static func _shape(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = size
	var node := CollisionShape3D.new()
	node.shape = box
	node.position = pos
	body.add_child(node)
