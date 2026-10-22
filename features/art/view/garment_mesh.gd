class_name GarmentMesh
extends RefCounted
## Stand-in clothing built in code from a ModelPartDef (until Feras's own models): a lathe (a skirt, a coat, a head
## wrap) turned from a radius profile, and `prim`, which adds a coloured primitive to a SurfaceTool so a whole prop
## (the jambiyah) is one mesh with vertex colours (the skin shader multiplies COLOR into the albedo).

const SIDES: int = 16


## A surface of revolution around +y, top at y = 0 and bottom at y = -length: radius profile[i] at station i, the z
## axis squashed by `depth`. `sweep` degrees of the ring are built, centred on the back (-z). Double sided (the inside faces too), so no cull mode is needed.
static func lathe(profile: Array[float], length: float, depth: float, color: Color, sweep: float = 360.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(color)
	var stations: int = profile.size()
	for i: int in stations - 1:
		for s: int in SIDES:
			var quad: Array[Vector3] = [
				_ring(profile, length, depth, sweep, i, s), _ring(profile, length, depth, sweep, i, s + 1),
				_ring(profile, length, depth, sweep, i + 1, s + 1), _ring(profile, length, depth, sweep, i + 1, s)]
			for corner: int in [0, 1, 2, 0, 2, 3]:
				st.add_vertex(quad[corner])
			for corner: int in [0, 2, 1, 0, 3, 2]:
				st.add_vertex(quad[corner])
	st.generate_normals()
	return st.commit()


## Adds a primitive mesh (a cylinder, box or sphere) to the builder at `xf`, painted `color`.
static func prim(st: SurfaceTool, mesh: PrimitiveMesh, xf: Transform3D, color: Color) -> void:
	var arrays: Array = mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	st.set_color(color)
	for index: int in indices:
		st.set_normal((xf.basis * normals[index]).normalized())
		st.add_vertex(xf * verts[index])


static func _ring(profile: Array[float], length: float, depth: float, sweep: float, station: int, side: int) -> Vector3:
	var angle: float = deg_to_rad(270.0 - sweep * 0.5 + sweep * float(side) / float(SIDES))
	var y: float = -length * float(station) / float(profile.size() - 1)
	return Vector3(cos(angle) * profile[station], y, sin(angle) * profile[station] * depth)
