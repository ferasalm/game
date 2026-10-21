class_name ArenaBuilder
extends RefCounted
## Builds a battle arena from its ArenaDef: a floor slab whose top is at the arena origin and the look's key light,
## placed far from the exploring area (content/combat/arenas.json). The arena's own Environment is handed to the
## battle camera, so the area's WorldEnvironment never shows in a fight.


static func build(def: ArenaDef) -> Node3D:
	var root := Node3D.new()
	root.name = "Arena"
	root.position = def.origin
	var slab := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = def.floor_size
	var material := StandardMaterial3D.new()
	material.albedo_color = def.floor_color
	box.material = material
	slab.mesh = box
	slab.position.y = -def.floor_size.y / 2.0
	root.add_child(slab)
	var look: LookDef = _look(def)
	if look != null:
		root.add_child(Diorama.make_sun(look))
	return root


## The Environment of the arena's look (null when the look is missing).
static func environment(def: ArenaDef) -> Environment:
	var look: LookDef = _look(def)
	if look == null:
		return null
	var world: WorldEnvironment = Diorama.make_environment(look)
	var env: Environment = world.environment
	world.free()
	return env


## The floor point the fighters are placed around: the middle of the slab's top face.
static func anchor(def: ArenaDef) -> Vector3:
	return def.origin


static func _look(def: ArenaDef) -> LookDef:
	return ContentDB.get_def("look", def.look) as LookDef
