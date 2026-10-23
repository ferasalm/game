class_name WaterNetDef
extends Def
## purpose: Defines a water routing network puzzle (valves, splits, gates, spouts, outlets).

var nodes: Array[WaterNodeDef] = []
var hint_secs: Array[int] = []
var hint_keys: Array[StringName] = []
var topo_order: Array[StringName] = []

var _nodes_by_id: Dictionary[StringName, WaterNodeDef] = {}


func read(r: DefReader) -> void:
	id = r.id()
	nodes.clear()
	_nodes_by_id.clear()
	topo_order.clear()

	for nr: DefReader in r.objects("nodes"):
		var node := WaterNodeDef.new()
		node.read(nr)
		nodes.append(node)
		_nodes_by_id[node.id] = node

	var sources: int = 0
	for node: WaterNodeDef in nodes:
		if node.kind == &"source":
			sources += 1
		if node.kind == &"gate" and node.to.size() != 1:
			r.problem("nodes", "gate '%s' must have 1 target in 'to', found %d" % [node.id, node.to.size()])
		elif node.kind == &"spout" and node.to.size() != 2:
			r.problem("nodes", "spout '%s' must have 2 targets in 'to', found %d" % [node.id, node.to.size()])

	if sources != 1:
		r.problem("nodes", "must have exactly 1 source, found %d" % sources)

	for node: WaterNodeDef in nodes:
		for target: StringName in node.to:
			if not _nodes_by_id.has(target):
				r.problem("nodes", "node '%s' points to unknown id '%s'" % [node.id, target])
		if not node.spill_unless_shut.is_empty() and not _nodes_by_id.has(node.spill_unless_shut):
			r.problem("nodes", "spout '%s' has unknown spill_unless_shut id '%s'" % [node.id, node.spill_unless_shut])

	_compute_topo_order(r)
	hint_secs = r.int_list("hint_secs", 0, 3600)
	hint_keys = r.id_list("hint_keys")


func node_def(node_id: StringName) -> WaterNodeDef:
	return _nodes_by_id.get(node_id)


func _compute_topo_order(r: DefReader) -> void:
	var visited: Dictionary[StringName, int] = {}
	var order: Array[StringName] = []
	var has_cycle: bool = false
	for node: WaterNodeDef in nodes:
		if visited.get(node.id, 0) == 0:
			if _dfs_visit(node.id, visited, order):
				has_cycle = true
				break
	if has_cycle:
		r.problem("nodes", "cycle detected in water network")
	else:
		order.reverse()
		topo_order = order


func _dfs_visit(curr: StringName, visited: Dictionary[StringName, int], order: Array[StringName]) -> bool:
	visited[curr] = 1
	var n: WaterNodeDef = node_def(curr)
	if n != null:
		for target: StringName in n.to:
			if _nodes_by_id.has(target):
				var state: int = visited.get(target, 0)
				if state == 1:
					return true
				if state == 0 and _dfs_visit(target, visited, order):
					return true
	visited[curr] = 2
	order.append(curr)
	return false
