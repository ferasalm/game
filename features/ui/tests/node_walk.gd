class_name NodeWalk
extends RefCounted
## Test helper (not a test): every descendant of a node, depth first.


static func all(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in node.get_children():
		out.append(child)
		out.append_array(all(child))
	return out
