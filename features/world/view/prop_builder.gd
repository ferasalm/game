class_name PropBuilder
extends RefCounted
## Places an area's props and tower-houses from its placement lists. Every prop or building id becomes one
## MultiMeshInstance3D (shared mesh and materials), so a hundred props cost a handful of draw calls. Props with a
## collide box also get a static box so the player cannot walk through them; a prop with a splash gets its drops.
## Chests are left to AreaDressing.


## One node with the tower-houses (group per building id) and the props (group per prop id), plus "Collision".
static func build(area: AreaDef, palette: PaletteDef, floor_y: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Props"
	var by_house: Dictionary[StringName, Array] = {}
	for p: Placement in area.buildings:
		_group(by_house, p.ref, p, floor_y)
	for id: StringName in by_house:
		var def := ContentDB.get_def("building", id) as BuildingDef
		root.add_child(_multi(TowerHouse.mesh(def, palette), by_house[id]))
	var by_prop: Dictionary[StringName, Array] = {}
	var body := StaticBody3D.new()
	body.name = "Collision"
	for p: Placement in area.props:
		var def := ContentDB.get_def("prop", p.ref) as PropDef
		if def == null:
			continue
		_group(by_prop, p.ref, p, floor_y)
		if def.collide != Vector3.ZERO:
			_collider(body, def, _place(p, floor_y))
	for id: StringName in by_prop:
		var def := ContentDB.get_def("prop", id) as PropDef
		if not def.chest:
			root.add_child(_multi(PropMesh.mesh(def, palette), by_prop[id]))
		if def.splash != null:
			for at: Transform3D in by_prop[id]:
				root.add_child(PropFx.splash(def.splash, at))
	root.add_child(body)
	return root


## The transform a placement stands at (y = the floor height unless the placement gave one).
static func transform_of(p: Placement, floor_y: float) -> Transform3D:
	return _place(p, floor_y)


## Real lights carried by the props (a lantern brings its light), moved to where each prop stands.
static func light_specs(area: AreaDef, floor_y: float) -> Array[LightSpec]:
	var out: Array[LightSpec] = []
	for p: Placement in area.props:
		var def := ContentDB.get_def("prop", p.ref) as PropDef
		if def != null and def.light != null:
			out.append(def.light.placed(_place(p, floor_y).origin, p.yaw))
	return out


static func _place(p: Placement, floor_y: float) -> Transform3D:
	var y: float = p.pos.y if p.has_y else floor_y
	return Transform3D(Basis(Vector3.UP, deg_to_rad(p.yaw)), Vector3(p.pos.x, y, p.pos.z))


static func _group(groups: Dictionary[StringName, Array], id: StringName, p: Placement, floor_y: float) -> void:
	if not groups.has(id):
		groups[id] = []
	groups[id].append(_place(p, floor_y))


static func _multi(mesh: Mesh, transforms: Array) -> MultiMeshInstance3D:
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


static func _collider(body: StaticBody3D, def: PropDef, at: Transform3D) -> void:
	var box := BoxShape3D.new()
	box.size = def.collide
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.transform = Transform3D(at.basis, at.origin + Vector3(0.0, def.collide.y / 2.0, 0.0))
	body.add_child(shape)
