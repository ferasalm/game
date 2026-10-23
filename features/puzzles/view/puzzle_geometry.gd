class_name PuzzleGeometry
extends RefCounted
## purpose: Grey-box geometry helpers shared by the puzzle yard: oriented boxes, edge boxes and beam segments.

static func box(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)
	return node


static func edge(parent: Node3D, from: Vector3, to: Vector3, size: Vector3, material: Material,
		up_offset: float = 0.0) -> MeshInstance3D:
	var delta: Vector3 = to - from
	var basis: Basis = basis_along(delta)
	var node := box(parent, Vector3(size.x, size.y, delta.length()), Vector3.ZERO, material)
	node.transform = Transform3D(basis, (from + to) * 0.5 + basis.y * up_offset)
	return node


static func segment(parent: Node3D, from: Vector3, to: Vector3, width: float, material: Material) -> MeshInstance3D:
	return edge(parent, from, to, Vector3(width, width, 1.0), material)


static func basis_along(direction: Vector3) -> Basis:
	var dir: Vector3 = direction.normalized()
	var up: Vector3 = Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	return Basis.looking_at(dir, up)
