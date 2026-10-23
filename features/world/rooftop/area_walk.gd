class_name AreaWalk
extends RefCounted
## The walk graph of an area built from content: a cell can be stood on when its tile is not solid and no prop's
## collide box (turned by its yaw, grown by the capsule radius) covers the cell centre at the height Zayd stands.
## Tests and the rooftop's safe-spot code use it (the pure rules are in WalkGraph).


static func build(area: AreaDef, rules: ExploreRulesDef) -> WalkGraph:
	var open := PackedByteArray()
	var heights := PackedFloat32Array()
	open.resize(area.width() * area.depth())
	heights.resize(area.width() * area.depth())
	var floor_y: float = floor_height(area)
	var boxes: Array[Dictionary] = _prop_boxes(area, rules, floor_y)
	for z: int in area.depth():
		for x: int in area.width():
			var tile := ContentDB.get_def("tile", area.tile_id_at(x, z)) as TileDef
			var index: int = z * area.width() + x
			heights[index] = tile.height if tile != null else 0.0
			var free: bool = tile != null and not tile.solid and not _blocked(boxes, Vector2(x + 0.5, z + 0.5))
			open[index] = 1 if free else 0
	return WalkGraph.new(area.width(), area.depth(), open, heights)


## The floor height at the spawn marker (where Zayd stands).
static func floor_height(area: AreaDef) -> float:
	var spawn: Vector2i = area.find_marker(AreaDef.SPAWN)
	var tile := ContentDB.get_def("tile", area.tile_id_at(spawn.x, spawn.y)) as TileDef
	return tile.height if tile != null else 0.0


## True when a floor point lies inside a prop's collide box grown by the capsule radius (a body there would overlap it).
static func on_prop(area: AreaDef, rules: ExploreRulesDef, point: Vector3) -> bool:
	return _blocked(_prop_boxes(area, rules, floor_height(area)), Vector2(point.x, point.z))


## Floor-plane cell centres of the cells in `cells`, as points at floor_y.
static func centers(cells: Dictionary[Vector2i, bool], floor_y: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for cell: Vector2i in cells:
		out.append(AreaBuilder.cell_center(cell) + Vector3(0.0, floor_y, 0.0))
	return out


## The floor cell a floor point stands in.
static func cell_of(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x), floori(p.z))


## Boxes that block walking: {"at": Vector2 centre, "yaw": radians, "half": Vector2 half size grown by the radius}.
static func _prop_boxes(area: AreaDef, rules: ExploreRulesDef, floor_y: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Placement in area.props:
		var def := ContentDB.get_def("prop", p.ref) as PropDef
		if def == null or def.collide == Vector3.ZERO:
			continue
		var bottom: float = p.pos.y if p.has_y else floor_y
		if bottom >= floor_y + rules.capsule_height or bottom + def.collide.y <= floor_y:
			continue
		out.append({"at": Vector2(p.pos.x, p.pos.z), "yaw": deg_to_rad(p.yaw),
			"half": Vector2(def.collide.x, def.collide.z) / 2.0 + Vector2.ONE * rules.capsule_radius})
	return out


static func _blocked(boxes: Array[Dictionary], point: Vector2) -> bool:
	for box: Dictionary in boxes:
		var local: Vector2 = (point - (box["at"] as Vector2)).rotated(box["yaw"] as float)
		var half: Vector2 = box["half"] as Vector2
		if absf(local.x) < half.x and absf(local.y) < half.y:
			return true
	return false
