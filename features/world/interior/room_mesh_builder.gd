class_name RoomMeshBuilder
extends RefCounted
## purpose: Builds room shell geometry: floor, walls, ceiling, qamariya stained-glass arches, and collisions.

const ARCH_COLORS: Array[String] = ["R", "Y", "G", "B", "V"]


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
	var floor_mat: Material = SurfaceMaterials.tile(&"planks", palette, Color(0.75, 0.65, 0.55))
	var f_mesh := BoxMesh.new()
	f_mesh.size = Vector3(spec.size.x, 0.1, spec.size.z)
	f_mesh.material = floor_mat
	var f_node := MeshInstance3D.new()
	f_node.mesh = f_mesh
	f_node.position = Vector3(spec.size.x * 0.5, -0.05, spec.size.z * 0.5)
	root.add_child(f_node)
	var c_mesh := BoxMesh.new()
	c_mesh.size = Vector3(spec.size.x, 0.1, spec.size.z)
	var c_mat := StandardMaterial3D.new()
	c_mat.albedo_color = palette.colors.get(spec.wall_color, Color.WHITE)
	c_mesh.material = c_mat
	var c_node := MeshInstance3D.new()
	c_node.mesh = c_mesh
	c_node.position = Vector3(spec.size.x * 0.5, spec.size.y + 0.05, spec.size.z * 0.5)
	root.add_child(c_node)


static func _build_walls(root: Node3D, spec: RoomDef, palette: PaletteDef) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(PaintedMaterials.trim())
	st.set_color(palette.colors.get(spec.wall_color, Color.WHITE))
	var w: float = spec.size.x
	var h: float = spec.size.y
	var d: float = spec.size.z
	_add_wall_quad(st, Vector3(0, 0, 0), Vector3(w, 0, 0), Vector3(w, h, 0), Vector3(0, h, 0))
	_add_wall_quad(st, Vector3(0, 0, d), Vector3(0, 0, 0), Vector3(0, h, 0), Vector3(0, h, d))
	_add_wall_quad(st, Vector3(w, 0, 0), Vector3(w, 0, d), Vector3(w, h, d), Vector3(w, h, 0))
	_add_wall_quad(st, Vector3(0, 0, d), Vector3(2.8, 0, d), Vector3(2.8, h, d), Vector3(0, h, d))
	_add_wall_quad(st, Vector3(4.2, 0, d), Vector3(w, 0, d), Vector3(w, h, d), Vector3(4.2, h, d))
	_add_wall_quad(st, Vector3(2.8, 2.4, d), Vector3(4.2, 2.4, d), Vector3(4.2, h, d), Vector3(2.8, h, d))
	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	root.add_child(mi)


static func _add_wall_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a).normalized()
	st.set_normal(n)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)


static func _build_qamariyas(root: Node3D, spec: RoomDef, palette: PaletteDef) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(PaintedMaterials.glow())
	if spec.qamariya_walls.has("north"):
		_add_qamariya_arch(st, Vector3(spec.size.x * 0.5, 1.8, 0.05), Vector3.BACK, palette)
	if spec.qamariya_walls.has("west"):
		_add_qamariya_arch(st, Vector3(0.05, 1.8, spec.size.z * 0.5), Vector3.RIGHT, palette)
	if spec.qamariya_walls.has("east"):
		_add_qamariya_arch(st, Vector3(spec.size.x - 0.05, 1.8, spec.size.z * 0.5), Vector3.LEFT, palette)
	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	root.add_child(mi)


static func _add_qamariya_arch(st: SurfaceTool, center: Vector3, normal: Vector3,
		palette: PaletteDef) -> void:
	var right: Vector3 = normal.cross(Vector3.UP).normalized()
	var radius: float = 0.8
	var segments: int = ARCH_COLORS.size()
	for i: int in segments:
		var c_letter: String = ARCH_COLORS[i]
		st.set_color(palette.colors.get(c_letter, Color.WHITE))
		st.set_normal(normal)
		var a0: float = PI * float(i) / float(segments)
		var a1: float = PI * float(i + 1) / float(segments)
		var p0: Vector3 = center + right * (cos(a0) * radius) + Vector3.UP * (sin(a0) * radius)
		var p1: Vector3 = center + right * (cos(a1) * radius) + Vector3.UP * (sin(a1) * radius)
		st.add_vertex(center)
		st.add_vertex(p0)
		st.add_vertex(p1)


static func _build_collisions(root: Node3D, spec: RoomDef) -> void:
	var body := StaticBody3D.new()
	body.name = "Collision"
	var t: float = 0.2
	var w: float = spec.size.x
	var h: float = spec.size.y
	var d: float = spec.size.z
	_add_box_col(body, Vector3(w, h, t), Vector3(w * 0.5, h * 0.5, -t * 0.5))
	_add_box_col(body, Vector3(t, h, d), Vector3(-t * 0.5, h * 0.5, d * 0.5))
	_add_box_col(body, Vector3(t, h, d), Vector3(w + t * 0.5, h * 0.5, d * 0.5))
	_add_box_col(body, Vector3(2.8, h, t), Vector3(1.4, h * 0.5, d + t * 0.5))
	_add_box_col(body, Vector3(w - 4.2, h, t), Vector3(4.2 + (w - 4.2) * 0.5, h * 0.5, d + t * 0.5))
	root.add_child(body)


static func _add_box_col(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	body.add_child(col)
