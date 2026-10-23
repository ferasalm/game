class_name RoomMeshBuilder
extends RefCounted
## purpose: Builds room shell geometry: floor, walls, ceiling, qamariya stained-glass arches, and collisions.

const ARCH_COLORS: Array[String] = ["R", "O", "Y", "G", "C", "B", "V"]


static func build(spec: RoomDef, palette: PaletteDef) -> Node3D:
	if PaintedMaterials.paint == null:
		var look := ContentDB.get_def("look", &"painted_b") as LookDef
		if look != null:
			PaintedMaterials.use(look.paint)
	var root := Node3D.new()
	root.name = "RoomShell"
	_build_floor_ceiling(root, spec, palette)
	_build_walls(root, spec, palette)
	_build_qamariyas(root, spec, palette)
	_build_collisions(root, spec)
	return root


static func _build_floor_ceiling(root: Node3D, spec: RoomDef, palette: PaletteDef) -> void:
	var f_mesh := BoxMesh.new()
	f_mesh.size = Vector3(spec.size.x, 0.1, spec.size.z)
	f_mesh.material = SurfaceMaterials.tile(&"roof_plaster", palette, Color(0.48, 0.20, 0.16))
	var f_node := MeshInstance3D.new()
	f_node.name = "Floor"
	f_node.mesh = f_mesh
	f_node.position = Vector3(spec.size.x * 0.5, -0.05, spec.size.z * 0.5)
	root.add_child(f_node)
	var ceiling := Node3D.new()
	ceiling.name = "Ceiling"
	var c_mesh := BoxMesh.new()
	c_mesh.size = Vector3(spec.size.x, 0.1, spec.size.z)
	c_mesh.material = SurfaceMaterials.tile(&"gypsum", palette)
	var c_node := MeshInstance3D.new()
	c_node.name = "Slab"
	c_node.mesh = c_mesh
	c_node.position = Vector3(spec.size.x * 0.5, spec.size.y + 0.05, spec.size.z * 0.5)
	ceiling.add_child(c_node)
	var beam_mat: Material = SurfaceMaterials.tile(&"planks", palette, Color(0.34, 0.22, 0.14))
	for bx: float in [0.8, 1.8, 2.8, 3.8, 4.8, 5.8, 6.4]:
		var bm := BoxMesh.new()
		bm.size = Vector3(0.18, 0.16, spec.size.z)
		bm.material = beam_mat
		var b_node := MeshInstance3D.new()
		b_node.mesh = bm
		b_node.position = Vector3(bx, spec.size.y - 0.08, spec.size.z * 0.5)
		ceiling.add_child(b_node)
	root.add_child(ceiling)


static func _build_walls(root: Node3D, spec: RoomDef, palette: PaletteDef) -> void:
	var walls := Node3D.new()
	walls.name = "Walls"
	var mat: Material = SurfaceMaterials.tile(&"gypsum", palette)
	var col: Color = palette.colors.get(spec.wall_color, Color.WHITE)
	_build_north_wall(walls, spec.size.x, spec.size.y, mat, col)
	_build_south_wall(walls, spec.size.x, spec.size.y, spec.size.z, mat, col)
	_build_side_wall(walls, "West", 0.0, spec.size.z, spec.size.y, Vector3.RIGHT, mat, col)
	_build_side_wall(walls, "East", spec.size.x, spec.size.z, spec.size.y, Vector3.LEFT, mat, col)
	root.add_child(walls)


static func _build_north_wall(parent: Node3D, w: float, h: float, mat: Material, col: Color) -> void:
	var buf := SurfaceBuffer.new()
	var x1: float = w * 0.5 - 0.8
	var x2: float = w * 0.5 + 0.8
	buf.face([Vector3(0, 0, 0), Vector3(x1, 0, 0), Vector3(x1, h, 0), Vector3(0, h, 0)], Vector3.BACK, col)
	buf.face([Vector3(x2, 0, 0), Vector3(w, 0, 0), Vector3(w, h, 0), Vector3(x2, h, 0)], Vector3.BACK, col)
	buf.face([Vector3(x1, 0, 0), Vector3(x2, 0, 0), Vector3(x2, 0.5, 0), Vector3(x1, 0.5, 0)], Vector3.BACK, col)
	buf.face([Vector3(x1, 2.6, 0), Vector3(x2, 2.6, 0), Vector3(x2, h, 0), Vector3(x1, h, 0)], Vector3.BACK, col)
	var mesh := ArrayMesh.new()
	buf.commit(mesh, mat)
	var mi := MeshInstance3D.new()
	mi.name = "North"
	mi.mesh = mesh
	parent.add_child(mi)


