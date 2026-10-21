class_name SurfaceBuffer
extends RefCounted
## Collects flat-shaded, vertex-coloured faces (boxes, prisms, polygons) for one surface of an ArrayMesh.
## Every point goes through xf first, so a piece can be built at the origin and then moved. With fake_light
## set (a direction towards the light) face colours are shaded by it, for surfaces that are drawn unshaded.

var xf: Transform3D = Transform3D.IDENTITY
var fake_light: Vector3 = Vector3.ZERO
var _verts := PackedVector3Array()
var _normals := PackedVector3Array()
var _uvs := PackedVector2Array()
var _colors := PackedColorArray()


func is_empty() -> bool:
	return _verts.is_empty()


func triangle_count() -> int:
	return _verts.size() / 3


## A convex polygon facing outward (a direction in local space); corners may come in either order.
func face(points: Array[Vector3], outward: Vector3, color: Color, uvs: Array[Vector2] = []) -> void:
	var pts: Array[Vector3] = []
	for p: Vector3 in points:
		pts.append(xf * p)
	var o: Vector3 = (xf.basis * outward).normalized()
	var order: Array[int] = []
	for i: int in pts.size():
		order.append(i)
	if (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(o) > 0.0:
		order.reverse()
	var lum: float = 1.0
	if fake_light != Vector3.ZERO:
		lum = 0.5 + 0.5 * clampf(o.dot(fake_light.normalized()), 0.0, 1.0)
	var shaded := Color(color.r * lum, color.g * lum, color.b * lum, color.a)
	for k: int in range(1, order.size() - 1):
		for idx: int in [order[0], order[k], order[k + 1]]:
			_verts.append(pts[idx])
			_normals.append(o)
			_colors.append(shaded)
			_uvs.append(uvs[idx] if uvs.size() > idx else Vector2.ZERO)


## An axis-aligned box (no bottom face) centred at center.
func box(center: Vector3, size: Vector3, color: Color) -> void:
	var h: Vector3 = size / 2.0
	var c: Vector3 = center
	var pts: Array[Vector3] = []
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				pts.append(c + Vector3(sx * h.x, sy * h.y, sz * h.z))
	# index = sx*4 + sy*2 + sz with sx,sy,sz in {0,1}
	_side([pts[4], pts[5], pts[7], pts[6]], Vector3.RIGHT, color)
	_side([pts[0], pts[1], pts[3], pts[2]], Vector3.LEFT, color)
	_side([pts[2], pts[3], pts[7], pts[6]], Vector3.UP, color)
	_side([pts[1], pts[3], pts[7], pts[5]], Vector3.BACK, color)
	_side([pts[0], pts[2], pts[6], pts[4]], Vector3.FORWARD, color)


func _side(corners: Array[Vector3], outward: Vector3, color: Color) -> void:
	face(corners, outward, color)


## A prism or cone frustum standing on base (radius bottom to top over height) with the given number of sides.
func frustum(base: Vector3, r_bottom: float, r_top: float, height: float, sides: int, color: Color,
		twist: float = 0.0, cap: bool = true) -> void:
	var top: Vector3 = base + Vector3(0.0, height, 0.0)
	for i: int in sides:
		var a0: float = twist + TAU * i / sides
		var a1: float = twist + TAU * (i + 1) / sides
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var mid: Vector3 = (d0 + d1).normalized()
		var out: Vector3 = mid + Vector3(0.0, (r_bottom - r_top) / maxf(height, 0.001), 0.0)
		var pts: Array[Vector3] = [base + d0 * r_bottom, base + d1 * r_bottom, top + d1 * r_top, top + d0 * r_top]
		face(pts, out, color)
		if cap and r_top > 0.0:
			face([top, top + d0 * r_top, top + d1 * r_top], Vector3.UP, color)


## Appends another buffer's faces as they are (its own xf is already applied; this buffer's xf is not).
func merge(other: SurfaceBuffer) -> void:
	_verts.append_array(other._verts)
	_normals.append_array(other._normals)
	_uvs.append_array(other._uvs)
	_colors.append_array(other._colors)


## Writes the collected faces as the next surface of mesh.
func commit(mesh: ArrayMesh, material: Material) -> void:
	if _verts.is_empty():
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _verts
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_TEX_UV] = _uvs
	arrays[Mesh.ARRAY_COLOR] = _colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(mesh.get_surface_count() - 1, material)
