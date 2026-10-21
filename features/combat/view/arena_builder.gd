class_name ArenaBuilder
extends RefCounted
## Builds a battle arena from its ArenaDef: a painted roof slab whose top is at the arena origin, a parapet round
## three sides (the fourth is the camera's), the dressing (props, lanterns, the city behind) and the look's key
## light, placed far from the exploring area (content/combat/arenas.json). The arena's own Environment is handed to
## the battle camera, so the area's WorldEnvironment never shows in a fight. Materials are the world's painted ones.

const PALETTE_ID: StringName = &"main"


static func build(def: ArenaDef) -> Node3D:
	var root := Node3D.new()
	root.name = "Arena"
	root.position = def.origin
	var look: LookDef = look_of(def)
	if look != null:
		if PaintedMaterials.paint != look.paint:
			PaintedLook.begin(look)  # an arena run alone (a render) paints like the area does
		root.add_child(Diorama.make_sun(look))
	var palette := ContentDB.get_def("palette", PALETTE_ID) as PaletteDef
	root.add_child(_slab(def, palette))
	_parapet(root, def, palette)
	ArenaDressing.add_to(root, def, palette)
	return root


## The Environment of the arena's look (null when the look is missing).
static func environment(def: ArenaDef) -> Environment:
	var look: LookDef = look_of(def)
	if look == null:
		return null
	var world: WorldEnvironment = Diorama.make_environment(look)
	var env: Environment = world.environment
	world.free()
	return env


## The floor point the fighters are placed around: the middle of the slab's top face.
static func anchor(def: ArenaDef) -> Vector3:
	return def.origin


static func look_of(def: ArenaDef) -> LookDef:
	return ContentDB.get_def("look", def.look) as LookDef


static func _slab(def: ArenaDef, palette: PaletteDef) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = def.floor_size
	box.material = _material(ContentDB.get_def("tile", def.floor_tile) as TileDef, palette, def.floor_color)
	var slab := MeshInstance3D.new()
	slab.name = "Roof"
	slab.mesh = box
	slab.position.y = -def.floor_size.y / 2.0
	return slab


## Parapet along the back and both ends, standing in from the edge.
static func _parapet(root: Node3D, def: ArenaDef, palette: PaletteDef) -> void:
	var tile := ContentDB.get_def("tile", def.parapet_tile) as TileDef
	if tile == null:
		return
	var material: Material = _material(tile, palette, def.floor_color)
	var half_x: float = def.floor_size.x / 2.0 - def.parapet_inset - def.parapet_thickness / 2.0
	var half_z: float = def.floor_size.z / 2.0 - def.parapet_inset - def.parapet_thickness / 2.0
	var run_x: float = def.floor_size.x - def.parapet_inset * 2.0
	var run_z: float = def.floor_size.z - def.parapet_inset * 2.0
	var y: float = tile.height / 2.0
	_wall(root, "ParapetBack", material, Vector3(run_x, tile.height, def.parapet_thickness), Vector3(0.0, y, -half_z))
	_wall(root, "ParapetLeft", material, Vector3(def.parapet_thickness, tile.height, run_z), Vector3(-half_x, y, 0.0))
	_wall(root, "ParapetRight", material, Vector3(def.parapet_thickness, tile.height, run_z), Vector3(half_x, y, 0.0))


static func _wall(root: Node3D, wall_name: String, material: Material, size: Vector3, at: Vector3) -> void:
	var box := BoxMesh.new()
	box.size = size
	box.material = material
	var wall := MeshInstance3D.new()
	wall.name = wall_name
	wall.mesh = box
	wall.position = at
	root.add_child(wall)


## A tile's painted pattern (world-space, so the arena's far origin changes nothing), else its flat colour.
static func _material(tile: TileDef, palette: PaletteDef, fallback: Color) -> Material:
	if tile == null:
		return Diorama.material(fallback)
	if tile.pattern != &"":
		return SurfaceMaterials.tile(tile.pattern, palette, tile.tint)
	return Diorama.material(tile.to_color(palette))
