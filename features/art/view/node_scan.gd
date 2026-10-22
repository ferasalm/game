class_name NodeScan
extends RefCounted
## Finds nodes inside an imported scene by walking its children: every node of a class (the skeleton, the meshes) and the
## chain of nodes from the root down to one of them (to multiply their transforms). No node lookups by path.


## Every node under `root` (root included) of this class, in tree order.
static func of_type(root: Node, type_name: StringName) -> Array[Node]:
	var out: Array[Node] = []
	_collect(root, type_name, out)
	return out


## The nodes from just under `root` down to `target` (both included); empty when `target` is not below `root`.
static func chain(root: Node, target: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	_descend(root, target, out)
	return out


## The transform of `target` relative to `root` (identity for the root itself).
static func transform_of(root: Node, target: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	for node: Node3D in chain(root, target):
		xf = xf * node.transform
	return xf


static func _collect(node: Node, type_name: StringName, out: Array[Node]) -> void:
	if node.is_class(type_name):
		out.append(node)
	for child: Node in node.get_children():
		_collect(child, type_name, out)


static func _descend(node: Node, target: Node, out: Array[Node3D]) -> bool:
	for child: Node in node.get_children():
		if child == target or _descend(child, target, out):
			if child is Node3D:
				out.push_front(child as Node3D)
			return true
	return false
