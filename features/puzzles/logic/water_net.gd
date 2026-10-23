class_name WaterNet
extends RefCounted
## purpose: Pure logic for water net gate toggling, unjamming, spout swinging, and flow calculation.


static func toggle_gate(state: WaterNetState, def: WaterNetDef, id: StringName) -> bool:
	var node: WaterNodeDef = def.node_def(id)
	if node == null or node.kind != &"gate":
		return false
	if node.jammed and not state.freed.get(id, false):
		return false
	state.open[id] = not state.open.get(id, false)
	return true


static func free_gate(state: WaterNetState, def: WaterNetDef, id: StringName) -> bool:
	var node: WaterNodeDef = def.node_def(id)
	if node == null or node.kind != &"gate":
		return false
	if not node.jammed:
		return false
	if state.freed.get(id, false):
		return false
	state.freed[id] = true
	return true


static func swing_spout(state: WaterNetState, id: StringName) -> int:
	var next: int = 1 if state.spout.get(id, 0) == 0 else 0
	state.spout[id] = next
	return next


static func flow(def: WaterNetDef, state: WaterNetState) -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {}
	for node: WaterNodeDef in def.nodes:
		result[node.id] = 0.0

	var source_id: StringName = &""
	for node: WaterNodeDef in def.nodes:
		if node.kind == &"source":
			source_id = node.id
			break
	if source_id.is_empty():
		return result
	result[source_id] = 1.0

	for nid: StringName in def.topo_order:
		var share: float = result.get(nid, 0.0)
		if share <= 0.0:
			continue
		var node: WaterNodeDef = def.node_def(nid)
		if node == null:
			continue
		match node.kind:
			&"source":
				if not node.to.is_empty():
					result[node.to[0]] = result.get(node.to[0], 0.0) + share
			&"split":
				_distribute_split(def, state, node, share, result)
			&"gate":
				if state.open.get(nid, false) and not node.to.is_empty():
					result[node.to[0]] = result.get(node.to[0], 0.0) + share
			&"spout":
				var target: StringName = _spout_target(node, state)
				if not target.is_empty():
					result[target] = result.get(target, 0.0) + share
			&"outlet":
				pass
	return result


static func outlet_shares(def: WaterNetDef, state: WaterNetState) -> Dictionary[StringName, float]:
	var full_flow: Dictionary[StringName, float] = flow(def, state)
	var shares: Dictionary[StringName, float] = {}
	for node: WaterNodeDef in def.nodes:
		if node.kind == &"outlet":
			shares[node.id] = full_flow.get(node.id, 0.0)
	return shares


static func solved(def: WaterNetDef, state: WaterNetState) -> bool:
	var shares: Dictionary[StringName, float] = outlet_shares(def, state)
	for node: WaterNodeDef in def.nodes:
		if node.kind == &"outlet" and node.reaction == &"goal":
			return shares.get(node.id, 0.0) >= 0.999
	return false


static func _distribute_split(def: WaterNetDef, state: WaterNetState, split: WaterNodeDef, share: float, result: Dictionary[StringName, float]) -> void:
	var active: Array[StringName] = []
	for child_id: StringName in split.to:
		var child: WaterNodeDef = def.node_def(child_id)
		if child == null:
			continue
		if child.kind == &"gate":
			if state.open.get(child_id, false):
				active.append(child_id)
		else:
			active.append(child_id)
	if active.is_empty():
		return
	var each: float = share / float(active.size())
	for child_id: StringName in active:
		result[child_id] = result.get(child_id, 0.0) + each


static func _spout_target(node: WaterNodeDef, state: WaterNetState) -> StringName:
	if node.to.size() < 2:
		return node.to[0] if not node.to.is_empty() else &""
	var pos: int = state.spout.get(node.id, node.start)
	if pos == 0:
		if not node.spill_unless_shut.is_empty() and state.open.get(node.spill_unless_shut, false):
			return node.to[1]
		return node.to[0]
	return node.to[1]