static func _build_south_wall(parent: Node3D, w: float, h: float, d: float, mat: Material, col: Color) -> void:
	var buf := SurfaceBuffer.new()
	buf.face([Vector3(0, 0, d), Vector3(2.8, 0, d), Vector3(2.8, h, d), Vector3(0, h, d)], Vector3.FORWARD, col)
	buf.face([Vector3(4.2, 0, d), Vector3(w, 0, d), Vector3(w, h, d), Vector3(4.2, h, d)], Vector3.FORWARD, col)
	buf.face([Vector3(2.8, 2.4, d), Vector3(4.2, 2.4, d), Vector3(4.2, h, d), Vector3(2.8, h, d)], Vector3.FORWARD, col)
	var mesh := ArrayMesh.new()
	buf.commit(mesh, mat)
	var mi := MeshInstance3D.new()
	mi.name = "South"
	mi.mesh = mesh
	parent.add_child(mi)


static func _build_side_wall(parent: Node3D, node_name: String, x: float, d: float, h: float,
		norm: Vector3, mat: Material, col: Color) -> void:
	var buf := SurfaceBuffer.new()
	var z1: float = d * 0.5 - 0.8
	var z2: float = d * 0.5 + 0.8
	buf.face([Vector3(x, 0, 0), Vector3(x, 0, z1), Vector3(x, h, z1), Vector3(x, h, 0)], norm, col)
	buf.face([Vector3(x, 0, z2), Vector3(x, 0, d), Vector3(x, h, d), Vector3(x, h, z2)], norm, col)
	buf.face([Vector3(x, 0, z1), Vector3(x, 0, z2), Vector3(x, 0.5, z2), Vector3(x, 0.5, z1)], norm, col)
	buf.face([Vector3(x, 2.6, z1), Vector3(x, 2.6, z2), Vector3(x, h, z2), Vector3(x, h, z1)], norm, col)
	var mesh := ArrayMesh.new()
	buf.commit(mesh, mat)
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	parent.add_child(mi)


static func _build_qamariyas(root: Node3D, spec: RoomDef, palette: PaletteDef) -> void:
	var qamariyas := Node3D.new()
	qamariyas.name = "Qamariyas"
	var cfgs: Array = [
		["north", "North", Vector3(spec.size.x * 0.5, 1.8, 0.04), Vector3.BACK],
		["west", "West", Vector3(0.04, 1.8, spec.size.z * 0.5), Vector3.RIGHT],
		["east", "East", Vector3(spec.size.x - 0.04, 1.8, spec.size.z * 0.5), Vector3.LEFT]
	]
	for cfg: Array in cfgs:
		if spec.qamariya_walls.has(cfg[0]):
			var mi := MeshInstance3D.new()
			mi.name = cfg[1] as String
			mi.mesh = _arch_mesh(cfg[2] as Vector3, cfg[3] as Vector3, palette)
			qamariyas.add_child(mi)
	root.add_child(qamariyas)


static func _arch_mesh(center: Vector3, normal: Vector3, palette: PaletteDef) -> ArrayMesh:
	var buf := SurfaceBuffer.new()
	var right: Vector3 = normal.cross(Vector3.UP).normalized()
	var radius: float = 0.8
	var segments: int = ARCH_COLORS.size()
	for i: int in segments:
		var col: Color = palette.colors.get(ARCH_COLORS[i], Color.WHITE)
		var a0: float = PI * float(i) / float(segments)
		var a1: float = PI * float(i + 1) / float(segments)
		var p0: Vector3 = center + right * (cos(a0) * radius) + Vector3.UP * (sin(a0) * radius)
		var p1: Vector3 = center + right * (cos(a1) * radius) + Vector3.UP * (sin(a1) * radius)
		buf.face([center, p0, p1], normal, col)
	var mesh := ArrayMesh.new()
	buf.commit(mesh, PaintedMaterials.glow())
	return mesh


static func _build_collisions(root: Node3D, spec: RoomDef) -> void:
	var body := StaticBody3D.new()
	body.name = "Collision"
	var t: float = 0.2
	var s: Vector3 = spec.size
	var boxes: Array = [
		[Vector3(s.x, s.y, t), Vector3(s.x * 0.5, s.y * 0.5, -t * 0.5)],
		[Vector3(t, s.y, s.z), Vector3(-t * 0.5, s.y * 0.5, s.z * 0.5)],
		[Vector3(t, s.y, s.z), Vector3(s.x + t * 0.5, s.y * 0.5, s.z * 0.5)],
		[Vector3(2.8, s.y, t), Vector3(1.4, s.y * 0.5, s.z + t * 0.5)],
		[Vector3(s.x - 4.2, s.y, t), Vector3(4.2 + (s.x - 4.2) * 0.5, s.y * 0.5, s.z + t * 0.5)]
	]
	for b: Array in boxes:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = b[0] as Vector3
		col.shape = shape
		col.position = b[1] as Vector3
		body.add_child(col)
	root.add_child(body)
